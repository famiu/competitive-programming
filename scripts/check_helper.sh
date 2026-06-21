# Shared checker + diff helpers for the `_test` and `_stress` just recipes.
#
# Usage:
#   source scripts/check_helper.sh
#   require_in_repo <target> <repo>
#   resolve_rel_dir <target> <repo>        # prints relative path
#   resolve_checker <target> <checker_bin> <cxx> <release_flags>
#   verify_check <input> <expected> <actual> <diagnostics> <diff_preview>
#   normalize <file>
#   print_capped_file <file> <noun>
#
# resolve_checker sets CHECKER_TYPE, CHECKER_TARGET, CHECKER_BIN for verify_check.
# DIFF_PREVIEW_LINES must be set before calling print_capped_file.

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

require_in_repo() {
    local target="$1" repo="$2"
    case "$target" in
        "$repo"|"$repo"/*) ;;
        *)
            error "path must be inside the repository: $target"
            exit 1
            ;;
    esac
}

resolve_rel_dir() {
    local target="$1" repo="$2"
    realpath --relative-to="$repo" "$target"
}

resolve_checker() {
    local target="$1"
    local checker_bin="$2"
    local cxx="$3"
    local release_flags="$4"

    CHECKER_TARGET="$target"
    CHECKER_BIN="$checker_bin"

    if [[ -x "$target/checker" ]]; then
        CHECKER_TYPE="binary"
    elif [[ -f "$target/checker.py" ]]; then
        CHECKER_TYPE="python"
    elif [[ -f "$target/checker.cpp" ]]; then
        CHECKER_TYPE="cpp"
        mkdir -p "$(dirname "$checker_bin")"
        $cxx $release_flags "$target/checker.cpp" -o "$checker_bin"
    else
        CHECKER_TYPE="diff"
    fi
}

colorize_diff() {
    while IFS= read -r line; do
        if [[ "$line" == "< "* ]]; then
            printf "${RED}%s${RESET}\n" "$line"
        elif [[ "$line" == "> "* ]]; then
            printf "${GREEN}%s${RESET}\n" "$line"
        elif [[ "$line" =~ ^[0-9] ]]; then
            printf "${CYAN}%s${RESET}\n" "$line"
        elif [[ "$line" == "---" ]]; then
            printf "${DIM}%s${RESET}\n" "$line"
        else
            printf '%s\n' "$line"
        fi
    done
}

verify_check() {
    local input_f="$1" expected_f="$2" actual_f="$3"
    local diagnostics_f="$4" diff_preview_f="$5"
    case "$CHECKER_TYPE" in
        binary) "$CHECKER_TARGET/checker" "$input_f" "$expected_f" "$actual_f" > "$diagnostics_f" 2>&1 ;;
        python)  python3 "$CHECKER_TARGET/checker.py" "$input_f" "$expected_f" "$actual_f" > "$diagnostics_f" 2>&1 ;;
        cpp)     "$CHECKER_BIN" "$input_f" "$expected_f" "$actual_f" > "$diagnostics_f" 2>&1 ;;
        diff)
            if cmp -s "$expected_f" "$actual_f"; then
                return 0
            fi
            diff <(normalize "$expected_f") <(normalize "$actual_f") > "$diff_preview_f" 2>/dev/null
            local diff_status=$?
            if [[ $diff_status -ne 0 ]]; then
                colorize_diff < "$diff_preview_f" > "${diff_preview_f}.color"
                mv "${diff_preview_f}.color" "$diff_preview_f"
            fi
            return $diff_status
            ;;
    esac
}

normalize() {
    local limit
    limit=$(awk '/[^[:space:]]/ { last = NR } END { print last + 0 }' "$1")
    if [[ -z "$limit" || "$limit" -eq 0 ]]; then
        return 0
    fi
    awk -v limit="$limit" 'NR <= limit { sub(/[[:space:]]+$/, ""); print }' "$1"
}

read_compile_flags() {
    local target="$1"
    local extra=""
    if [[ -f "$target/.compile_flags" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            extra+=" $line"
        done < "$target/.compile_flags"
    fi
    printf '%s' "$extra"
}

print_capped_file() {
    local file="$1" noun="$2"

    awk -v max="$DIFF_PREVIEW_LINES" -v noun="$noun" '
        NR <= max { print > "/dev/stderr" }
        END {
            if (NR > max) {
                printf "... %s truncated (%d total lines; showing first %d)\n", noun, NR, max > "/dev/stderr"
            }
        }
    ' "$file"
}

read_problem_timeout() {
    local target="$1"
    local base_timeout="$2"
    local factor="${3:-1}"
    local meta="$target/meta.json"

    if [[ -f "$meta" ]] && command -v jq &>/dev/null; then
        local tl_ms
        tl_ms=$(jq -r '.time_limit // empty' "$meta" 2>/dev/null)
        if [[ -n "$tl_ms" && "$tl_ms" != "null" && "$tl_ms" != "0" ]]; then
            local base_s="${base_timeout%s}"
            awk -v tl="$tl_ms" -v f="$factor" -v b="$base_s" \
                'BEGIN { s = tl / 1000 * f; if (s < b) s = b; printf "%.1fs", s }'
            return 0
        fi
    fi
    printf '%s' "$base_timeout"
}


