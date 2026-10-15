#!/usr/bin/env bash
# Usage: stress.sh [dir] [iterations]
#
# Compares solution.cpp with brute.cpp on inputs from generator.cpp, which receives the
# iteration number as its seed. Runs until the first failure, or for <iterations> when given.
# The failing case is saved to .stress/ in the problem directory.
#
# STRESS_JOBS sets the number of parallel iterations (default: number of CPUs).
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"
source "$SCRIPTS_DIR/check.sh"

parse_problem_args "$@"
dir="$PROBLEM_DIR"
(( ${#PROBLEM_ARGS[@]} <= 1 )) || die "usage: just stress [dir] [iterations]"
iterations="${PROBLEM_ARGS[0]:-}"
[[ -z "$iterations" || "$iterations" =~ ^[1-9][0-9]*$ ]] || die "iterations must be a positive integer"
jobs="${STRESS_JOBS:-$(nproc)}"
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || die "STRESS_JOBS must be a positive integer"

for f in solution.cpp brute.cpp generator.cpp; do
    [[ -f "$dir/$f" ]] || die "$dir/$f not found; \`just gen-stress\` creates brute.cpp and generator.cpp"
done

# Solution and brute use debug builds so that sanitizers catch errors; the generator only
# needs to be fast.
export SOL_BIN BRUTE_BIN GEN_BIN STRESS_KILL STRESS_DIR
SOL_BIN="$(bin_path debug "$dir" solution)"
BRUTE_BIN="$(bin_path debug "$dir" brute)"
GEN_BIN="$(bin_path release "$dir" generator)"
build debug "$dir/solution.cpp" "$SOL_BIN" "$dir"
build debug "$dir/brute.cpp" "$BRUTE_BIN" "$dir"
build release "$dir/generator.cpp" "$GEN_BIN" "$dir"
setup_checker "$dir"
STRESS_KILL="$(time_limit "$dir" debug)"
STRESS_DIR="$dir/.stress"
rm -rf "$STRESS_DIR"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

# run_batch <first> <last>: returns non-zero when an iteration failed.
run_batch() {
    local status=0
    seq "$1" "$2" | xargs -P "$jobs" -n 1 "$SCRIPTS_DIR/stress_iter.sh" 2> "$tmp/xargs.err" || status=$?
    grep -v 'exited with status 255; aborting' "$tmp/xargs.err" >&2 || true
    return "$status"
}

report_failure() {
    [[ -f "$STRESS_DIR/failing.type" ]] || die "a stress iteration failed without recording a case"
    local type seed status rel
    type="$(< "$STRESS_DIR/failing.type")"
    seed="$(< "$STRESS_DIR/failing.seed")"
    status="$(< "$STRESS_DIR/failing.status")"
    rel="$(realpath --relative-to="$PWD" "$STRESS_DIR")"

    [[ -t 1 ]] && printf '\r\e[K'
    case "$type" in
        mismatch) printf '%sMISMATCH%s with seed %s%s%s\n' "$BOLD$RED" "$RESET" "$BOLD" "$seed" "$RESET" ;;
        *-tle) printf '%sFAIL%s %s%s TLE%s (killed after %ss) with seed %s%s%s\n' "$RED" "$RESET" \
            "$YELLOW" "${type%-tle}" "$RESET" "$STRESS_KILL" "$BOLD" "$seed" "$RESET" ;;
        *-re) printf '%sFAIL%s %s%s RE%s (%s) with seed %s%s%s\n' "$RED" "$RESET" \
            "$RED" "${type%-re}" "$RESET" "$(describe_status "$status")" "$BOLD" "$seed" "$RESET" ;;
    esac

    if [[ "$type" != generator-* ]]; then
        section "--- input ---"
        print_block "$STRESS_DIR/failing.in"
    fi
    [[ -f "$STRESS_DIR/failing.report" ]] && show_report "$STRESS_DIR/failing.report"
    if [[ -f "$STRESS_DIR/failing.stderr" ]]; then
        local program="${type%-*}"
        [[ "$type" == mismatch ]] && program=solution
        section "--- stderr ($program) ---"
        print_capped "$STRESS_DIR/failing.stderr" stderr
    fi

    echo >&2
    note "Saved to $rel/"
    if [[ "$type" != generator-* ]]; then
        printf '%sReproduce:%s      just run %s/failing.in\n' "$BOLD" "$RESET" "$rel" >&2
        printf '%sKeep as a test:%s just stress-save\n' "$BOLD" "$RESET" >&2
    else
        printf '%sReproduce:%s      %s %s\n' "$BOLD" "$RESET" "$GEN_BIN" "$seed" >&2
    fi
    exit 1
}

if [[ -n "$iterations" ]]; then
    run_batch 1 "$iterations" || report_failure
    printf '%spassed %d iterations%s\n' "$GREEN" "$iterations" "$RESET"
    exit 0
fi

batch=$((jobs * 50)) first=1
while true; do
    run_batch "$first" $((first + batch - 1)) || report_failure
    first=$((first + batch))
    if [[ -t 1 ]]; then
        printf '\r\e[K%spassed %d iterations%s (Ctrl-C to stop)' "$GREEN" $((first - 1)) "$RESET"
    else
        printf 'passed %d iterations\n' $((first - 1))
    fi
done
