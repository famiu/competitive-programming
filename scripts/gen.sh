#!/usr/bin/env bash
# Usage: gen.sh [dir] [seed | first-last]
#
# Runs generator.cpp with the given seeds, as `just stress` does. A single seed prints the
# input exactly as generated. A range (default: 1-5) prints each input under a header, cut to
# DIFF_PREVIEW_LINES lines, followed by how many of the inputs are distinct.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

parse_problem_args "$@"
dir="$PROBLEM_DIR"
(( ${#PROBLEM_ARGS[@]} <= 1 )) || die "usage: just gen [dir] [seed | first-last]"
arg="${PROBLEM_ARGS[0]:-1-5}"
if [[ "$arg" =~ ^[0-9]+$ ]]; then
    first="$arg" last=""
elif [[ "$arg" =~ ^([0-9]+)-([0-9]+)$ ]]; then
    first="${BASH_REMATCH[1]}" last="${BASH_REMATCH[2]}"
    ((10#$first <= 10#$last)) || die "empty seed range: $arg"
else
    die "expected a seed or a range of seeds such as 1-20, got '$arg'"
fi

[[ -f "$dir/generator.cpp" ]] || die "$dir/generator.cpp not found; \`just gen-stress\` creates it"
gen_bin="$(bin_path release "$dir" generator)"
build release "$dir/generator.cpp" "$gen_bin" "$dir"
kill="$(time_limit "$dir" debug)"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
: > "$tmp/empty"

# generate <seed>: writes the input to $tmp/input, or exits when the generator fails.
generate() {
    run_timed "$kill" "$tmp/empty" "$tmp/input" "$tmp/err" "$gen_bin" "$1"
    ((RUN_STATUS == 0)) && return 0
    if ((RUN_STATUS == 124)); then
        error "generator.cpp was killed after ${kill}s with seed $1"
    else
        error "generator.cpp failed with seed $1 ($(describe_status "$RUN_STATUS"))"
    fi
    if [[ -s "$tmp/err" ]]; then
        section "--- stderr (generator) ---"
        print_capped "$tmp/err" stderr
    fi
    exit 1
}

if [[ -z "$last" ]]; then
    generate "$first"
    cat "$tmp/input"
    exit 0
fi

declare -A distinct=()
for ((seed = 10#$first; seed <= 10#$last; seed++)); do
    generate "$seed"
    distinct["$(md5sum < "$tmp/input")"]=1
    printf '%s── seed %d ──%s\n' "$CYAN" "$seed" "$RESET"
    head -n "$DIFF_PREVIEW_LINES" "$tmp/input"
    lines="$(wc -l < "$tmp/input")"
    ((lines > DIFF_PREVIEW_LINES)) &&
        printf '%s... (%d lines total, showing the first %d)%s\n' "$DIM" "$lines" "$DIFF_PREVIEW_LINES" "$RESET"
done
printf '%s%d seeds, %d distinct%s\n' "$BOLD" $((10#$last - 10#$first + 1)) "${#distinct[@]}" "$RESET"
