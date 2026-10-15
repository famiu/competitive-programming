#!/usr/bin/env bash
# Usage: gen_flags.sh
#
# Writes compile_commands.json for clangd into every problem directory that has a
# .compile_flags file, so that the editor sees the extra flags. Other problems use the
# repository's compile_flags.txt.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

require_cmd jq
while IFS= read -r -d '' cf; do
    dir="$(dirname "$cf")"
    extra_flags "$dir"
    shopt -s nullglob
    files=("$dir"/*.cpp)
    ((${#files[@]} > 0)) || continue
    # Values are passed newline-separated because jq would parse arguments like -std=c++23 as options.
    jq -n --arg dir "$dir" \
        --arg command "$(printf '%s\n' "$CXX" "${BASE_FLAGS[@]}" "${EXTRA_FLAGS[@]}")" \
        --arg files "$(printf '%s\n' "${files[@]##*/}")" '
        ($command | split("\n")) as $command
        | [$files | split("\n")[] | {directory: $dir, file: ., arguments: ($command + ["-c", .])}]
    ' > "$dir/compile_commands.json"
    note "generated: $dir/compile_commands.json"
done < <(find "$PROBLEMS_DIR" -name .compile_flags -print0)
