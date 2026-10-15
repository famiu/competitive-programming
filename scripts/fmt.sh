#!/usr/bin/env bash
# Usage: fmt.sh [dir]
#
# Formats the problem's .cpp files with clang-format.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

require_cmd clang-format
parse_problem_args "$@"
shopt -s nullglob
files=("$PROBLEM_DIR"/*.cpp)
((${#files[@]} > 0)) || die "no .cpp files in $PROBLEM_DIR"
clang-format -i "${files[@]}"
for f in "${files[@]}"; do note "formatted: $f"; done
