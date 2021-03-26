alias ll="ls -la --color=auto"

gkaw() {
    gitk --all --since="$1".weeks
}

gkgw() {
    gitk --glob="$2" --since="$1".weeks
}
