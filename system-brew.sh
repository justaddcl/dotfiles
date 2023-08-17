#!/usr/bin/env bash

# Exit immediately if a non-zero status is returned
set -o errexit
# Set the return value of a pipeline to the value of the last (rightmost) command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully
set -o pipefail

# Ensure the script prints a summary of what's changed when it exits
trap handle_exit SIGINT SIGTERM ERR EXIT

installed_list=()
error_list=()
already_installed_list=()
has_printed_summary=false

# Function to set terminal colors if supported.
term_colors() {
    if [[ -t 1 ]]; then
        RED=$(printf '\033[31m')
        GREEN=$(printf '\033[32m')
        YELLOW=$(printf '\033[33m')
        BLUE=$(printf '\033[34m')
        MAGENTA=$(printf '\033[35m')
        CYAN=$(printf '\033[36m')
        BOLD=$(printf '\033[1m')
        RESET=$(printf '\033[0m')
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        MAGENTA=""
        CYAN=""
        BOLD=""
        RESET=""
    fi
}

# Function to output colored or bold terminal messages.
# Usage examples: term_message "This is a default color and style message"
#                 term_message nb "This is a default color bold message"
#                 term_message rb "This is a red bold message"
term_message() {
    local set_color=""
    local set_style=""
    [[ -z "${2}" ]] && echo -ne "${1}" >&2 && return
    [[ ${1:0:1} == "d" ]] && set_color=${RESET}
    [[ ${1:0:1} == "r" ]] && set_color=${RED}
    [[ ${1:0:1} == "g" ]] && set_color=${GREEN}
    [[ ${1:0:1} == "y" ]] && set_color=${YELLOW}
    [[ ${1:0:1} == "b" ]] && set_color=${BLUE}
    [[ ${1:0:1} == "m" ]] && set_color=${MAGENTA}
    [[ ${1:0:1} == "c" ]] && set_color=${CYAN}
    [[ ${1:1:2} == "b" ]] && set_style=${BOLD}
    echo -e "${set_color}${set_style}${2}${RESET}" >&2 && return
}

# Displays a box containing a dash and message
task_start() {
    echo -ne "[-] ${1}"
}

# Displays a box containing a green tick and optional message if required.
task_done() {
    echo -e "\r[\033[0;32m\xE2\x9C\x94\033[0m] ${1}"
}

# Displays a box containing a red cross and optional message if required.
task_fail() {
    echo -e "\r[\033[0;31m\xe2\x9c\x98\033[0m] ${1}"
}

# Function to pause script and check if the user wishes to continue.
check_continue() {
    local response
    while true; do
        read -r -p "System brew will install Homebrew, Homebrew packages, apps from the Mac App Store, ZSH, some preferences files, Raycast config, ZSH config, wallpapers, and a lockscreen image. Ready? (y/n) " response
        case "${response}" in
        [yY][eE][sS] | [yY])
            echo
            break
            ;;
        *)
            echo
            exit
            ;;
        esac
    done
}

# Function check command exists
command_exists() {
    command -v "${@}" >/dev/null 2>&1
}

# Function to output details of script.
script_info() {
    cat <<EOF

Name:           system-brew.sh
Version:        v1.0.26
Description:    Automate the installation of macOS
                applications and packages using homebrew.
                Fork of autobrew.sh by Mark Bradley
Author:         JustAddCl
Requirements:   Command Line Tools (CLT) for Xcode

EOF
}

check_xcode() {
    term_message cb "Checking for setup dependencies..."
    task_start "Checking for Xcode command line tools..."
    if xcode-select -p >/dev/null 2>&1; then
        task_done "Xcode command line tools are installed.$(tput el)"
    else
        task_fail "\n"
        term_message mb "Attempting to install Xcode command line tools..."
        if xcode-select --install >/dev/null 2>&1; then
            term_message gb "Re-run script after Xcode command line tools have finished installing.\n"
        else
            term_message rb "Xcode command line tools install failed.\n"
        fi
        exit 1
    fi
}

