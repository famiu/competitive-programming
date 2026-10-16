#!/usr/bin/env bash
# Usage: commit.sh new [dir] [git-commit-args...]
#        commit.sh update [dir] [git-commit-args...]
#
# Commits every change in the problem directory, and nothing outside it. `new` is for problems
# with nothing committed yet and uses the message "feat: solve <site>/<problem>" (e.g.
# "feat: solve codeforces/2200d_portal"). `update` is for problems that are already committed
# and opens the editor with a "<type>: update <site>/<problem>" template; git aborts the commit
# if the template is saved unchanged. Other arguments go to `git commit`, so `-e` edits the
# message.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib.sh"

require_cmd git
mode="$1"
shift
parse_problem_args "$@"
dir="$PROBLEM_DIR"
case "$dir" in
    "$PROBLEMS_DIR"/*) ;;
    *) die "not inside problems/: $dir" ;;
esac
rel="$(realpath --relative-to="$PROBLEMS_DIR" "$dir")"

committed=0
[[ -n "$(git -C "$REPO_ROOT" ls-tree -r --name-only HEAD -- "$dir" 2> /dev/null)" ]] && committed=1

case "$mode" in
    new)
        ((!committed)) || die "$rel is already committed; use \`just commit-update\`"
        ;;
    update)
        ((committed)) || die "$rel has not been committed yet; use \`just commit\`"
        ;;
    *) die "invalid mode: $mode" ;;
esac

git -C "$REPO_ROOT" add -A -- "$dir"
git -C "$REPO_ROOT" diff --cached --quiet -- "$dir" && die "nothing to commit in $rel"

if [[ "$mode" == new ]]; then
    git -C "$REPO_ROOT" commit -m "feat: solve $rel" "${PROBLEM_ARGS[@]}" -- "$dir"
    exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
cat > "$tmp/template" << EOF
<type>: update $rel

# Pick a type: fix (wrong answer), perf (too slow), refactor (cleanup),
# test (tests, brute, generator or checker only).
# Optionally say what changed below the first line.
EOF
git -C "$REPO_ROOT" commit -t "$tmp/template" "${PROBLEM_ARGS[@]}" -- "$dir"
