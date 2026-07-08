eval "$(starship init zsh)"

export LESS='-R'

export EDITOR="/opt/homebrew/bin/nvim"
export VISUAL="$EDITOR"

# pyenv setup: expose pyenv command directory.
# Better than original: one init instead of `init --path` + `init -`, saving ~130ms per shell.
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
# Loads pyenv shims, completions, and shell function; `--no-rehash` skips slow shim scan each startup.
# If newly installed Python console commands do not appear, run `pyenv rehash` once manually.
eval "$(pyenv init - --no-rehash zsh)"

# Most programs ask for this
export PATH="$HOME/.local/bin:$PATH"
# Homebrew Apple silicon Brew bin location
export PATH="/usr/local/bin:$PATH"

# My other conf
source $HOME/.aliases


if (( $+commands[brew] )); then
  # Add Homebrew completions to zsh function path.
  # Better than original: derive prefix from resolved brew path instead of spawning `brew --prefix` every shell.
  brew_prefix="${HOMEBREW_PREFIX:-${commands[brew]:h:h}}"
  FPATH="$brew_prefix/share/zsh-completions:$FPATH"

  autoload -Uz compinit
  # Initialize completions from existing cache.
  # Better than original: `compinit -C` skips slow freshness/security scan; rebuild cache with `rm ~/.zcompdump*` if completions change.
  compinit -C
  unset brew_prefix
fi

# fzf keybindings/completions.
# Better than original: cache generated script instead of spawning `fzf --zsh` every shell.
if (( $+commands[fzf] )); then
  _fzf_zsh_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf-zsh.zsh"
  # Regenerate only when cache is missing. Delete this file after fzf upgrade to refresh keybindings/completions.
  if [[ ! -r "$_fzf_zsh_cache" ]]; then
    mkdir -p "${_fzf_zsh_cache:h}"
    fzf --zsh >| "$_fzf_zsh_cache"
  fi
  # Redirect stderr to silence fzf's known `can't change option: zle` restore warning in non-TTY interactive shells.
  source "$_fzf_zsh_cache" 2>/dev/null
  unset _fzf_zsh_cache
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# uv zsh completions.
# Better than original: cache generated completion script instead of spawning `uv generate-shell-completion zsh` every shell (~60ms).
if (( $+commands[uv] )); then
  _uv_completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/uv-completion.zsh"
  # Regenerate only when cache is missing. Delete this file after major uv upgrade to refresh completions.
  if [[ ! -r "$_uv_completion_cache" ]]; then
    mkdir -p "${_uv_completion_cache:h}"
    uv generate-shell-completion zsh >| "$_uv_completion_cache" 2>/dev/null
  fi
  source "$_uv_completion_cache"
  unset _uv_completion_cache
fi

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
