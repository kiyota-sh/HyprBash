#!/bin/bash

source lib/ansi.sh
source bin/pkg_uninstaller.sh

DO_MINIMAL=false
DO_DEV=false
DO_CUSTOM=false

show_help() {
  echo -e "${TAG_INFO} Usage: ./uninstall_me.sh [OPTIONS]"
  echo "  -m    Uninstall Minimal profile (system.lst + hoka.lst)"
  echo "  -d    Uninstall Development profile (+ devel.lst)"
  echo "  -c    Uninstall Custom profile (+ custom.lst)"
  echo "  -h    Show this help message"
}

while getopts "mdch" opt; do
  case $opt in
  m) DO_MINIMAL=true ;;
  d) DO_DEV=true ;;
  c) DO_CUSTOM=true ;;
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

# Pass control to the uninstaller logic
execute_uninstall "$DO_MINIMAL" "$DO_DEV" "$DO_CUSTOM"
