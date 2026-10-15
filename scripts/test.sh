#!/usr/bin/env bash
# Usage: test.sh <debug|release> [dir] [case...]
#
# Builds solution.cpp and runs it on tests/*.in. Cases are names or glob patterns matched
# against test names (e.g. `02`, `custom_*`), separated by spaces or commas; the default is
# every test. Tests without a matching .out file are run and their output is shown.
# Exits 1 when any test fails.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"
source "$SCRIPTS_DIR/check.sh"

mode="$1"
shift
parse_problem_args "$@"
dir="$PROBLEM_DIR"

patterns=()
for arg in "${PROBLEM_ARGS[@]}"; do
    IFS=',' read -ra parts <<< "$arg"
    for p in "${parts[@]}"; do
        p="${p//[[:space:]]/}"
        [[ -n "$p" ]] && patterns+=("$p")
    done
done
((${#patterns[@]} > 0)) || patterns=('*')

[[ -d "$dir/tests" ]] || die "no tests directory in $dir"
declare -A seen=()
inputs=()
for p in "${patterns[@]}"; do
    matched=0
    while IFS= read -r -d '' f; do
        matched=1
        [[ -n "${seen[$f]:-}" ]] && continue
        seen[$f]=1
        inputs+=("$f")
    done < <(find "$dir/tests" -maxdepth 1 -type f -name "$p.in" -print0 | sort -z)
    ((matched)) || die "no test matches '$p' in $dir/tests"
done

sol_bin="$(bin_path "$mode" "$dir" solution)"
build "$mode" "$dir/solution.cpp" "$sol_bin" "$dir"
setup_checker "$dir"

limit="$(time_limit "$dir" "$mode")"
kill="$(kill_after "$limit")"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

passed=0 failed=0 unchecked=0 total="${#inputs[@]}" idx=0
for input in "${inputs[@]}"; do
    ((idx += 1))
    name="$(basename "${input%.in}")"
    expected="${input%.in}.out"
    run_timed "$kill" "$input" "$tmp/out" "$tmp/err" "$sol_bin"
    elapsed="$RUN_ELAPSED"
    slow="$(awk -v e="$elapsed" -v l="$limit" 'BEGIN { print (e > l) ? 1 : 0 }')"

    verdict='' detail=''
    if ((RUN_STATUS == 124)); then
        verdict=TLE detail="killed after ${kill}s"
    elif ((RUN_STATUS != 0)); then
        verdict=RE detail="$(describe_status "$RUN_STATUS")"
    elif [[ ! -f "$expected" ]]; then
        verdict=OUT detail="no expected output"
    elif check_output "$input" "$expected" "$tmp/out" "$tmp/report"; then
        verdict=PASS
        ((slow)) && verdict=TLE detail="output correct"
    else
        verdict=WA
        ((slow)) && detail="also over the time limit"
    fi

    case "$verdict" in
        PASS) color="$GREEN" ;;
        TLE) color="$YELLOW" ;;
        OUT) color="$CYAN" ;;
        *) color="$RED" ;;
    esac
    printf '[%d/%d] %s%-4s%s %s  %s%ss%s' "$idx" "$total" "$color" "$verdict" "$RESET" "$name" "$DIM" "$elapsed" "$RESET"
    [[ -n "$detail" ]] && printf '  %s(%s)%s' "$DIM" "$detail" "$RESET"
    printf '\n'

    case "$verdict" in
        PASS)
            ((passed += 1))
            continue
            ;;
        OUT)
            ((unchecked += 1))
            section "--- output ---"
            print_capped "$tmp/out" output
            ;;
        WA)
            ((failed += 1))
            show_report "$tmp/report"
            ;;
        *) ((failed += 1)) ;;
    esac
    if [[ -s "$tmp/err" ]]; then
        section "--- stderr ---"
        print_capped "$tmp/err" stderr
    fi
    echo >&2
done

printf '%s────────────────────────────────────%s\n' "$DIM" "$RESET"
summary="${GREEN}${passed} passed${RESET}"
((failed > 0)) && summary+=", ${RED}${failed} failed${RESET}"
((unchecked > 0)) && summary+=", ${CYAN}${unchecked} without expected output${RESET}"
printf '%s  %s(time limit %ss)%s\n' "$summary" "$DIM" "$limit" "$RESET"
((failed == 0))
