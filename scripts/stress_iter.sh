#!/usr/bin/env bash
# stress_iter.sh — run one iteration of stress testing (invoked by GNU parallel)
#
# Usage:
#   stress_iter.sh <sol_bin> <brute_bin> <gen_bin> <checker_bin>
#                  <checker_type> <checker_target>
#                  <stress_timeout> <diff_preview_lines>
#                  <iter> <stress_dir>

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
source "$(dirname "${BASH_SOURCE[0]}")/check_helper.sh"

sol_bin="$1"
brute_bin="$2"
gen_bin="$3"
checker_bin="$4"
checker_type="$5"
checker_target="$6"
stress_timeout="$7"
diff_preview_lines="$8"
iter="$9"
stress_dir="${10}"

CHECKER_BIN="$checker_bin"
CHECKER_TYPE="$checker_type"
CHECKER_TARGET="$checker_target"
DIFF_PREVIEW_LINES="$diff_preview_lines"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

input_f="$tmp_dir/input.txt"
sol_out="$tmp_dir/solution.out"
brute_out="$tmp_dir/brute.out"
diff_preview_f="$tmp_dir/diff.preview"
diagnostics_f="$tmp_dir/diagnostics"

# Atomic failure save — only the first parallel job to fail gets to write
save_failure() {
    local input="$1" expected="$2" actual="$3" seed="$4" iteration="$5"
    local fail_type="$6" diff_src="${7:-}" diag_src="${8:-}"
    local fail_dir="$stress_dir/fail"
    if mkdir "$fail_dir" 2>/dev/null; then
        cp "$input" "$fail_dir/failing.in" 2>/dev/null || true
        [[ -n "$expected" && -f "$expected" ]] && cp "$expected" "$fail_dir/failing.expected" 2>/dev/null || true
        [[ -n "$actual" && -f "$actual" ]] && cp "$actual" "$fail_dir/failing.actual" 2>/dev/null || true
        printf '%s\n' "$seed" > "$fail_dir/failing.seed"
        printf '%s\n' "$iteration" > "$fail_dir/failing.iteration"
        printf '%s\n' "$fail_type" > "$fail_dir/failing.type"
        [[ -n "$diff_src" && -f "$diff_src" ]] && cp "$diff_src" "$fail_dir/failing.diff_preview" 2>/dev/null || true
        [[ -n "$diag_src" && -f "$diag_src" ]] && cp "$diag_src" "$fail_dir/failing.diagnostics" 2>/dev/null || true
    fi
}

# Generate
gen_status=0
timeout "$stress_timeout" "$gen_bin" "$iter" > "$input_f" || gen_status=$?
if (( gen_status == 124 )); then
    save_failure "$input_f" "" "" "$iter" "$iter" "generator-tle"
    exit 1
elif (( gen_status != 0 )); then
    save_failure "$input_f" "" "" "$iter" "$iter" "generator-re"
    exit 1
fi

# Run solution
sol_status=0
timeout "$stress_timeout" "$sol_bin" < "$input_f" > "$sol_out" || sol_status=$?
if (( sol_status == 124 )); then
    save_failure "$input_f" "" "$sol_out" "$iter" "$iter" "solution-tle"
    exit 1
elif (( sol_status != 0 )); then
    save_failure "$input_f" "" "$sol_out" "$iter" "$iter" "solution-re"
    exit 1
fi

# Run brute
brute_status=0
timeout "$stress_timeout" "$brute_bin" < "$input_f" > "$brute_out" || brute_status=$?
if (( brute_status == 124 )); then
    save_failure "$input_f" "$brute_out" "$sol_out" "$iter" "$iter" "brute-tle"
    exit 1
elif (( brute_status != 0 )); then
    save_failure "$input_f" "$brute_out" "$sol_out" "$iter" "$iter" "brute-re"
    exit 1
fi

# Compare
if ! verify_check "$input_f" "$brute_out" "$sol_out" "$diagnostics_f" "$diff_preview_f"; then
    save_failure "$input_f" "$brute_out" "$sol_out" "$iter" "$iter" "mismatch" "$diff_preview_f" "$diagnostics_f"
    exit 1
fi
