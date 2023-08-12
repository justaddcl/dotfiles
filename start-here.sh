#!/usr/bin/env bash
# run with sudo sh {script location}

set -o errexit
set -o pipefail

# import util functions
[ -f ./utils.sh ] && . ./utils.sh

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

install_git() {
    term_message cb "\nInstalling git formulae..."
    task_start "Checking brew for git"
    if brew list "git" >/dev/null 2>&1 || command_exists "git"; then
        task_done "Git already installed.$(tput el)"
    else
        task_fail "\n"
        term_message mb "Attempting to install git..."
        if brew install "git"; then
            task_done "Git installed.\n"
        else
            task_fail "Git install failed.\n"
        fi
    fi
}

check_for_repositories_dir() {
    term_message cb "\nChecking for ~/Repositories directory"
    task_start "Checking ~/Repositories"
    if [ ! -d "$HOME/Repositories" ]
    then
        task_fail "Error: ~/Repositories does not yet exist. Creating the directory now."
        task_start "Creating ~/Repositories directory"
        cd $HOME
        mkdir Repositories
        task_done "~/Repositories has been created"
    else
        task_done "~/Repositories already exists. Skipping mkdir."
    fi

    task_start "Switching directories"
    cd "$HOME/Repositories"
    task_done "Switched directory"
}

clone_dotfiles_repo() {
    term_message cb "\nCloning dotfiles repository"

    task_start "Cloning dotfiles repository"
    # git clone https://github.com/justaddcl/dotfiles.git
    task_done "Repository cloned"

    task_start "Running system-brew script"
    # ./system-brew.sh
    task_done "Script run"
}

# The function that does everything
main() {
    clear
    term_colors
    install_homebrew
    install_git
    check_for_repositories_dir
    clone_dotfiles_repo
    term_message gb "\nScript completed."
}

main "${@}"
