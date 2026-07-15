#!/bin/bash

source lib/ansi.sh

echo -e "\n${TAG_BOOT} System needs to reboot to apply kernel modules."
echo -e "${TAG_INFO} Press [Ctrl+C] immediately to cancel."

# 15 second countdown loop
for i in {15..1}; do
  # \r overwrites the current line, \033[K clears the rest of the line
  echo -ne "\r${TAG_INFO} Rebooting in $i seconds... \033[K"
  sleep 1
done

echo -e "\n${TAG_BOOT} Initiating reboot..."
sudo reboot
