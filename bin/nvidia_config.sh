#!/bin/bash

source lib/ansi.sh

echo -e "${TAG_INFO} Starting Nvidia Configuration for Arch Linux..."

# 1. DRIVER SELECTION
echo -e "\nWhich Nvidia driver do you want to install?"
echo "1) Proprietary (nvidia-dkms) - Recommended for GTX 10xx, 20xx, 30xx, 40xx"
echo "2) Open (nvidia-open-dkms)   - REQUIRED for RTX 50xx and newer"
read -rp "Enter choice [1 or 2]: " driver_choice

case $driver_choice in
1) NVIDIA_PKG="nvidia-dkms" ;;
2) NVIDIA_PKG="nvidia-open-dkms" ;;
*)
  echo -e "${TAG_ERROR} Invalid choice. Exiting."
  exit 1
  ;;
esac

# 2. DETECTING KERNELS & MATCHING HEADERS
echo -e "\n${TAG_PACMAN} Detecting installed kernels to fetch headers..."

# HOW THIS WORKS:
# - pacman -Q: Queries the local package database (what is installed on your system).
# - -s: Searches package names matching a pattern.
# - -q: "Quiet" mode. Normally pacman prints "linux 6.1.x-1". -q forces it to print *only* the name "linux", making it clean for scripts.
# - "^linux(-lts|-zen|-hardened)?$": A regular expression (regex).
#   ^ means "starts with", $ means "ends with".
#   It matches exactly: "linux", "linux-lts", "linux-zen", or "linux-hardened".
K_PKGS=$(pacman -Qsq "^linux(-lts|-zen|-hardened)?$")

HEADERS=()
for k in $K_PKGS; do
  HEADERS+=("$k-headers")
  echo -e "   - Found kernel: $k (Adding $k-headers)"
done

# 3. VERIFYING MULTILIB REPO (USING GREP)
EXTRA_PKGS="nvidia-utils egl-wayland"

if grep -q "^\[multilib\]" /etc/pacman.conf; then
  echo -e "${TAG_INFO} Multilib repo detected. Adding lib32-nvidia-utils..."
  EXTRA_PKGS="$EXTRA_PKGS lib32-nvidia-utils"
fi

# 4. PACKAGE INSTALLATION
echo -e "\n${TAG_PACMAN} Installing drivers and dependencies..."
sudo pacman -S --needed --noconfirm "${HEADERS[@]}" $NVIDIA_PKG $EXTRA_PKGS

# 5. ENABLING MODESET (USING TEE)
echo -e "\n${TAG_BOOT} Enabling Early KMS in /etc/modprobe.d/nvidia.conf..."
echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null

# 6. CONFIGURING MKINITCPIO (USING SED)
MKINIT_FILE="/etc/mkinitcpio.conf"
MKINIT_BAK="/etc/mkinitcpio.conf.bak"

echo -e "\n${TAG_BOOT} Backing up $MKINIT_FILE to prevent corruption..."
sudo cp "$MKINIT_FILE" "$MKINIT_BAK"

NVIDIA_MODS="nvidia nvidia_modeset nvidia_uvm nvidia_drm"

if ! grep -q "nvidia_drm" "$MKINIT_FILE"; then
  echo -e "${TAG_INFO} Injecting Nvidia modules into mkinitcpio.conf..."

  # ^MODULES=\((.*)\): Looks for a line starting with (^) MODULES=( and captures whatever is currently inside the parentheses using (.*).
  # MODULES=\(\1 $NVIDIA_MODS\): Replaces the line. The \1 means "put whatever was originally caught inside the parentheses back here", and then we append our new $NVIDIA_MODS right next to it.
  sudo sed -i -E "s/^MODULES=\((.*)\)/MODULES=\(\1 $NVIDIA_MODS\)/" "$MKINIT_FILE"
else
  echo -e "${TAG_SKIP} Nvidia modules already present in mkinitcpio.conf."
fi

# 7. REBUILDING INITRAMFS WITH FAIL-SAFE
echo -e "${TAG_BOOT} Rebuilding initramfs..."
if ! sudo mkinitcpio -P; then
  echo -e "\n${TAG_ERROR} FATAL: mkinitcpio failed! Your boot image might be corrupt."
  echo -e "${TAG_INFO} Executing Fail-Safe: Restoring backup and rebuilding..."

  sudo cp "$MKINIT_BAK" "$MKINIT_FILE"
  sudo mkinitcpio -P

  echo -e "${TAG_INFO} Backup restored successfully. Your system is safe."
  echo -e "${TAG_ERROR} Nvidia modules were NOT applied."
  exit 1
fi

# 8. APPLYING HYPRLAND ENVIRONMENT VARIABLES
ENV_FILE="config/hypr/env.lua"
if [[ -f "$ENV_FILE" ]]; then
  echo -e "\n${TAG_DISPLAY} Applying Nvidia variables to $ENV_FILE..."

  if ! grep -q "GBM_BACKEND" "$ENV_FILE"; then
    echo -e "\n-- NVIDIA" >>"$ENV_FILE"
    echo 'hl.env("GBM_BACKEND", "nvidia-drm")' >>"$ENV_FILE"
    echo 'hl.env("LIBVA_DRIVER_NAME", "nvidia")' >>"$ENV_FILE"
    echo 'hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")' >>"$ENV_FILE"
    echo -e "${TAG_INFO} Variables added."
  else
    echo -e "${TAG_SKIP} Variables already exist in config."
  fi
else
  echo -e "\n${TAG_SKIP} $ENV_FILE not found. Skipping variable injection."
fi

echo -e "\n${TAG_INFO} Nvidia configuration complete!"

bash lib/reboot.sh
