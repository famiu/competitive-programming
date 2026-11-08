#!/usr/bin/env bash
# Usage: stress.sh [dir] [iterations]
#
# Compares solution.cpp with brute.cpp on inputs from generator.cpp, which receives the
# iteration number as its seed. Runs until the first failure, or for <iterations> when given.
# The failing case is saved to .stress/ in the problem directory.
#
# Before the first iteration, brute.cpp is checked against the tests that have an expected
# output, except stress_* tests, whose expected output came from brute.cpp, and generator.cpp
# must not print the same input for every one of the first seeds.
#
# For interactive problems, interactor.cpp judges the solution on each generated input instead,
# and brute.cpp is not used.
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

export STRESS_INTERACTIVE=''
is_interactive "$dir" && STRESS_INTERACTIVE=1
programs=(solution.cpp generator.cpp)
[[ -n "$STRESS_INTERACTIVE" ]] || programs+=(brute.cpp)
for f in "${programs[@]}"; do
    [[ -f "$dir/$f" ]] || die "$dir/$f not found; \`just gen-stress\` creates it"
done

# Solution and brute use debug builds so that sanitizers catch errors; the generator only
# needs to be fast.
export SOL_BIN BRUTE_BIN GEN_BIN STRESS_KILL STRESS_DIR
SOL_BIN="$(bin_path debug "$dir" solution)"
BRUTE_BIN="$(bin_path debug "$dir" brute)"
GEN_BIN="$(bin_path release "$dir" generator)"
build debug "$dir/solution.cpp" "$SOL_BIN" "$dir"
[[ -n "$STRESS_INTERACTIVE" ]] || build debug "$dir/brute.cpp" "$BRUTE_BIN" "$dir"
build release "$dir/generator.cpp" "$GEN_BIN" "$dir"
if [[ -n "$STRESS_INTERACTIVE" ]]; then setup_interactor "$dir"; else setup_checker "$dir"; fi
STRESS_KILL="$(time_limit "$dir" debug)"
STRESS_DIR="$dir/.stress"
rm -rf "$STRESS_DIR"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

# Tests the brute does not finish within this many seconds are skipped.
BRUTE_CHECK_SECONDS=1

check_brute() {
    local input name checked=0
    for input in "$dir"/tests/*.in; do
        [[ -f "$input" && -f "${input%.in}.out" ]] || continue
        name="$(basename "${input%.in}")"
        [[ "$name" == stress_* ]] && continue
        run_timed "$BRUTE_CHECK_SECONDS" "$input" "$tmp/brute.out" "$tmp/brute.err" "$BRUTE_BIN"
        if ((RUN_STATUS == 124)); then
            warn "brute.cpp took over ${BRUTE_CHECK_SECONDS}s on test $name; skipped it"
            continue
        fi
        if ((RUN_STATUS != 0)); then
            error "brute.cpp fails on test $name ($(describe_status "$RUN_STATUS"))"
            if [[ -s "$tmp/brute.err" ]]; then
                section "--- stderr (brute) ---"
                print_capped "$tmp/brute.err" stderr
            fi
            exit 1
        fi
        if grep -q '^input check:' "$tmp/brute.err"; then
            error "brute.cpp does not read test $name correctly"
            print_capped "$tmp/brute.err" stderr
            exit 1
        fi
        if ! check_output "$input" "${input%.in}.out" "$tmp/brute.out" "$tmp/report"; then
            error "brute.cpp gives a wrong answer on test $name"
            section "--- input ---"
            print_block "$input"
            show_report "$tmp/report"
            exit 1
        fi
        ((checked += 1))
    done
    ((checked > 0)) || warn "brute.cpp was not checked against any test with an expected output"
}
[[ -n "$STRESS_INTERACTIVE" ]] || check_brute

# A generator that ignores its seed prints the same input every time. Generator failures are
# left to the iterations, which report them in full.
check_variety() {
    local seed
    local -A seen=()
    : > "$tmp/empty"
    for seed in {1..20}; do
        run_timed "$STRESS_KILL" "$tmp/empty" "$tmp/input" "$tmp/generator.err" "$GEN_BIN" "$seed"
        ((RUN_STATUS == 0)) || return 0
        seen["$(md5sum < "$tmp/input")"]=1
    done
    ((${#seen[@]} > 1)) || die "generator.cpp printed the same input for seeds 1 to 20; does it call seed(argc, argv)?"
}
check_variety

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
        *-input) printf '%sFAIL%s %s%s input check%s with seed %s%s%s\n' "$RED" "$RESET" \
            "$RED" "${type%-input}" "$RESET" "$BOLD" "$seed" "$RESET" ;;
        *-re) printf '%sFAIL%s %s%s RE%s (%s) with seed %s%s%s\n' "$RED" "$RESET" \
            "$RED" "${type%-re}" "$RESET" "$(describe_status "$status")" "$BOLD" "$seed" "$RESET" ;;
        interactive)
            local verdict detail=''
            verdict="$(< "$STRESS_DIR/failing.verdict")"
            [[ -s "$STRESS_DIR/failing.detail" ]] && detail=" ($(< "$STRESS_DIR/failing.detail"))"
            printf '%sFAIL%s %s%s%s%s with seed %s%s%s\n' "$RED" "$RESET" "$BOLD" "$verdict" "$RESET" "$detail" \
                "$BOLD" "$seed" "$RESET"
            ;;
    esac

    if [[ "$type" != generator-* ]]; then
        section "--- input ---"
        print_block "$STRESS_DIR/failing.in"
    fi
    [[ -f "$STRESS_DIR/failing.report" ]] && show_report "$STRESS_DIR/failing.report"
    [[ "$type" == interactive ]] && show_interaction "$STRESS_DIR/failing.transcript" "$STRESS_DIR/failing.interactor"
    if [[ -f "$STRESS_DIR/failing.stderr" ]]; then
        local program="${type%-*}"
        [[ "$type" == mismatch || "$type" == interactive ]] && program=solution
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
    printf 'running %d iterations with %d jobs...\n' "$iterations" "$jobs"
    run_batch 1 "$iterations" || report_failure
    printf '%spassed %d iterations%s\n' "$GREEN" "$iterations" "$RESET"
    exit 0
fi

batch=$((jobs * 50)) first=1
if [[ -t 1 ]]; then
    printf 'stress testing with %d jobs (Ctrl-C to stop)...' "$jobs"
else
    printf 'stress testing with %d jobs\n' "$jobs"
fi
while true; do
    run_batch "$first" $((first + batch - 1)) || report_failure
    first=$((first + batch))
    if [[ -t 1 ]]; then
        printf '\r\e[K%spassed %d iterations%s (Ctrl-C to stop)' "$GREEN" $((first - 1)) "$RESET"
    else
        printf 'passed %d iterations\n' $((first - 1))
    fi
done
