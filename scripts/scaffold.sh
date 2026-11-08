#!/usr/bin/env bash
# Usage: scaffold.sh new [-t seconds] dir...
#        scaffold.sh contest name count|range [-t seconds]
#        scaffold.sh stress [dir]
#        scaffold.sh checker [dir]
#        scaffold.sh interactor [dir]
#
# `new` creates each directory with solution.cpp and prints the directories on stdout. Relative
# paths are resolved from the repository root. Nothing is created when any directory already
# has solution.cpp. -t writes the time limit to meta.json; otherwise tests use
# DEFAULT_TIME_LIMIT.
#
# `contest` creates scratch/<name>/<letter> for each letter in <range> (`a-k`, or `c` for one
# problem) or the first <count> letters, the same way, with the contest in meta.json. Problems
# that already have solution.cpp are skipped, so a wider range adds only the missing ones. -t
# takes a single time limit for every problem created; `just limit` changes one problem's.
#
# `stress` adds brute.cpp and generator.cpp, or only generator.cpp for interactive problems;
# `checker` adds checker.cpp. `interactor` marks the problem interactive in meta.json and adds
# interactor.cpp. Existing files are never overwritten.
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

# check_seconds <value>: dies unless <value> is a single positive number of seconds.
check_seconds() {
    [[ "$1" =~ ^[0-9]*\.?[0-9]+$ ]] && awk -v s="$1" 'BEGIN { exit !(s > 0) }' ||
        die "-t takes one positive number of seconds, not '$1'; set other problems' limits with \`just limit\`"
}

# make_problem <dir> <name> <seconds> [contest]
# Creates <dir> with solution.cpp, and meta.json when a time limit or contest is given.
make_problem() {
    local dir="$1" name="$2" tl="$3" contest="${4:-}"
    mkdir -p "$dir"
    copy_template solution.cpp "$dir/solution.cpp"
    if [[ -n "$tl" || -n "$contest" ]]; then
        require_cmd jq "needed to write meta.json"
        local meta="$dir/meta.json"
        [[ -f "$meta" ]] || jq -n --arg name "$name" '{name: $name}' > "$meta"
        jq --arg tl "$tl" --arg contest "$contest" '
            if $tl != "" then .time_limit = ($tl | tonumber * 1000 | round) else . end
            | if $contest != "" then .contest = $contest else . end' "$meta" > "$meta.tmp"
        mv "$meta.tmp" "$meta"
    fi
    printf '%s\n' "$dir"
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
            check_seconds "$tl"
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
            make_problem "$dir" "${dir##*/}" "$tl"
        done
        ;;
    contest)
        usage="usage: just contest name count|range [-t seconds]"
        tl='' args=()
        while (($# > 0)); do
            if [[ "$1" == -t ]]; then
                (($# >= 2)) || die "$usage"
                tl="$2"
                check_seconds "$tl"
                shift 2
            else
                args+=("$1")
                shift
            fi
        done
        ((${#args[@]} == 2)) || die "$usage"
        name="${args[0]}" spec="${args[1],,}"
        [[ -n "$name" && "$name" != */* && "$name" != . && "$name" != .. ]] ||
            die "the contest name must be a single directory name: '$name'"

        letters=({a..z})
        if [[ "$spec" =~ ^[0-9]+$ ]]; then
            ((spec >= 1 && spec <= 26)) || die "count must be between 1 and 26: $spec"
            first=0 last=$((spec - 1))
        elif [[ "$spec" =~ ^([a-z])(-([a-z]))?$ ]]; then
            from="${BASH_REMATCH[1]}" to="${BASH_REMATCH[3]:-${BASH_REMATCH[1]}}"
            first=$(($(printf '%d' "'$from") - 97)) last=$(($(printf '%d' "'$to") - 97))
            ((first <= last)) || die "range goes backwards: $spec"
        else
            die "expected a count (e.g. 5) or a letter range (e.g. a-k): ${args[1]}"
        fi

        for ((i = first; i <= last; i++)); do
            dir="$SCRATCH_DIR/$name/${letters[i]}"
            if [[ -e "$dir/solution.cpp" ]]; then
                note "exists: $dir"
                continue
            fi
            make_problem "$dir" "$name ${letters[i]^^}" "$tl" "$name"
        done
        ;;
    stress)
        parse_problem_args "$@"
        # brute.cpp starts from the solution template so that both share the same helpers.
        is_interactive "$PROBLEM_DIR" || copy_template solution.cpp "$PROBLEM_DIR/brute.cpp"
        copy_template generator.cpp "$PROBLEM_DIR/generator.cpp"
        ;;
    checker)
        parse_problem_args "$@"
        copy_template checker.cpp "$PROBLEM_DIR/checker.cpp"
        ;;
    interactor)
        parse_problem_args "$@"
        require_cmd jq "needed to write meta.json"
        meta="$PROBLEM_DIR/meta.json"
        [[ -f "$meta" ]] || jq -n --arg name "${PROBLEM_DIR##*/}" '{name: $name}' > "$meta"
        jq '.interactive = true' "$meta" > "$meta.tmp"
        mv "$meta.tmp" "$meta"
        copy_template interactor.cpp "$PROBLEM_DIR/interactor.cpp"
        if [[ -f "$PROBLEM_DIR/brute.cpp" ]]; then note "brute.cpp is not used for interactive problems"; fi
        ;;
    *) die "invalid scaffold kind: $kind" ;;
esac
