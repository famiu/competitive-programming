#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/check_helper.sh"

target="$(realpath -m "${1:-.}")"
require_in_repo "$target" "$REPO_ROOT"

meta="$target/meta.json"
if [[ ! -f "$meta" ]]; then
    error "no meta.json found in $target"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    error "jq is required to read meta.json"
    exit 1
fi

name=$(jq -r '.name // "?"' "$meta")
site=$(jq -r '.site // "?"' "$meta")
platform=$(jq -r '.platform // "?"' "$meta")
url=$(jq -r '.url // "?"' "$meta")
tl=$(jq -r '.time_limit // 0' "$meta")
ml=$(jq -r '.memory_limit // 0' "$meta")

printf "${BOLD}%s${RESET}\n" "$name"
printf "  ${CYAN}Site${RESET}          %s (%s)\n" "$site" "$platform"
printf "  ${CYAN}URL${RESET}           %s\n" "$url"
if [[ "$tl" != "0" && "$tl" != "null" ]]; then
    printf "  ${CYAN}Time limit${RESET}    %s\n" \
        "$(awk -v tl="$tl" 'BEGIN { printf "%.1f s", tl / 1000 }')"
fi
if [[ "$ml" != "0" && "$ml" != "null" ]]; then
    printf "  ${CYAN}Memory limit${RESET}  %d MB\n" "$ml"
fi

shopt -s nullglob
tests=("$target/tests/"*.in)
if (( ${#tests[@]} > 0 )); then
    printf "  ${CYAN}Test cases${RESET}    %d\n" "${#tests[@]}"
fi