install_homebrew() {
    term_message cb "\nInstalling Homebrew..."
    task_start "Checking for Homebrew..."
    if command_exists "brew"; then
        task_done "Homebrew is installed.$(tput el)"
        task_start "Running brew update..."
        if brew update >/dev/null 2>&1; then
            task_done "Brew update completed.$(tput el)"
        else
            task_fail "Brew update failed.$(tput el)"
        fi
        task_start "Running brew upgrade..."
        if brew upgrade >/dev/null 2>&1; then
            task_done "Brew upgrade completed.$(tput el)"
        else
            task_fail "Brew upgrade failed.$(tput el)"
        fi
    else
        task_fail "\n"
        term_message mb "Attempting to install Homebrew..."
        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            task_done "Homebrew installed.\n"
        else
            task_fail "Homebrew install failed.\n"
            exit 1
        fi
    fi
}

brew_packages() {
    if [[ ! -z "$tap_list" ]]; then
        term_message cb "\nAdding additional Homebrew taps..."
        for tap in ${tap_list[@]}; do
            task_start "Checking for tap > ${tap}"
            if brew tap | grep "${tap}" >/dev/null 2>&1 || command_exists "${tap}"; then
                task_done "Tap ${tap} already added.$(tput el)"
                already_installed_list+=(${tap})
            else
                task_fail "\n"
                term_message mb "Attempting to add tap ${tap}..."
                if brew tap "${tap}"; then
                    task_done "Tap ${tap} added.\n"
                    installed_list+=(${tap})
                else
                    task_fail "Unable to add tap ${tap}.\n"
                    error_list+=(${tap})
                fi
            fi
        done
    fi
    if [[ ! -z "$formulae_list" ]]; then
        term_message cb "\nInstalling brew terminal packages..."
        for formula in ${formulae_list[@]}; do
            task_start "Checking for package > ${formula}"
            if brew list "${formula}" >/dev/null 2>&1 || command_exists "${formula}"; then
                task_done "Package ${formula} already installed.$(tput el)"
                already_installed_list+=(${formula})
            else
                task_fail "\n"
                term_message mb "Attempting to install ${formula}..."
                if brew install "${formula}"; then
                    task_done "Package ${formula} installed.\n"
                    installed_list+=(${formula})
                else
                    task_fail "Package ${formula} install failed.\n"
                    error_list+=(${formula})
                fi
            fi
        done
    fi
    if [[ ! -z "$cask_list" ]]; then
        term_message cb "\nInstalling brew cask packages..."
        for cask in ${cask_list[@]}; do
            task_start "Checking for cask package > ${cask}"
            if brew list --cask "${cask}" >/dev/null 2>&1; then
                task_done "Package ${cask} already installed.$(tput el)"
                already_installed_list+=(${cask})
            else
                task_fail "\n"
                term_message mb "Attempting to install ${cask}..."
                if brew install --cask "${cask}"; then
                    task_done "Package ${cask} installed.\n"
                    installed_list+=(${cask})
                else
                    task_fail "Package ${cask} install failed.\n"
                    error_list+=(${cask})
                fi
            fi
        done
    fi
}

brew_cleanup() {
    task_start "Running brew cleanup..."
    if brew cleanup >/dev/null 2>&1; then
        task_done "Brew cleanup completed.$(tput el)"
    else
        task_fail "Brew cleanup failed.$(tput el)"
    fi
}

install_zsh() {
    if ! which "zsh" >/dev/null 2>&1; then
        task_start "Installing ZSH..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        task_done "ZSH installed.\n"
        success_list+=('ZSH')
    else
        task_start "ZSH already installed\n"
        already_installed_list+=('ZSH')
    fi
}

install_mas() {
    term_message cb "\nInstalling Mac App Store apps..."
    # Mac App Store apps have IDs. You can find these
    # with `mas search <name>`.

    apps=(
        1168254295 # AmorphousDiskMark https://apps.apple.com/us/app/amorphousdiskmark/id1168254295?mt=12
        937984704  # Amphetamine: https://apps.apple.com/us/app/amphetamine/id937984704?mt=12
        1643751440 # Energiza https://apps.apple.com/us/app/energiza-battery-monitor/id1643751440?mt=12
        1423210932 # Flow - Focus & Pomodoro Timer: https://flowapp.info/
        1452453066 # Hidden Bar https://apps.apple.com/us/app/hidden-bar/id1452453066?mt=12
        1440405750 # MusicHarbor: https://apps.apple.com/us/app/musicharbor-track-new-music/id1440405750
    )

    for app in "${apps[@]}"; do
        if mas list | grep $app >/dev/null 2>&1; then
            task_start "App ID: $app already installed\n"
            already_installed_list+=(${app})
        else
            if ! mas info ${app} >/dev/null 2>&1; then
                task_fail "Cannot find app ID: ${app} on the Mac App Store"
                error_list+=(${app})
            else
                task_start "Installing ${app}"
                if mas install $app; then
                    task_done "App ID: ${app} installed"
                    installed_list+=(${app})
                else
                    task_fail "App ID: ${app} install failed"
                    error_list+=(${cask})
                fi
            fi
        fi
    done

    task_done "Mac apps installed.\n"
}

