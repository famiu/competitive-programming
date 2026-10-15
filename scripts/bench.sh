#!/usr/bin/env bash
# Usage: bench.sh [dir] [input]
#
# Builds solution.cpp in release mode and times BENCH_RUNS runs (default 3) on one input,
# reporting the best wall time and the peak memory against the problem's limits.
# Exits 1 when the program fails or exceeds a limit.
# <input> is a file or a test name; the default is the largest tests/*.in.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

runs="${BENCH_RUNS:-3}"
[[ "$runs" =~ ^[1-9][0-9]*$ ]] || die "BENCH_RUNS must be a positive integer"
[[ -x /usr/bin/time ]] || die "/usr/bin/time (GNU time) is not installed; run \`just doctor\` for details"

parse_problem_args "$@"
dir="$PROBLEM_DIR"
(( ${#PROBLEM_ARGS[@]} <= 1 )) || die "usage: just bench [dir] [input]"

input=''
if (( ${#PROBLEM_ARGS[@]} == 1 )); then
    arg="${PROBLEM_ARGS[0]}"
    for candidate in "$arg" "$dir/$arg" "$dir/tests/$arg.in"; do
        if [[ -f "$candidate" ]]; then
            input="$candidate"
            break
        fi
    done
    [[ -n "$input" ]] || die "no input file or test named '$arg'"
else
    input="$(find "$dir/tests" -maxdepth 1 -type f -name '*.in' -printf '%s\t%p\n' 2> /dev/null |
        sort -rn | head -n 1 | cut -f 2-)"
    [[ -n "$input" ]] || die "no tests/*.in in $dir; pass an input file"
fi

sol_bin="$(bin_path release "$dir" solution)"
build release "$dir/solution.cpp" "$sol_bin" "$dir"

limit="$(time_limit "$dir" release)"
kill="$(awk -v l="$limit" 'BEGIN { k = l * 5; if (k < 10) k = 10; print k }')"
ml_mb="$(meta_get "$dir" memory_limit)"

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

printf '%sInput:%s %s (%s bytes)\n' "$CYAN" "$RESET" "$input" "$(wc -c < "$input")"
times=() peak_kb=0 status=0
for ((i = 1; i <= runs; i++)); do
    status=0
    /usr/bin/time -f '%e %M' -o "$tmp/time" timeout "$kill" "$sol_bin" < "$input" > /dev/null 2> "$tmp/err" || status=$?
    read -r t kb < <(tail -n 1 "$tmp/time")
    times+=("$t")
    ((kb > peak_kb)) && peak_kb="$kb"
    ((status == 0)) || break
done

best="$(printf '%s\n' "${times[@]}" | sort -n | head -n 1)"
printf '  %-13s %s%ss%s  %s(runs: %s)%s\n' "Wall time" "$BOLD" "$best" "$RESET" "$DIM" "${times[*]}" "$RESET"
printf '  %-13s %s MB\n' "Peak memory" "$(awk -v kb="$peak_kb" 'BEGIN { printf "%.1f", kb / 1024 }')"

if ((status == 124)); then
    printf '  %-13s %skilled after %ss%s\n' "Exit" "$YELLOW" "$kill" "$RESET"
    exit 1
elif ((status != 0)); then
    printf '  %-13s %s%s%s\n' "Exit" "$RED" "$(describe_status "$status")" "$RESET"
    sed -i '/^timeout: the monitored command dumped core$/d' "$tmp/err"
    if [[ -s "$tmp/err" ]]; then
        section "--- stderr ---"
        print_capped "$tmp/err" stderr
    fi
    exit 1
fi

ok=1
pct="$(awk -v t="$best" -v l="$limit" 'BEGIN { printf "%.0f", t / l * 100 }')"
if awk -v t="$best" -v l="$limit" 'BEGIN { exit !(t <= l) }'; then
    verdict="${GREEN}OK${RESET}"
else
    verdict="${RED}TOO SLOW${RESET}" ok=0
fi
printf '  %-13s %ss  %s (%s%% of limit)\n' "Time limit" "$limit" "$verdict" "$pct"

if [[ -n "$ml_mb" ]]; then
    mpct="$(awk -v kb="$peak_kb" -v ml="$ml_mb" 'BEGIN { printf "%.0f", kb / 1024 / ml * 100 }')"
    if awk -v kb="$peak_kb" -v ml="$ml_mb" 'BEGIN { exit !(kb / 1024 <= ml) }'; then
        verdict="${GREEN}OK${RESET}"
    else
        verdict="${RED}TOO MUCH${RESET}" ok=0
    fi
    printf '  %-13s %s MB  %s (%s%% of limit)\n' "Memory limit" "$ml_mb" "$verdict" "$mpct"
fi
((ok))
