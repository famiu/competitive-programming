#!/usr/bin/env bash
# Usage: clean.sh [dir]
#
# Removes build outputs and .stress/ artifacts for one problem, or for everything
# (including precompiled headers) when no directory is given.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

if (($# > 0)); then
    dir="$(find_problem_dir "$1")"
    rel="$(realpath --relative-to="$REPO_ROOT" "$dir")"
    for path in "$BIN_DIR/debug/$rel" "$BIN_DIR/release/$rel" "$dir/.stress"; do
        if [[ -e "$path" ]]; then
            rm -rf -- "$path"
            note "removed: $path"
        fi
    done
    exit 0
fi

if [[ -e "$BIN_DIR" ]]; then
    rm -rf -- "$BIN_DIR"
    note "removed: $BIN_DIR"
fi
while IFS= read -r -d '' path; do
    rm -rf -- "$path"
    note "removed: $path"
done < <(find "$PROBLEMS_DIR" -type d -name .stress -prune -print0)
