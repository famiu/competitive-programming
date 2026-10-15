# Output checking for test.sh and the stress scripts. Source it after lib.sh.
#
# A problem directory selects how output is checked, in this order:
#   checker       executable, run as: checker <input> <output> <answer>
#   checker.py    run with python3, same arguments
#   checker.cpp   compiled in release mode, same arguments
#   .compare      built-in comparison: `lines` (default), `tokens`, or `float [eps]`
#
# <output> is the solution's output and <answer> is the expected output, as in testlib.
# Checkers accept by exiting 0; anything they print is shown when they reject.

# setup_checker <problem-dir>
# Sets and exports CHECKER_KIND, CHECKER_PATH, COMPARE_MODE and COMPARE_EPS.
setup_checker() {
    local dir="$1"
    CHECKER_KIND=compare CHECKER_PATH='' COMPARE_MODE=lines COMPARE_EPS=1e-6
    if [[ -x "$dir/checker" && -f "$dir/checker" ]]; then
        CHECKER_KIND=program CHECKER_PATH="$dir/checker"
    elif [[ -f "$dir/checker.py" ]]; then
        require_cmd python3 "needed for checker.py"
        CHECKER_KIND=python CHECKER_PATH="$dir/checker.py"
    elif [[ -f "$dir/checker.cpp" ]]; then
        CHECKER_KIND=program CHECKER_PATH="$(bin_path release "$dir" checker)"
        build release "$dir/checker.cpp" "$CHECKER_PATH" "$dir"
    elif [[ -f "$dir/.compare" ]]; then
        local -a words
        read -ra words < <(grep -v '^[[:space:]]*\(#\|$\)' "$dir/.compare" | head -n 1)
        case "${words[0]:-lines}" in
            lines | tokens) COMPARE_MODE="${words[0]:-lines}" ;;
            float)
                COMPARE_MODE=float
                COMPARE_EPS="${words[1]:-1e-6}"
                ;;
            *) die "$dir/.compare: unknown mode '${words[0]}' (expected lines, tokens or float [eps])" ;;
        esac
    fi
    export CHECKER_KIND CHECKER_PATH COMPARE_MODE COMPARE_EPS
}

# check_output <input> <expected> <actual> <report>
# Returns 0 when <actual> is accepted. On rejection, <report> explains why: a unified diff in
# `lines` mode, the first mismatching token in `tokens`/`float` mode, or the checker's output.
check_output() {
    local input="$1" expected="$2" actual="$3" report="$4"
    : > "$report"
    case "$CHECKER_KIND" in
        program) "$CHECKER_PATH" "$input" "$actual" "$expected" > "$report" 2>&1 ;;
        python) python3 "$CHECKER_PATH" "$input" "$actual" "$expected" > "$report" 2>&1 ;;
        compare)
            case "$COMPARE_MODE" in
                lines) compare_lines "$expected" "$actual" > "$report" ;;
                tokens) compare_tokens "$expected" "$actual" -1 > "$report" ;;
                float) compare_tokens "$expected" "$actual" "$COMPARE_EPS" > "$report" ;;
            esac
            ;;
    esac
}

# Prints the report for a rejected output, colored when it is a diff.
show_report() {
    local report="$1"
    [[ -s "$report" ]] || return 0
    if [[ "$CHECKER_KIND" == compare && "$COMPARE_MODE" == lines ]]; then
        section "--- diff (expected vs actual) ---"
        print_capped "$report" diff colorize
    else
        section "--- checker ---"
        print_capped "$report" "checker output"
    fi
}

# Strips trailing whitespace from each line and drops trailing blank lines.
normalize_lines() {
    awk '{ sub(/[[:space:]]+$/, ""); lines[NR] = $0; if ($0 != "") last = NR }
         END { for (i = 1; i <= last; i++) print lines[i] }' "$1"
}

compare_lines() {
    cmp -s "$1" "$2" && return 0
    diff -u --label expected --label actual <(normalize_lines "$1") <(normalize_lines "$2")
}

# compare_tokens <expected> <actual> <eps>
# Compares whitespace-separated tokens. With eps >= 0, numeric tokens may differ by eps,
# absolute or relative to the expected value.
compare_tokens() {
    awk -v eps="$3" '
        function is_num(s) { return s ~ /^[-+]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][-+]?[0-9]+)?$/ }
        function abs(x) { return x < 0 ? -x : x }
        {
            for (i = 1; i <= NF; i++) {
                if (FILENAME == ARGV[1]) { exp_tok[++ne] = $i; exp_line[ne] = FNR }
                else { act_tok[++na] = $i; act_line[na] = FNR }
            }
        }
        END {
            n = ne < na ? ne : na
            for (i = 1; i <= n; i++) {
                e = exp_tok[i]; a = act_tok[i]
                if (e == a) continue
                if (eps >= 0 && is_num(e) && is_num(a)) {
                    d = abs(e - a); m = abs(e + 0); if (m < 1) m = 1
                    if (d <= eps * m) continue
                }
                printf "token %d (expected line %d, actual line %d): expected \"%s\", got \"%s\"\n", \
                    i, exp_line[i], act_line[i], e, a
                exit 1
            }
            if (ne != na) {
                printf "expected %d tokens, got %d\n", ne, na
                exit 1
            }
        }
    ' "$1" "$2"
}
