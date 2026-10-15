#!/usr/bin/env bash
# Usage: scaffold.sh new [dir...]
#        scaffold.sh stress [dir]
#        scaffold.sh checker [dir]
#
# `new` creates solution.cpp in each directory (default: the current one) and prints the
# directories on stdout. `stress` adds brute.cpp and generator.cpp; `checker` adds checker.cpp.
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
        for target in "$@"; do
            dir="$(realpath -m "$target")"
            case "$dir" in
                "$REPO_ROOT") die "refusing to scaffold the repository root; pass a problem path" ;;
                "$REPO_ROOT"/*) ;;
                *) die "path must be inside the repository: $dir" ;;
            esac
            mkdir -p "$dir"
            copy_template solution.cpp "$dir/solution.cpp"
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
