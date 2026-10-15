#!/usr/bin/env bash
# Usage: stress_iter.sh <seed>
#
# Runs one stress-test iteration; stress.sh starts it through xargs. Configuration comes
# from the environment variables exported by stress.sh and setup_checker. On failure, the
# first iteration to create STRESS_DIR records the case there. Every failure exits 255,
# which makes xargs stop starting new iterations.
set -euo pipefail
trap 'exit 255' ERR
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"
source "$SCRIPTS_DIR/check.sh"

seed="$1"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

# fail <type> <program-whose-stderr-to-keep>
fail() {
    if mkdir "$STRESS_DIR" 2> /dev/null; then
        cp "$tmp/input" "$STRESS_DIR/failing.in"
        [[ -f "$tmp/solution.out" ]] && cp "$tmp/solution.out" "$STRESS_DIR/failing.actual"
        [[ -f "$tmp/brute.out" ]] && cp "$tmp/brute.out" "$STRESS_DIR/failing.expected"
        [[ -s "$tmp/$2.err" ]] && cp "$tmp/$2.err" "$STRESS_DIR/failing.stderr"
        [[ -s "$tmp/report" ]] && cp "$tmp/report" "$STRESS_DIR/failing.report"
        printf '%s\n' "$seed" > "$STRESS_DIR/failing.seed"
        printf '%s\n' "$RUN_STATUS" > "$STRESS_DIR/failing.status"
        printf '%s\n' "$1" > "$STRESS_DIR/failing.type"
    fi
    exit 255
}

# Generators receive the iteration number as their seed.
: > "$tmp/empty"
run_timed "$STRESS_KILL" "$tmp/empty" "$tmp/input" "$tmp/generator.err" "$GEN_BIN" "$seed"
((RUN_STATUS == 124)) && fail generator-tle generator
((RUN_STATUS != 0)) && fail generator-re generator

run_timed "$STRESS_KILL" "$tmp/input" "$tmp/solution.out" "$tmp/solution.err" "$SOL_BIN"
((RUN_STATUS == 124)) && fail solution-tle solution
((RUN_STATUS != 0)) && fail solution-re solution

run_timed "$STRESS_KILL" "$tmp/input" "$tmp/brute.out" "$tmp/brute.err" "$BRUTE_BIN"
((RUN_STATUS == 124)) && fail brute-tle brute
((RUN_STATUS != 0)) && fail brute-re brute

check_output "$tmp/input" "$tmp/brute.out" "$tmp/solution.out" "$tmp/report" || fail mismatch solution
exit 0
