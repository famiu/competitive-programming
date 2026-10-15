#!/usr/bin/env bash
# Usage: stress_save.sh [dir]
#
# Copies the failing case from the last `just stress` run into tests/ as stress_NN.in and
# stress_NN.out. The expected output is brute.cpp's output on that input.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

parse_problem_args "$@"
dir="$PROBLEM_DIR"
(( ${#PROBLEM_ARGS[@]} == 0 )) || die "usage: just stress-save [dir]"
stress_dir="$dir/.stress"
[[ -f "$stress_dir/failing.in" ]] || die "no failing stress case in $stress_dir; run \`just stress\` first"
type="$(cat "$stress_dir/failing.type" 2> /dev/null || true)"
[[ "$type" != generator-* ]] || die "the last stress run failed in the generator; there is no input to save"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

expected="$stress_dir/failing.expected"
if [[ "$type" != mismatch || ! -f "$expected" ]]; then
    brute_bin="$(bin_path debug "$dir" brute)"
    build debug "$dir/brute.cpp" "$brute_bin" "$dir"
    run_timed "$(time_limit "$dir" debug)" "$stress_dir/failing.in" "$tmp/expected" "$tmp/err" "$brute_bin"
    ((RUN_STATUS == 0)) || die "brute.cpp failed on the saved input ($(describe_status "$RUN_STATUS"))"
    expected="$tmp/expected"
fi

mkdir -p "$dir/tests"
n=1
while [[ -e "$(printf '%s/tests/stress_%02d.in' "$dir" "$n")" ]]; do ((n += 1)); done
base="$(printf '%s/tests/stress_%02d' "$dir" "$n")"
cp "$stress_dir/failing.in" "$base.in"
cp "$expected" "$base.out"
printf '%s\n%s\n' "$base.in" "$base.out"
