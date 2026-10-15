#!/usr/bin/env bash
# Usage: copy.sh [dir]
#
# Copies solution.cpp to the clipboard.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

parse_problem_args "$@"
src="$PROBLEM_DIR/solution.cpp"
[[ -f "$src" ]] || die "expected $src"
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy &> /dev/null; then
    wl-copy < "$src"
elif command -v xclip &> /dev/null; then
    xclip -selection clipboard < "$src"
elif command -v pbcopy &> /dev/null; then
    pbcopy < "$src"
else
    die "no clipboard tool found (wl-copy, xclip or pbcopy)"
fi
note "copied $src ($(wc -l < "$src") lines)"
