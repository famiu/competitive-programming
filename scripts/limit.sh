#!/usr/bin/env bash
# Usage: limit.sh [dir] seconds [megabytes]
#
# Sets the problem's time limit, and optionally its memory limit, in meta.json. meta.json is
# created when the problem has none.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

parse_problem_args "$@"
dir="$PROBLEM_DIR"
usage="usage: just limit [dir] seconds [megabytes]"
((${#PROBLEM_ARGS[@]} >= 1 && ${#PROBLEM_ARGS[@]} <= 2)) || die "$usage"
tl="${PROBLEM_ARGS[0]}" ml="${PROBLEM_ARGS[1]:-}"
[[ "$tl" =~ ^[0-9]*\.?[0-9]+$ ]] && awk -v s="$tl" 'BEGIN { exit !(s > 0) }' ||
    die "the time limit must be a positive number of seconds: '$tl'"
[[ -z "$ml" || "$ml" =~ ^[1-9][0-9]*$ ]] || die "the memory limit must be a positive number of megabytes: '$ml'"

require_cmd jq "needed to write meta.json"
meta="$dir/meta.json"
[[ -f "$meta" ]] || jq -n --arg name "${dir##*/}" '{name: $name}' > "$meta"
jq --arg tl "$tl" --arg ml "$ml" '
    .time_limit = ($tl | tonumber * 1000 | round)
    | if $ml != "" then .memory_limit = ($ml | tonumber) else . end' "$meta" > "$meta.tmp"
mv "$meta.tmp" "$meta"
note "time limit ${tl}s${ml:+, memory limit $ml MB}: $(realpath --relative-to="$REPO_ROOT" "$dir")"
