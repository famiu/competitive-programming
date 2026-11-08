#!/usr/bin/env bash
# Usage: info.sh [dir]
#
# Prints the problem's metadata from meta.json and what the tooling will use for it.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"
source "$SCRIPTS_DIR/check.sh"

parse_problem_args "$@"
dir="$PROBLEM_DIR"

if [[ -f "$dir/meta.json" ]]; then
    printf '%s%s%s\n' "$BOLD" "$(meta_get "$dir" name)" "$RESET"
    for key in Platform URL; do
        value="$(meta_get "$dir" "${key,,}")"
        [[ -n "$value" ]] && printf '  %-14s %s\n' "$key" "$value"
    done
    ml="$(meta_get "$dir" memory_limit)"
    [[ -n "$ml" ]] && printf '  %-14s %s MB\n' "Memory limit" "$ml"
    is_interactive "$dir" && printf '  %-14s %s\n' "Interactive" "yes"
else
    printf '%s%s%s %s(no meta.json)%s\n' "$BOLD" "$(basename "$dir")" "$RESET" "$DIM" "$RESET"
fi
printf '  %-14s %ss' "Time limit" "$(time_limit "$dir" release)"
time_limit_set "$dir" || printf ' %s(default, not set)%s' "$YELLOW" "$RESET"
printf '\n'
contest="$(meta_get "$dir" contest)"
[[ -n "$contest" ]] && printf '  %-14s %s\n' "Contest" "$contest"

shopt -s nullglob
tests=("$dir"/tests/*.in)
printf '  %-14s %d\n' "Tests" "${#tests[@]}"

if is_interactive "$dir"; then
    if [[ -f "$dir/interactor.cpp" ]]; then
        printf '  %-14s %s\n' "Interactor" interactor.cpp
    else
        printf '  %-14s %smissing; `just gen-interactor` creates it%s\n' "Interactor" "$YELLOW" "$RESET"
    fi
    exit 0
elif [[ -x "$dir/checker" && -f "$dir/checker" ]]; then
    checker=checker
elif [[ -f "$dir/checker.py" ]]; then
    checker=checker.py
elif [[ -f "$dir/checker.cpp" ]]; then
    checker=checker.cpp
else
    setup_checker "$dir"
    checker="built-in ($COMPARE_MODE)"
    [[ "$COMPARE_MODE" == float ]] && checker="built-in (float, eps $COMPARE_EPS)"
fi
printf '  %-14s %s\n' "Checker" "$checker"