install_configs() {
    term_message cb "\nSetting up preferences..."
    local response
    read -r -p "There may already be configs in ${HOME}/Library/Preferences/, ${HOME}/.zshrc, and in ${raycast_dir} and continuing may overwrite those files. Do you want to continue? (y/n) " response
    if [[ ${response,,} =~ ^(y|yes)$ ]]; then
        task_start "Downloading dock preferences"
        curl -o $HOME/Library/Preferences/com.apple.dock.plist 'https://github.com/justaddcl/dotfiles/raw/main/configs/com.apple.dock.plist'
        task_done "Installed dock preferences at 'https://github.com/justaddcl/dotfiles/raw/main/configs/com.apple.dock.plist'"
        installed_list+=("Dock preferences")

        task_start "Downloading emoji preferences"
        curl -o $HOME/Library/Preferences/com.apple.EmojiPreferences.plist 'https://github.com/justaddcl/dotfiles/raw/main/configs/com.apple.EmojiPreferences.plist'
        task_done "Installed emoji preferences at 'https://github.com/justaddcl/dotfiles/raw/main/configs/com.apple.dock.plist'"
        installed_list+=("Emoji preferences")

        task_start "Downloading ZSH config..."
        curl -o $HOME/.zshrc 'https://raw.githubusercontent.com/justaddcl/dotfiles/main/configs/.zshrc'
        task_done "Installed ZSH config"
        installed_list+=("ZSH config")

        task_start "Downloading Raycast config..."
        raycast_dir="${HOME}/Documents/Raycast"
        if [ ! -d "${raycast_dir}" ]; then
            mkdir "${raycast_dir}"
        fi
        curl -o ${raycast_dir}/2023-04-07.rayconfig 'https://raw.githubusercontent.com/justaddcl/dotfiles/main/configs/2023-04-07.rayconfig'
        task_done "Downloaded Raycast config"
        installed_list+=("Raycase config")
    else
        task_fail "User has skipped installing the configs"
        error_list+=("Configs")
        return 0
    fi

}

