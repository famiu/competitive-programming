#!/usr/bin/env bash
# Usage: run.sh [dir] [input]
#
# Builds solution.cpp in debug mode and runs it with no time limit. <input> is a file or a
# test name (e.g. `02` for tests/02.in); without it, stdin passes through.
#
# For interactive problems, an input file, or piped stdin, is the input of interactor.cpp: the
# solution runs against it, the interaction is shown as it happens and the verdict at the end.
# With stdin a terminal and no input, you type the interactor's side yourself.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"
source "$SCRIPTS_DIR/check.sh"

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

if is_interactive "$dir" && [[ -n "$input" || ! -t 0 ]]; then
    setup_interactor "$dir"
    if [[ -z "$input" ]]; then
        tmp="$(mktemp -d)"
        trap 'rm -rf -- "$tmp"' EXIT
        input="$tmp/stdin.in"
        cat > "$input"
        label=stdin
    else
        label="$(realpath --relative-to="$PWD" "$input")"
    fi
    printf '%s── running solution against interactor.cpp on %s (> solution, < interactor) ──%s\n' \
        "$DIM" "$label" "$RESET" >&2
    run_interactive 1000000 1000000 "$input" "$sol_bin" --live '' ''
    case "$RUN_VERDICT" in
        PASS) color="$GREEN" ;;
        ILE) color="$YELLOW" ;;
        *) color="$RED" ;;
    esac
    printf '%s── %s%s%s%s  %ss%s ──%s\n' "$DIM" "$color" "$RUN_VERDICT" "$RESET" "$DIM" "$RUN_ELAPSED" \
        "${RUN_DETAIL:+  ($RUN_DETAIL)}" "$RESET" >&2
    [[ "$RUN_VERDICT" == PASS ]]
    exit
fi

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
