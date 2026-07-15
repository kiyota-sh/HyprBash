#!/bin/bash

# Helper function to display packages on grid
display_queue() {
  local type=$1
  shift
  local arr=("$@")

  if [[ ${#arr[@]} -eq 0 ]]; then return; fi

  if [[ "$type" == "PACMAN" ]]; then
    echo -e "\n${TAG_PACMAN} Packages queued:"
  elif [[ "$type" == "AUR" ]]; then
    echo -e "\n${TAG_AUR} Packages queued:"
  else
    echo -e "\n${TAG_ERROR} Packages NOT found in official repos or AUR:"
  fi

  # Build the | pkg | pkg | string
  local out="|"
  for p in "${arr[@]}"; do
    out+=" ${C_CYAN}${p}${C_RESET} |"
  done

  # Print the formatted grid
  echo -e "$out"
}
