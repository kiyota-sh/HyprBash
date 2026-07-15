#!/bin/bash

source lib/ansi.sh
source bin/pkg_installer.sh

DO_MINIMAL=false
DO_DEV=false
DO_CUSTOM=false
DO_NVIDIA=false

show_help() {
  echo -e "${TAG_INFO} Usage: ./execute_me.sh [OPTIONS]"
  echo "  -m    Install Minimal profile (system.lst + hoka.lst)"
  echo "  -d    Install Development profile (+ devel.lst)"
  echo "  -c    Install Custom profile (+ custom.lst)"
  echo "  -n    Install and configure NVIDIA drivers"
  echo "  -h    Show this help message"
}

while getopts "mdcnh" opt; do
  case $opt in
  m) DO_MINIMAL=true ;;
  d) DO_DEV=true ;;
  c) DO_CUSTOM=true ;;
  n) DO_NVIDIA=true ;;
  h)
    show_help
    exit 0
    ;;
  \?)
    show_help
    exit 1
    ;;
  esac
done

if [ $OPTIND -eq 1 ]; then
  echo -e "${TAG_ERROR} No flags provided."
  show_help
  exit 1
fi

# 1. Profile based package installation
execute_install "$DO_MINIMAL" "$DO_DEV" "$DO_CUSTOM"

# 2. NVIDIA Config
if $DO_NVIDIA; then
  bash bin/nvidia_config.sh
fi

# Symlinks ls -l ~/.config
ln -s ~/HyprBash/config/* ~/.config