install_walls() {
    term_message cb "\nInstalling wallpapers..."

    target_dir="$HOME/Pictures"
    walls_zip_filename="Walls.zip"

    if [ -d "${target_dir}/Walls/" ]; then
        local response
        read -r -p "There is already a wallpapers zip file in ${target_dir}. Do you want to continue? (y/n) " response
        if [[ ${response,,} =~ ^(y|yes)$ ]]; then
            task_start "Downloading wallpapers...\n"
            if [ -f "${target_dir}/${walls_zip_filename}" ]; then
                local response
                read -r -p "There is already a wallpapers folder in ${target_dir}. Do you want to continue? (y/n) " response
                if [[ ${response,,} =~ ^(y|yes)$ ]]; then
                    if curl -L "https://s3.us-west-2.amazonaws.com/demo.yujinelson.com/${walls_zip_filename}" -o ${target_dir}/${walls_zip_filename}; then
                        task_done "Downloaded wallpapers"
                    else
                        task_fail "Could not download wallpapers"
                        error_list+=("Wallpapers")
                    fi

                    if [ -f "${target_dir}/${walls_zip_filename}" ]; then
                        task_start "Unzipping wallpapers..."
                        if unzip -q ${target_dir}/${walls_zip_filename} -d ${target_dir}/Walls; then
                            task_done "Unzipped wallpapers to ${target_dir}/Walls"
                        else
                            task_fail "Could not unzip wallpaper"
                        fi

                        task_start "Removing .zip file"
                        rm ${target_dir}/${walls_zip_filename}
                        task_done "Removed .zip file"

                        if [ -d "${target_dir}/Walls/Walls" ]; then
                            task_start "Cleaning up Walls/Walls folder..."
                            mv -i $target_dir/Walls/Walls/* $target_dir/Walls/

                            if rm -r ${target_dir}/Walls/Walls; then
                                task_done "Removed Walls/Walls folder"
                            else
                                task_fail "Could not automatically remove Walls/Walls folder"
                            fi
                        fi

                        if [ -d "${target_dir}/Walls/__MACOSX" ]; then
                            task_start "Removing __MACOSX folder..."
                            rm -r ${target_dir}/Walls/__MACOSX
                            task_done "Removed __MACOSX folder"
                        fi

                        term_message gb "\nWallpapers installed."
                        success_list+=("Wallpapers")
                    fi
                else
                    task_fail "Skipping wallpapers installation"
                    error_list+=("Wallpapers")
                    return 0
                fi
            fi
        else
            task_fail "Skipping wallpapers installation"
            error_list+=("Wallpapers")
            return 0
        fi
    fi

}

install_lockscreen_image() {
    term_message cb "\nInstalling lockscreen..."
    desktop_pictures_dir="/Library/Caches/Desktop Pictures"

    task_start "Getting User UUID..."
    uuidWithFieldName=$(dscl . -read "/Users/$USER" GeneratedUID)
    uuid=${uuidWithFieldName#'GeneratedUID: '}
    task_done "User UUID retrieved. \n"

    task_start "Checking for desktop pictures directories..."

    # check if the /Library/Caches/Desktop Pictures directory exists
    if [ -d "$desktop_pictures_dir/" ]; then
        task_done "Desktop pictures directories confirmed."

        # check if there's a subfolder with the user's UUID
        if [ -d "$desktop_pictures_dir/$uuid/" ]; then
            task_start "Downloading lockscreen image..."
            # check if a lockscreen.png already exists
            if [ -f "$desktop_pictures_dir/$uuid/lockscreen.png" ]; then
                task_fail "Lockscreen image already exists in $desktop_pictures_dir/$uuid. Skipping download.\n"
            else
                curl -o $desktop_pictures_dir/$uuid/lockscreen.png 'https://github.com/justaddcl/dotfiles/blob/main/configs/lockscreen.png?raw=true'
                task_done "Lockscreen image downloaded into $desktop_pictures_dir/$uuid.\n"
            fi
        else
            task_fail "Desktop pictures directory for $uuid does not exist.\n"
        fi
    else
        task_fail "Error: /Library/Caches/Desktop Pictures/ directory does not exist.\n"
    fi
}

print_success() {
    term_message gb "\n${#success_list[@]} items installed"
    for success in ${success_list[@]}; do
        task_done $success
    done
}

print_already_installed() {
    term_message bb "\n${#already_installed_list[@]} items were already installed"
    for already_installed in ${already_installed_list[@]}; do
        task_start "$already_installed\n"
    done
}

print_errors() {
    term_message rb "\n${#error_list[@]} items failed"
    for error in ${error_list[@]}; do
        task_fail $error
    done
}

print_summary() {
    term_message cb "\nSystem brew summary ---------------------------------------"
    print_success
    print_already_installed
    print_errors
}

handle_exit() {
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        term_message yb "\n[!] System brew was interrupted and has exited without completing."
        print_summary
        has_printed_summary=true
    else
        if [ $has_printed_summary = false ]; then
            term_message gb "\n[\xE2\x9C\x94] System brew has completed."
            print_summary
        fi
    fi

    exit 0
}

tap_list=(
    homebrew/cask-fonts
)

formulae_list=(
    bash
    bat
    bat-extras
    curl
    eslint
    gh
    gifski
    git
    mas
    neovim
    node
    nvm
    prettier
    ripgrep
    tmux
    typescript
    unzip
    wget
    yarn
)

cask_list=(
    1password
    adobe-creative-cloud
    appcleaner
    arc
    authy
    brave-browser
    coconutbattery
    discord
    disk-inventory-x
    docker
    figma
    font-fira-code
    font-fira-mono-for-powerline
    firefox
    fliqlo
    flux
    google-chrome
    font-inconsolata-for-powerline
    font-jetbrains-mono
    kap
    notion
    paragon-ntfs
    numi
    postman
    raycast
    rectangle
    rocket
    signal
    spotify
    steam
    thinkorswim
    visual-studio-code
    vlc
    warp
    webull
    whatsapp
)

main() {
    clear
    term_message cb "\nBrewing a new system..."
    term_colors
    script_info
    check_continue
    check_xcode
    install_homebrew
    brew_packages
    brew_cleanup
    install_mas
    install_zsh
    install_configs
    install_walls
    install_lockscreen_image
}

main "${@}"
