#!/usr/bin/env bash
# Usage: run.sh [dir] [input]
#
# Builds solution.cpp in debug mode and runs it with no time limit. <input> is a file or a
# test name (e.g. `02` for tests/02.in); without it, stdin passes through.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

parse_problem_args "$@"
dir="$PROBLEM_DIR"
(( ${#PROBLEM_ARGS[@]} <= 1 )) || die "usage: just run [dir] [input]"

input=''
if (( ${#PROBLEM_ARGS[@]} == 1 )); then
    arg="${PROBLEM_ARGS[0]}"
    if [[ -f "$arg" ]]; then
        input="$arg"
    elif [[ -f "$dir/$arg" ]]; then
        input="$dir/$arg"
    elif [[ -f "$dir/tests/$arg.in" ]]; then
        input="$dir/tests/$arg.in"
    else
        die "no input file or test named '$arg'"
    fi
fi

sol_bin="$(bin_path debug "$dir" solution)"
build debug "$dir/solution.cpp" "$sol_bin" "$dir"

# Marks where the build ends and the program starts, so that a program waiting for input
# does not look like a build that is still running.
if [[ -n "$input" ]]; then
    printf '%s── running solution on %s ──%s\n' "$DIM" "$(realpath --relative-to="$PWD" "$input")" "$RESET" >&2
    exec "$sol_bin" < "$input"
fi
if [[ -t 0 ]]; then
    printf '%s── running solution; type the input, then press Ctrl-D ──%s\n' "$GREEN" "$RESET" >&2
fi
exec "$sol_bin"
