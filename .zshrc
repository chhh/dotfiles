eval "$(starship init zsh)"

export LESS='-R'

export EDITOR="/opt/homebrew/bin/nvim"
export VISUAL="$EDITOR"

# pyenv setup
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Most programs ask for this
export PATH="$HOME/.local/bin:$PATH"
# Homebrew Apple silicon Brew bin location
export PATH="/usr/local/bin:$PATH"

# My other conf
source $HOME/.aliases


if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

source <(fzf --zsh)

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# uv zsh completions
eval "$(uv generate-shell-completion zsh)"

function zvm_config() {
  ZVM_VI_EDITOR="$EDITOR"
}

function zvm_after_init() {
  zle -N fzf-history-widget
  bindkey -M emacs '^R' fzf-history-widget
  bindkey -M viins '^R' fzf-history-widget
  bindkey -M vicmd '^R' fzf-history-widget
}
source $HOME/.zsh-vi-mode/zsh-vi-mode.plugin.zsh
eval "$(zoxide init zsh)"

alias oc-yolo='OPENCODE_PERMISSION="{\"*\":\"allow\"}" opencode'
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
