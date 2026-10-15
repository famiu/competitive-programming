#!/usr/bin/env bash
# Usage: lint.sh [dir]
#
# Runs clang-tidy on the problem's .cpp files with the same flags as the build.
# A .no-lint file in the problem directory skips it.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

parse_problem_args "$@"
dir="$PROBLEM_DIR"
if [[ -f "$dir/.no-lint" ]]; then
    note "skipping $dir (found .no-lint)"
    exit 0
fi
require_cmd clang-tidy
shopt -s nullglob
files=("$dir"/*.cpp)
((${#files[@]} > 0)) || die "no .cpp files in $dir"
extra_flags "$dir"
clang-tidy --quiet "${files[@]}" -- "${BASE_FLAGS[@]}" "${EXTRA_FLAGS[@]}"
