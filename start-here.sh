#!/bin/bash
# run with sudo sh {script location}

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
    echo "${set_color}${set_style}${2}${RESET}" >&2 && return
}

# Displays a box containing a dash and message
task_start() {
    echo "[-] ${1}"
}

# Displays a box containing a green tick and optional message if required.
task_done() {
    echo "\r[\033[0;32m\xE2\x9C\x94\033[0m] ${1}"
}

# Displays a box containing a red cross and optional message if required.
task_fail() {
    echo "\r[\033[0;31m\xe2\x9c\x98\033[0m] ${1}"
}

# Function check command exists
command_exists() {
    command -v "${@}" >/dev/null 2>&1
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
  git clone https://github.com/justaddcl/dotfiles.git
  task_done "Repository cloned"

  task_start "Running system-brew script"
  sudo sh ./system-brew.sh
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
}

main "${@}"
