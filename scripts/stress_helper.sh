# Stress-testing loop for the `_stress` just recipe.
#
# Usage:
#   source scripts/stress_helper.sh
#   run_stress <target> <sol_bin> <brute_bin> <gen_bin> <checker_bin> <stress_timeout> <diff_preview_lines>
#
# Requires check_helper.sh (verify_check, print_capped_file, $CHECKER_TYPE) to be sourced first.
# Sets $stress_dir for external inspection after a failure.

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

run_stress() {
    local target="$1"
    local sol_bin="$2"
    local brute_bin="$3"
    local gen_bin="$4"
    local checker_bin="$5"
    local stress_timeout="$6"
    local diff_preview_lines="$7"

    local stress_dir="$target/.stress"

    # Keep failures reproducible even for TLE/RE cases, not just mismatches.
    save_failure() {
        local input="$1" expected="$2" actual="$3" seed="$4" iteration="$5"
        mkdir -p "$stress_dir"
        cp "$input" "$stress_dir/failing.in"
        if [[ -n "$expected" && -f "$expected" ]]; then
            cp "$expected" "$stress_dir/failing.expected"
        else
            rm -f "$stress_dir/failing.expected"
        fi
        if [[ -n "$actual" && -f "$actual" ]]; then
            cp "$actual" "$stress_dir/failing.actual"
        else
            rm -f "$stress_dir/failing.actual"
        fi
        printf '%s\n' "$seed" > "$stress_dir/failing.seed"
        printf '%s\n' "$iteration" > "$stress_dir/failing.iteration"
        dim "Artifacts saved to: $stress_dir/" >&2
    }

    run_stress_binary() {
        local label="$1" bin="$2" input="$3" output="$4"

        if timeout "$stress_timeout" "$bin" < "$input" > "$output"; then
            return 0
        fi

        local status=$?
        if (( status == 124 )); then
            printf "${RED}FAIL${RESET} (${YELLOW}%s TLE${RESET}) on iteration ${BOLD}%d${RESET}\n" "$label" "$iter" >&2
        else
            printf "${RED}FAIL${RESET} (${RED}%s RE${RESET}) on iteration ${BOLD}%d${RESET}\n" "$label" "$iter" >&2
        fi
        return "$status"
    }

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf -- "$tmp_dir"' EXIT

    local iter=0
    while true; do
        (( iter += 1 ))

        local input_f="$tmp_dir/input.txt"
        local sol_out="$tmp_dir/solution.out"
        local brute_out="$tmp_dir/brute.out"
        local diff_preview_f="$tmp_dir/diff.preview"
        local diagnostics_f="$tmp_dir/diagnostics"
        local seed="$iter"

        # Generators receive the iteration number as a deterministic seed.
        if ! "$gen_bin" "$seed" > "$input_f"; then
            error "generator failed on iteration $iter"
            exit 1
        fi

        if ! run_stress_binary "solution" "$sol_bin" "$input_f" "$sol_out"; then
            save_failure "$input_f" "" "$sol_out" "$seed" "$iter"
            exit 1
        fi

        if ! run_stress_binary "brute" "$brute_bin" "$input_f" "$brute_out"; then
            save_failure "$input_f" "$brute_out" "$sol_out" "$seed" "$iter"
            exit 1
        fi

        if ! verify_check "$input_f" "$brute_out" "$sol_out" "$diagnostics_f" "$diff_preview_f"; then
            printf "${BOLD}${RED}MISMATCH${RESET} on iteration ${BOLD}%d${RESET}\n" "$iter" >&2
            save_failure "$input_f" "$brute_out" "$sol_out" "$seed" "$iter"
            local input_bytes
            input_bytes="$(wc -c < "$input_f")"
            if (( input_bytes <= 4096 )); then
                section "--- input ---"
                while IFS= read -r line; do
                    printf "${DIM}│${RESET} %s\n" "$line" >&2
                done < "$input_f"
            else
                dim "Input is $input_bytes bytes; see $stress_dir/failing.in" >&2
            fi
            if [[ "$CHECKER_TYPE" == "diff" ]]; then
                section "--- normalized diff preview (expected vs actual, first $diff_preview_lines lines) ---"
                print_capped_file "$diff_preview_f" "diff"
            else
                error "checker rejected output on iteration $iter"
                if [[ -s "$diagnostics_f" ]]; then
                    section "--- checker diagnostics (first $diff_preview_lines lines) ---"
                    print_capped_file "$diagnostics_f" "diagnostics"
                fi
            fi
            {
                printf "${BOLD}Repro hint:${RESET} "
                printf '%q ' "$gen_bin" "$seed"
                printf '> '
                printf '%q\n' "$stress_dir/failing.in"
            } >&2
            exit 1
        fi

        if (( iter <= 10 || iter % 100 == 0 )); then
            printf "${GREEN}passed %d iteration(s)${RESET}\n" "$iter"
        fi
    done
}
