#!/usr/bin/env bash
# Usage: open.sh [dir]
#
# Opens the problem's URL from meta.json in the browser.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

parse_problem_args "$@"
url="$(meta_get "$PROBLEM_DIR" url)"
[[ -n "$url" ]] || die "no URL in $PROBLEM_DIR/meta.json"
require_cmd xdg-open "needed to open the browser"
xdg-open "$url" > /dev/null 2>&1 &
note "opened $url"
