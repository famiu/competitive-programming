#!/usr/bin/env bash
# Usage: scaffold.sh new [-t seconds] dir...
#        scaffold.sh stress [dir]
#        scaffold.sh checker [dir]
#
# `new` creates each directory with solution.cpp and prints the directories on stdout. Relative
# paths are resolved from the repository root. Nothing is created when any directory already
# has solution.cpp. -t writes the time limit to meta.json; otherwise tests use
# DEFAULT_TIME_LIMIT.
#
# `stress` adds brute.cpp and generator.cpp; `checker` adds checker.cpp. Existing files are
# never overwritten.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

# copy_template <template> <dest>
copy_template() {
    if [[ -e "$2" ]]; then
        note "exists: $2"
    else
        cp "$TEMPLATES_DIR/$1" "$2"
        note "created: $2"
    fi
}

kind="$1"
shift
case "$kind" in
    new)
        usage="usage: just new [-t seconds] dir..."
        tl=''
        if [[ "${1:-}" == -t ]]; then
            (($# >= 2)) || die "$usage"
            tl="$2"
            shift 2
        fi
        (($# > 0)) || die "$usage"

        dirs=()
        declare -A seen=()
        for target in "$@"; do
            dir="$(cd "$REPO_ROOT" && realpath -m "$target")"
            case "$dir" in
                "$REPO_ROOT") die "refusing to scaffold the repository root; pass a problem path" ;;
                "$REPO_ROOT"/*) ;;
                *) die "path must be inside the repository: $dir" ;;
            esac
            [[ ! -e "$dir/solution.cpp" ]] || die "$dir already has solution.cpp"
            [[ -z "${seen[$dir]:-}" ]] || die "directory given twice: $dir"
            seen[$dir]=1
            dirs+=("$dir")
        done

        for dir in "${dirs[@]}"; do
            mkdir -p "$dir"
            copy_template solution.cpp "$dir/solution.cpp"
            if [[ -n "$tl" ]]; then
                require_cmd jq "needed to write meta.json"
                meta="$dir/meta.json"
                [[ -f "$meta" ]] || printf '{"name": "%s"}\n' "${dir##*/}" > "$meta"
                jq --argjson tl "$tl" '.time_limit = ($tl * 1000 | round)' "$meta" > "$meta.tmp"
                mv "$meta.tmp" "$meta"
            fi
            printf '%s\n' "$dir"
        done
        ;;
    stress)
        parse_problem_args "$@"
        # brute.cpp starts from the solution template so that both share the same helpers.
        copy_template solution.cpp "$PROBLEM_DIR/brute.cpp"
        copy_template generator.cpp "$PROBLEM_DIR/generator.cpp"
        ;;
    checker)
        parse_problem_args "$@"
        copy_template checker.cpp "$PROBLEM_DIR/checker.cpp"
        ;;
    *) die "invalid scaffold kind: $kind" ;;
esac
