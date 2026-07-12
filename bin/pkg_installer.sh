#!/bin/bash

source lib/ansi.sh

# Private function to handle the actual parsing and installation of a single list
_process_list_install() {
  local lst_file="$1"

  # 1. Verify existance
  if [[ ! -f "$lst_file" ]]; then
    echo -e "${TAG_SKIP} File '$lst_file' not found."
    return 0
  fi

  # 2. Parse file into a raw package array
  echo -e "${TAG_INFO} Parsing ${TAG_PKG} from $lst_file..."
  mapfile -t raw_pkg_array < <(awk '{sub(/#.*/, ""); if (NF) print $1}' "$lst_file")

  if [[ ${#raw_pkg_array[@]} -eq 0 ]]; then
    echo -e "${TAG_SKIP} No packages found in $lst_file."
    return 0
  fi

  local pacman_packages=()
  local aur_packages=()
  local error_packages=()

  echo "${TAG_INFO} Sorting ${#raw_pkg_array[@]} packages (this may take a moment)..."
  for pkg in "${raw_pkg_array[@]}"; do
    # Query pacman sync database (suppress output)
    if pacman -Si "$pkg" &>/dev/null; then
      pacman_packages+=("$pkg")
      # If not in pacman, query yay (AUR)
    elif yay -Si "$pkg" &>/dev/null; then
      aur_packages+=("$pkg")
      # If neither finds if, flag as error
    else
      error_packages+=("$pkg")
    fi
  done

  # 3. Install Pacman packages
  if [[ ${#pacman_packages[@]} -gt 0 ]]; then
    echo -e "${TAG_PACMAN} Installing ${#pacman_packages[@]} official packages..."
    sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"
  fi
  # 4. Install AUR packages
  if [[ ${#aur_packages[@]} -gt 0 ]]; then
    echo -e "${TAG_AUR} Installing ${#aur_packages[@]} AUR packages..."
    yay -S --needed --noconfirm "${aur_packages[@]}"
  fi
  # 5. Report errors
  if [[ ${#error_packages[@]} -gt 0 ]]; then
    echo -e "${TAG_ERROR} Packages NOT found in official repos or AUR:"
    for err_pkg in "${error_packages[@]}"; do
      echo "   - $err_pkg"
    done
  fi
}

# Public function called by execute_me.sh
execute_install() {
  local do_minimal=$1
  local do_dev=$2
  local do_custom=$3
  local files_to_install=()

  if $do_minimal || $do_dev; then
    files_to_install+=("packages/system.lst" "packages/hoka.lst")
  fi

  if $do_dev; then
    files_to_install+=("packages/devel.lst")
  fi

  if $do_custom; then
    files_to_install+=("packages/custom.lst")
  fi

  # Deduplicate the array
  local unique_files=($(printf "%s\n" "${files_to_install[@]}" | sort -u))

  for target_file in "${unique_files[@]}"; do
    _process_list_install "$target_file"
  done

  echo -e "\n${TAG_INFO} Installation process complete!"
}
