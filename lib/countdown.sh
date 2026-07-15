#!/bin/bash

# Helper function for the interruptible countdown
countdown() {
  echo -e "\n${TAG_INFO} Action will begin in 10 seconds."
  echo -e "${TAG_INFO} Press [ENTER] to start immediately or [Ctrl+C] to abort."

  for i in {15..1}; do
    # \r overwrites the line, \033[K clears trailing characters
    echo -ne "\r${C_YELLOW}Waiting: $i seconds...${C_RESET}\033[K"
    # Wait for 1 second for user input. If Enter is pressed, break loop.
    if read -r -t 1; then
      break
    fi
  done
  echo -ne "\r\033[K" # Clear the countdown line cleanly when done
}
