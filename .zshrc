eval "$(/opt/homebrew/bin/brew shellenv)"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

#download Zinit, if it's not there already
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Snippets
zinit snippet OMZP::command-not-found
zinit snippet OMZP::git
zinit snippet OMZP::jsontools
zinit snippet OMZP::sudo

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle 'fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/justaddcode.json)"
fi

export ZSH="$HOME/.oh-my-zsh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="cerulean"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# plugins=(
#   git
#   jsontools
#   sudo
# )

# source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# aliases

# ZSH configs aliases
alias zshrc="$HOME/.zshrc"
alias zsh-edit="code $HOME/.zshrc"
alias zsh-reload="source $HOME/.zshrc"

# VSCode aliases
alias vscode-ext="open $HOME/.vscode/extensions"

# Workflow aliases
alias copy-pwd="echo $PWD | pbcopy"
alias copy-branch-name="git branch --show-current | pbcopy"

#Remove existing gs alias
unalias gs 2>/dev/null
# (g)it (s)witch
gs() {
	local branches branch
	branches=$(git branch -vv) || return 1
	branch=$(echo "$branches" | fzf +m | awk '{print $1}' | sed "s/.* //")

	if [[ -z "$branch" ]]; then
		echo "No target branch selected"
		return 1
	fi

	git switch "$branch"
}

#Remove existing gs alias
unalias gcp 2>/dev/null
# (g)it (c)herry (p)ick
gcp() {
	local branches target_branch commits commit_hash

	# Get commits
	commits=$(git log --format="%h @ %ci (%ch): %s - %ce")

	# Store current branch
	local current_branch=$(git branch --show-current)

	# Prompt for target branch name
	echo -n "Branch to move commit to: "
	branches=$(git branch -vv) && target_branch=$(echo "$branches" | fzf | awk '{print $1}' | sed "s/.* //")

	# Validate branch name was provided
	if [[ -z "$target_branch" ]]; then
		echo "No branch name provided"
		return 1
	fi

	# Prompt for commit to cherry-pick
	commit_hash=$(echo "$commits" | fzf)

	# Switch to target branch and cherry-pick commit
	if git switch "$target_branch"; then
		git cherry-pick $(echo "$commit_hash" | awk '{print $1}') || {
			echo "Cherry-pick failed, switching back to $current_branch"
			git switch "$current_branch"
			return 1
		}
	else
		echo "Failed to switch to branch: $target_branch"
		return 1
	fi
}

# use `delta` by default to display diffs
export BATDIFF_USE_DELTA=true

#alias capScrn="node $HOME/Repositories/Magpul-m2/scripts/visual-testing.js"
#alias ohmyzsh="code ~/.oh-my-zsh"

# enable zsh-autosuggestions
# source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# enable zsh-syntax-highlighting
# source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# set up zoxide to replace default "cd" command
eval "$(zoxide init zsh --cmd cd)"

PATH=~/.console-ninja/.bin:$PATH
export PATH=$PATH:$HOME/.maestro/bin
