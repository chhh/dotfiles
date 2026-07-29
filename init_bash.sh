#!/bin/sh
# Symlinks core dotfiles from this repo into $HOME. Works under `sh ./init_bash.sh`,
# `bash init_bash.sh`, or `zsh init_bash.sh` — POSIX sh syntax only, no bashisms.
set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

link() {
  src="$DOTFILES_DIR/$1"
  dst="$HOME/$1"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$(readlink "$dst" 2>/dev/null || true)" = "$src" ]; then
      echo "ok:      $dst"
      return
    fi
    mv "$dst" "$dst.bak"
    echo "backed up existing $dst -> $dst.bak"
  fi
  ln -s "$src" "$dst"
  echo "linked:  $dst -> $src"
}

for f in .bashrc .aliases .aliases-bash \
         .tmux.conf .dircolors \
         .gitconfig .gitaliases .gitmorealiases .gitignore_global; do
  link "$f"
done

mkdir -p "$HOME/.config"
link .config/nvim
