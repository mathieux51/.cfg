# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Debug zsh startup performance, 
# uncomment next line and zprof at EOF to see the profile
# zmodload zsh/zprof

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/Users/${USER}/.oh-my-zsh
export DEFAULT_USER='mathieu'
# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="agnoster"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Languages
export LANG=en_US

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

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
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(colorize zsh-completions zsh-autosuggestions npm docker go terraform aws)
source $ZSH/oh-my-zsh.sh

# User configuration

# zsh-vim-mode
bindkey -v
bindkey '^R' history-incremental-search-backward
# bindkey -rpM viins '^[^['

# kubectl completion
source <(kubectl completion zsh)
# helm completion
source <(helm completion zsh)
# digitalocean completion
# source <(doctl completion zsh)

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
# export EDITOR='code -w'
export EDITOR='vim'
# bindkey -v
# bindkey '^R' history-incremental-search-backward
# for bash
# set -o vi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# path
export PATH="/usr/local/sbin:$PATH"

# miscellaneous
alias zshrc="vim ~/.zshrc"
# alias ohmyzsh="vim ~/.oh-my-zsh"
alias code="open -a Visual\ Studio\ Code"
alias v="vim"
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias firefox="/Applications/Firefox.app/Contents/MacOS/firefox"
alias s="git status -b --show-stash"
alias l="git log --color"
alias d="git diff HEAD"
alias ds="git diff HEAD --staged"
alias m="git commit -m"
alias am="git commit -am"
alias lg="lazygit"
# alias pgconfig="v /usr/local/var/postgres/postgresql.conf"
# alias postgres-start="pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start"
# alias postgres-stop="pg_ctl -D /usr/local/var/postgres stop -s -m fast"
# Notification when done
alias schwifty="osascript -e 'display notification \"I want to see what you got\" with title \"Show me what you got\"'"

# alias for config .cfg repo
alias gitc='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# fzf
export FZF_DEFAULT_COMMAND="rg --files --hidden --sort accessed --glob '!.git' --glob '!node_modules:' --glob '!Pods'"
export FZF_DEFAULT_OPTS="--layout=reverse"

# React Native
export ANDROID_HOME=${HOME}/Library/Android/sdk
export PATH=${PATH}:${ANDROID_HOME}/tools
export PATH=${PATH}:${ANDROID_HOME}/platform-tools 
# React Native Expo
export ANDROID_SDK=/Users/${USER}/Library/Android/sdk/
export PATH=${ANDROID_SDK}/platform-tools:$PATH

# sqlite
export PATH="/usr/local/opt/sqlite/bin:$PATH"

# Go
# export GOPATH="$HOME/Projects/production/leolefevre/go"
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
export GOROOT="/usr/local/opt/go/libexec"
export PATH="$PATH:$GOROOT/bin"

# bash functions
gocov () {
  mkdir -p temp; \
  go test -coverprofile temp/cover.out ./...; \
  go tool cover -html=temp/cover.out; \
  rm -rf temp
}

gif(){
  rm "$2"
  ffmpeg -i "$1" -vf scale=600:-1 -pix_fmt rgb24 -r 25 -f gif - | gifsicle --optimize=3 --delay=3 > "$2"
}

touch2() { mkdir -p "$(dirname "$1")" && touch "$1" ; }

# Ruby
export PATH="/usr/local/lib/ruby/gems/2.7.0/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"
export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"

# Python 
# eval "$(pyenv init -)"
export PATH="/Users/$USER/Library/Python/2.7/bin:$PATH"
export PATH="/Users/$USER/Library/Python/3.7/bin:$PATH"

# helm
export PATH="/usr/local/opt/helm@2/bin:$PATH"

# brew install zlib 
# For compilers to find zlib you may need to set:
export LDFLAGS="${LDFLAGS} -L/usr/local/opt/zlib/lib"
export CPPFLAGS="${CPPFLAGS} -I/usr/local/opt/zlib/include"
# For pkg-config to find zlib you may need to set:
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"

# Newstore
cd $GOPATH/src/github.com/newstore/newstore/
source tools/environment.sh
cd -
clear

# zprof # Should be at the end of .zshrc

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
