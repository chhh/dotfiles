#!/usr/bin/env bash
# Install this repo's AI agent skills (ai/skills/<name>/SKILL.md, plus any
# supporting files alongside it) into the local per-user skill directories
# that Claude Code, Pi, and Codex discover automatically.
#
# For each skill found under ai/skills/, and for each known agent target,
# asks for confirmation before installing (default: yes on Enter, matching
# the usual apt-get/dnf-style "[Y/n]" convention) unless -y/--yes is given,
# in which case everything installs without prompting -- the standard flag
# for "auto-accept yes" on Linux/Unix CLIs (apt-get -y, yum -y, npm -y, ...).
#
# Usage:
#   ./install-skills.sh              # interactive, asks before each install
#   ./install-skills.sh -y           # install everywhere, no prompts
#   ./install-skills.sh --yes
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
SKILLS_DIR="$SCRIPT_DIR/skills"

AUTO_YES=0

usage() {
    # Print the header comment block (everything from line 2 up to the first
    # line that isn't a '#' comment), stripped of its leading '# '.
    awk 'NR==1{next} /^#/{sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
}

for arg in "$@"; do
    case "$arg" in
        -y|--yes)
            AUTO_YES=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "No skills directory found at: $SKILLS_DIR" >&2
    exit 1
fi

# name -> local skills directory each agent reads on its own, per-user.
TARGET_NAMES=("Claude Code" "Pi agent" "Codex")
TARGET_DIRS=("$HOME/.claude/skills" "$HOME/.pi/agent/skills" "${CODEX_HOME:-$HOME/.codex}/skills")

confirm() {
    # confirm "prompt text" -- returns 0 (yes) if AUTO_YES, or the user
    # accepts an "[Y/n]"-style prompt (Enter alone counts as yes).
    local prompt="$1"
    if [[ "$AUTO_YES" -eq 1 ]]; then
        return 0
    fi
    local reply
    read -r -p "$prompt [Y/n] " reply
    [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
}

installed_any=0

for skill_path in "$SKILLS_DIR"/*/; do
    [[ -f "${skill_path}SKILL.md" ]] || continue
    skill_name="$(basename "$skill_path")"

    for i in "${!TARGET_NAMES[@]}"; do
        target_name="${TARGET_NAMES[$i]}"
        target_root="${TARGET_DIRS[$i]}"
        dest_dir="$target_root/$skill_name"

        note=""
        [[ -e "$dest_dir/SKILL.md" ]] && note=" (already installed there -- will overwrite)"
        [[ -n "$note" && "$AUTO_YES" -eq 1 ]] && echo "  note: $dest_dir/$note"

        if confirm "Install '$skill_name' skill for $target_name at $dest_dir/$note"; then
            mkdir -p "$dest_dir"
            cp -R "${skill_path}." "$dest_dir/"
            echo "  installed: $dest_dir/SKILL.md"
            installed_any=1
        else
            echo "  skipped: $target_name"
        fi
    done
done

if [[ "$installed_any" -eq 0 ]]; then
    echo "Nothing installed."
fi
