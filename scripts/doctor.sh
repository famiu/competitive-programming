#!/usr/bin/env bash
# Usage: doctor.sh
#
# Checks that the tools used by the recipes are installed.
set -uo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

missing=0

# check <required|optional> <command> <purpose>
check() {
    local level="$1" cmd="$2" purpose="$3"
    if command -v "$cmd" &> /dev/null || [[ -x "$cmd" ]]; then
        printf '  %sok%s       %-16s %s\n' "$GREEN" "$RESET" "$cmd" "$purpose"
    elif [[ "$level" == required ]]; then
        printf '  %smissing%s  %-16s %s\n' "$RED" "$RESET" "$cmd" "$purpose"
        missing=1
    else
        printf '  %smissing%s  %-16s %s %s(optional)%s\n' "$YELLOW" "$RESET" "$cmd" "$purpose" "$DIM" "$RESET"
    fi
}

printf '%sRequired%s\n' "$BOLD" "$RESET"
check required "$CXX" "compiler (C++23 with <print>: GCC 14 or newer)"
check required jq "reads meta.json"
check required timeout "time limits (coreutils)"
check required python3 "listen, and checker.py checkers"
check required xargs "parallel stress iterations (findutils)"
printf '%sOptional%s\n' "$BOLD" "$RESET"
check optional /usr/bin/time "bench (GNU time)"
check optional entr "watch"
check optional clang-format "fmt"
check optional clang-tidy "lint"
check optional xdg-open "open"
check optional wl-copy "copy (or xclip / pbcopy)"

if command -v "$CXX" &> /dev/null; then
    if ! printf '#include <print>\nint main() { std::println("ok"); }\n' |
        "$CXX" "${BASE_FLAGS[@]}" -x c++ - -o /dev/null 2> /dev/null; then
        printf '  %swarning%s  %s cannot compile C++23 std::println; the debug helpers in the template need it\n' \
            "$YELLOW" "$RESET" "$CXX"
    fi
fi
exit "$missing"
