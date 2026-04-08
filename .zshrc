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
source $HOME/.zsh-vi-mode/zsh-vi-mode.plugin.zsh


# tmux config block

alias tms='tmux list-sessions'
alias tmw='tmux list-windows'
alias tmp='tmux list-panes'

tm() {
  _tm_session_name_from_pwd() {
    basename "$PWD" | sed 's/[^A-Za-z0-9_-]/_/g'
  }

  case "${1-}" in
    "")
      command tmux
      ;;
    a|attach)
      shift
      [ "$#" -eq 0 ] && command tmux attach || command tmux attach -t "$1"
      ;;
    d|detach)
      [ -n "${TMUX:-}" ] && command tmux detach-client || { echo "Not inside tmux"; return 1; }
      ;;
    s|sessions)
      command tmux list-sessions
      ;;
    w|windows)
      [ "$#" -gt 1 ] && command tmux list-windows -t "$2" || command tmux list-windows
      ;;
    p|panes)
      [ "$#" -gt 1 ] && command tmux list-panes -t "$2" || command tmux list-panes
      ;;
    n|new)
      shift
      [ "$#" -eq 0 ] && command tmux new-session || command tmux new-session -s "$1"
      ;;
    nwd)
      name="$(_tm_session_name_from_pwd)"
      command tmux new-session -s "$name" -c "$PWD" -n shell
      ;;
    cwd)
      name="$(_tm_session_name_from_pwd)"
      if ! command tmux has-session -t "$name" 2>/dev/null; then
        command tmux new-session -d -s "$name" -c "$PWD" -n shell
      fi
      if [ -n "${TMUX:-}" ]; then
        command tmux switch-client -t "$name"
      else
        command tmux attach -t "$name"
      fi
      ;;
    *)
      command tmux "$@"
      ;;
  esac
}

# END: tmux config block
