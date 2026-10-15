#!/usr/bin/env bash
# Usage: scaffold.sh new [url-or-dir...]
#        scaffold.sh stress [dir]
#        scaffold.sh checker [dir]
#
# `new` fetches problem URLs with cpfetch (command line in $CPFETCH) into problems/<site>/,
# creates solution.cpp in each problem directory, and prints the directories on stdout.
# `stress` adds brute.cpp and generator.cpp; `checker` adds checker.cpp.
# Existing files are never overwritten.
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
        (($# > 0)) || set -- .
        urls=() dirs=() status=0
        for target in "$@"; do
            if [[ "$target" =~ ^https?:// ]]; then
                urls+=("$target")
            else
                dirs+=("$(realpath -m "$target")")
            fi
        done
        if ((${#urls[@]} > 0)); then
            read -ra cpfetch <<< "${CPFETCH:?CPFETCH is not set}"
            fetched="$("${cpfetch[@]}" fetch "${urls[@]}" --nest --out-dir "$PROBLEMS_DIR")" || {
                error "cpfetch could not fetch every URL"
                status=1
            }
            [[ -n "$fetched" ]] && mapfile -t -O "${#dirs[@]}" dirs <<< "$fetched"
        fi
        for dir in "${dirs[@]}"; do
            [[ -n "$dir" ]] || continue
            case "$dir" in
                "$REPO_ROOT") die "refusing to scaffold the repository root; pass a problem path or URL" ;;
                "$REPO_ROOT"/*) ;;
                *) die "path must be inside the repository: $dir" ;;
            esac
            mkdir -p "$dir"
            copy_template solution.cpp "$dir/solution.cpp"
            printf '%s\n' "$dir"
        done
        exit "$status"
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
