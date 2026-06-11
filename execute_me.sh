#!/bin/bash

# ./pkg_installer.sh

# Script arguments
#while getopts "bdch" opt; do
#	case $opt in
#	b)
#
#	esac
#done


if [ -d "$HOME/clones/yay" ]; then
	echo "YAY helper already installed"
else
	echo "Installing YAY helper"
	mkdir -p "$HOME/clones"
	git clone "https://aur.archlinux.org/yay.git" "$HOME/clones/yay"
	cd "$HOME/clones/yay"
	makepkg -si

	if [ $? -eq 0 ]; then
		echo "Helper installed, no errors"
	fi
fi

# Symlinks
ln -s ~/HyprBash/.config/* ~/.config
