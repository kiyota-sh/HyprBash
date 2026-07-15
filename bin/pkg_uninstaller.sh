#!/bin/bash

source lib/ansi.sh
source lib/queue.sh
source lib/countdown.sh

_process_list_uninstall() {
  local lst_file="$1"

  if [[ ! -f "$lst_file" ]]; then
    echo -e "${TAG_SKIP} File '$lst_file' not found."
    return 0
  fi

  echo -e "${TAG_INFO} Parsing ${TAG_PKG} for removal from $lst_file..."
  mapfile -t raw_pkg_array < <(awk '{sub(/#.*/, ""); if (NF) print $1}' "$lst_file")

  if [[ ${#raw_pkg_array[@]} -eq 0 ]]; then
    echo -e "${TAG_SKIP} No packages found to remove"
    return 1
  fi

  local unique_pkgs=($(printf "%s\n" "${raw_pkg_array[@]}" | sort -u))
  local pacman_remove=()
  local aur_remove=()

  for pkg in "${unique_pkgs[@]}"; do
    # -Qq ensures it only returns the package name if installed.
    # -Qn filters for native (official), -Qm filters for foreign (AUR).
    if pacman -Qqen "$pkg" &>/dev/null; then
      pacman_remove+=("$pkg")
    elif pacman -Qqem "$pkg" &>/dev/null; then
      aur_remove+=("$pkg")
    fi
  done

  if [[ ${#pacman_remove[@]} -eq 0 && ${#aur_remove[@]} -eq 0 ]]; then
    echo -e "\n${TAG_SKIP} None of the requested packages are currently installed."
    return 0
  fi

  display_queue "PACMAN" "${pacman_remove[@]}"
  display_queue "AUR" "${aur_remove[@]}"
  countdown

  # -Rns removes the package, its config files, and unneeded dependencies
  if [[ ${#pacman_remove[@]} -gt 0 ]]; then
    echo -e "${TAG_PACMAN} Removing ${#pacman_remove[@]} official packages..."
    sudo pacman -Rns --noconfirm "${pacman_remove[@]}"
  fi

  if [[ ${#aur_remove[@]} -gt 0 ]]; then
    echo -e "${TAG_AUR} Removing ${#aur_remove[@]} AUR packages..."
    yay -Rns --noconfirm "${aur_remove[@]}"
  fi
}

execute_uninstall() {
  local do_minimal=$1
  local do_dev=$2
  local do_custom=$3
  local files_to_uninstall=()

  if $do_minimal || $do_dev; then
    files_to_uninstall+=("packages/system.lst" "packages/hoka.lst")
  fi

  if $do_dev; then
    files_to_uninstall+=("packages/devel.lst")
  fi

  if $do_custom; then
    files_to_uninstall+=("packages/custom.lst")
  fi

  local unique_files=($(printf "%s\n" "${files_to_uninstall[@]}" | sort -u))

  for target_file in "${unique_files[@]}"; do
    _process_list_uninstall "$target_file"
  done

  echo -e "\n${TAG_INFO} Uninstallation process complete!"
}
