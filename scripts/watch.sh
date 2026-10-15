#!/usr/bin/env bash
# Usage: watch.sh [dir] [case...]
#
# Re-runs `just test` whenever a source file, checker, test or per-problem config changes.
# New files in the problem or tests directory are picked up too. Press q to stop.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

require_cmd entr "needed for watch"
parse_problem_args "$@"
dir="$PROBLEM_DIR"

note "watching $dir"
while true; do
    status=0
    find "$dir" "$dir/tests" -maxdepth 1 -type f \
        \( -name '*.cpp' -o -name '*.py' -o -name '*.in' -o -name '*.out' \
        -o -name '.compare' -o -name '.compile_flags' -o -name checker \) 2> /dev/null |
        entr -d -c "$SCRIPTS_DIR/test.sh" release "$dir" "${PROBLEM_ARGS[@]}" || status=$?
    # entr exits with 2 when a new file appears in a watched directory.
    ((status == 2)) || exit "$status"
done
