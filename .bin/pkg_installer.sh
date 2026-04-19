#!/bin/bash

base_packages=$(sed 's/#.*//;/^\s*$/d' base_pkgs)

sudo pacman -S --needed --noconfirm $packages
