#!/usr/bin/env bash

# import util functions
[ -f ./utils.sh ] && . ./utils.sh

set -o errexit
set -o pipefail

# Function to output details of script.
script_info() {
    cat <<EOF

Name:           system-brew.sh
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
            else
                task_fail "\n"
                term_message mb "Attempting to add tap ${tap}..."
                if brew tap "${tap}"; then
                    task_done "Tap ${tap} added.\n"
                else
                    task_fail "Unable to add tap ${tap}.\n"
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
            else
                task_fail "\n"
                term_message mb "Attempting to install ${formula}..."
                if brew install "${formula}"; then
                    task_done "Package ${formula} installed.\n"
                else
                    task_fail "Package ${formula} install failed.\n"
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
            else
                task_fail "\n"
                term_message mb "Attempting to install ${cask}..."
                if brew install --cask "${cask}"; then
                    task_done "Package ${cask} installed.\n"
                else
                    task_fail "Package ${cask} install failed.\n"
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
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

tap_list=(
    homebrew/cask-fonts
)

formulae_list=(
    bat
    bat-extras
    curl
    eslint
    gh
    git
    mas
    node
    nvm
    prettier
    ripgrep
    tmux
    typescript
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
    gifski
    google-chrome
    font-inconsolata-for-powerline
    font-jetbrains-mono
    kap
    neovim
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

# One function to rule them all.
main() {
    # Customise the following list variables (tap_list, term_list and cask_list)
    # Leave list blank or comment out the list if not required.
    # tap_list="homebrew/cask-fonts"
    # term_list="git htop wget curl tmux"
    # cask_list="the-unarchiver vlc visual-studio-code google-chrome \
    # firefox adobe-acrobat-reader malwarebytes font-fira-code"
    clear
    term_colors
    script_info
    check_continue
    check_xcode
    install_homebrew
    brew_packages
    brew_cleanup
    install_zsh
    term_message gb "\nScript completed."
}

main "${@}"
