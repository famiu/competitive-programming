#!/usr/bin/env bash
# Usage: ship.sh [dir] [--force]
#
# Runs every test on the release build and copies solution.cpp to the clipboard only when all of
# them pass. Tests without an expected output, interactive problems and problems without tests
# cannot pass, so they also stop it. --force copies anyway once the tests have run. Leftover
# freopen, cerr, clog and `#define LOCAL` lines are reported but do not stop it.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

force=0 args=()
for arg in "$@"; do
    if [[ "$arg" == --force ]]; then force=1; else args+=("$arg"); fi
done
parse_problem_args "${args[@]}"
dir="$PROBLEM_DIR"
((${#PROBLEM_ARGS[@]} == 0)) || die "usage: just ship [dir] [--force]"

# refuse <reason>: stops unless --force was given.
refuse() {
    if ((force)); then
        warn "$1; copying anyway (--force)"
    else
        die "$1; not copied (--force copies anyway)"
    fi
}

shopt -s nullglob
inputs=("$dir"/tests/*.in)
if ((${#inputs[@]} == 0)); then
    refuse "no tests to check"
else
    "$SCRIPTS_DIR/test.sh" release solution "$dir" || refuse "tests failed"
    unchecked=0
    for input in "${inputs[@]}"; do
        [[ -f "${input%.in}.out" ]] || ((unchecked += 1))
    done
    ((unchecked == 0)) || refuse "$unchecked test(s) have no expected output"
fi
[[ "$(meta_get "$dir" interactive)" == true ]] && refuse "interactive problems cannot be checked by the tests"

leftovers='\b(freopen|cerr|clog)\b|^[[:space:]]*#[[:space:]]*define[[:space:]]+LOCAL\b'
if grep -qE "$leftovers" "$dir/solution.cpp"; then
    warn "solution.cpp may have leftover debugging code:"
    grep -nE "$leftovers" "$dir/solution.cpp" | sed 's/^/  /' >&2
fi
exec "$SCRIPTS_DIR/copy.sh" "$dir"
