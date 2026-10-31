#!/usr/bin/env bash
# Usage: archive.sh [dir] [site name] [--commit]
#
# Moves a problem from scratch/ to problems/<site>/<id>_<slug> (see archive.py for how it is
# named), removes its build outputs and the contest directory when that is left empty, and
# prints the destination. --commit then commits it as `just commit` does.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

commit=0 args=()
for arg in "$@"; do
    if [[ "$arg" == --commit ]]; then commit=1; else args+=("$arg"); fi
done
parse_problem_args "${args[@]}"
dir="$PROBLEM_DIR"
case "$dir" in
    "$SCRATCH_DIR"/*) ;;
    *) die "not inside scratch/: $dir" ;;
esac
((${#PROBLEM_ARGS[@]} == 0 || ${#PROBLEM_ARGS[@]} == 2)) || die "usage: just archive [dir] [site name] [--commit]"

rel="$(realpath --relative-to="$REPO_ROOT" "$dir")"
dest="$(python3 "$SCRIPTS_DIR/archive.py" "$dir" "${PROBLEM_ARGS[@]}")"
rm -rf -- "$BIN_DIR/debug/$rel" "$BIN_DIR/release/$rel"
note "moved $rel to $(realpath --relative-to="$REPO_ROOT" "$dest")"
parent="$(dirname "$dir")"
[[ "$parent" != "$SCRATCH_DIR" ]] && rmdir -- "$parent" 2> /dev/null && note "removed empty $(realpath --relative-to="$REPO_ROOT" "$parent")"
printf '%s\n' "$dest"

((commit)) && exec "$SCRIPTS_DIR/commit.sh" new "$dest"
exit 0
