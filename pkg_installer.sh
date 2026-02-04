#!/bin/bash

packages=$(sed 's/#.*//;/^\s*$/d' base_pkgs)
