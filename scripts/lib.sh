# Shared helpers for the scripts in this directory. Source it; do not run it.
#
# Environment variables (all optional):
#   CXX                 compiler (default: g++)
#   TIME_LIMIT_FACTOR   multiplier applied to every time limit (default: 1)
#   DEFAULT_TIME_LIMIT  time limit in seconds when meta.json has none (default: 2)
#   DIFF_PREVIEW_LINES  maximum lines shown for diffs, stderr and checker output (default: 80)
#   NO_COLOR            disables colored output when set

export LC_ALL=C

SCRIPTS_DIR="$(realpath "${BASH_SOURCE[0]}")"
SCRIPTS_DIR="${SCRIPTS_DIR%/*}"
REPO_ROOT="${SCRIPTS_DIR%/*}"
BIN_DIR="$REPO_ROOT/.bin"
TEMPLATES_DIR="$REPO_ROOT/templates"
PROBLEMS_DIR="$REPO_ROOT/problems"

CXX="${CXX:-g++}"
TIME_LIMIT_FACTOR="${TIME_LIMIT_FACTOR:-1}"
DEFAULT_TIME_LIMIT="${DEFAULT_TIME_LIMIT:-2}"
DIFF_PREVIEW_LINES="${DIFF_PREVIEW_LINES:-80}"

# ── Output ────────────────────────────────────────────────────────────────────

if [[ -n "${NO_COLOR:-}" ]] || { [[ ! -t 1 ]] && [[ ! -t 2 ]]; }; then
    BOLD='' DIM='' RESET='' RED='' GREEN='' YELLOW='' CYAN=''
else
    BOLD=$'\e[1m' DIM=$'\e[2m' RESET=$'\e[0m'
    RED=$'\e[31m' GREEN=$'\e[32m' YELLOW=$'\e[33m' CYAN=$'\e[36m'
fi

# Messages go to stderr so that stdout stays usable by callers (e.g. `new` prints paths).
error() { printf '%serror:%s %s\n' "$BOLD$RED" "$RESET" "$*" >&2; }
warn() { printf '%swarning:%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
note() { printf '%s%s%s\n' "$DIM" "$*" "$RESET" >&2; }
die() {
    error "$@"
    exit 1
}
section() { printf '%s%s%s\n' "$CYAN" "$*" "$RESET" >&2; }

# print_capped <file> <noun> [colorize-diff]
# Prints at most DIFF_PREVIEW_LINES lines of <file> to stderr.
print_capped() {
    local file="$1" noun="$2" colorize="${3:-}"
    awk -v max="$DIFF_PREVIEW_LINES" -v noun="$noun" -v colorize="$colorize" \
        -v red="$RED" -v green="$GREEN" -v cyan="$CYAN" -v reset="$RESET" '
        NR <= max {
            line = $0
            if (colorize) {
                if (line ~ /^@@/) line = cyan line reset
                else if (line ~ /^-/) line = red line reset
                else if (line ~ /^\+/) line = green line reset
            }
            print line > "/dev/stderr"
        }
        END {
            if (NR > max)
                printf "... %s truncated (%d lines total, showing the first %d)\n", noun, NR, max > "/dev/stderr"
        }
    ' "$file"
}

# print_block <file>: prints a small file with a gutter, or its size if it is large.
print_block() {
    local file="$1" bytes
    bytes="$(wc -c < "$file")"
    if ((bytes > 4096)); then
        note "($bytes bytes; see $file)"
        return
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
        printf '%s│%s %s\n' "$DIM" "$RESET" "$line" >&2
    done < "$file"
}

# ── Environment checks ────────────────────────────────────────────────────────

# require_cmd <command> [reason]
require_cmd() {
    command -v "$1" &> /dev/null || die "$1 is not installed${2:+ ($2)}; run \`just doctor\` for details"
}

# ── Problem directories ───────────────────────────────────────────────────────

# find_problem_dir <start>
# Prints the nearest directory at or above <start> that contains solution.cpp or meta.json.
find_problem_dir() {
    local dir
    dir="$(realpath -m "$1")"
    case "$dir" in
        "$REPO_ROOT" | "$REPO_ROOT"/*) ;;
        *) die "path must be inside the repository: $dir" ;;
    esac
    while [[ "$dir" != "$REPO_ROOT" ]]; do
        if [[ -f "$dir/solution.cpp" || -f "$dir/meta.json" ]]; then
            printf '%s\n' "$dir"
            return
        fi
        dir="$(dirname "$dir")"
    done
    die "no problem directory (one with solution.cpp or meta.json) at or above $(realpath -m "$1")"
}

# parse_problem_args [dir] [args...]
# Sets PROBLEM_DIR and PROBLEM_ARGS. The first argument selects the problem when it is a
# directory; otherwise the problem is found from the current directory.
parse_problem_args() {
    local start="$PWD"
    if (($# > 0)) && [[ -d "$1" ]]; then
        start="$1"
        shift
    fi
    PROBLEM_DIR="$(find_problem_dir "$start")"
    PROBLEM_ARGS=("$@")
}

# bin_path <mode> <problem-dir> <name>
bin_path() {
    printf '%s/%s/%s/%s\n' "$BIN_DIR" "$1" "$(realpath --relative-to="$REPO_ROOT" "$2")" "$3"
}

# meta_get <problem-dir> <key>: prints the value, or nothing when missing.
meta_get() {
    local meta="$1/meta.json"
    [[ -f "$meta" ]] || return 0
    require_cmd jq "needed to read meta.json"
    jq -r --arg k "$2" '.[$k] // empty' "$meta"
}

# time_limit <problem-dir> <mode>: prints the time limit in seconds for a build mode.
# Debug builds get three times the limit because of -O0 and sanitizers.
time_limit() {
    local tl_ms mode_factor=1
    tl_ms="$(meta_get "$1" time_limit)"
    [[ "$2" == debug ]] && mode_factor=3
    awk -v ms="$tl_ms" -v def="$DEFAULT_TIME_LIMIT" -v f="$TIME_LIMIT_FACTOR" -v m="$mode_factor" '
        BEGIN {
            if (f !~ /^[0-9]*\.?[0-9]+$/) { print "TIME_LIMIT_FACTOR must be a number" > "/dev/stderr"; exit 1 }
            s = (ms + 0 > 0) ? ms / 1000 : def
            v = sprintf("%.3f", s * f * m); sub(/\.?0+$/, "", v); print v
        }'
}

# kill_after <limit>: how long a run may take before it is killed.
kill_after() {
    awk -v tl="$1" 'BEGIN { k = tl * 2; if (k < tl + 1) k = tl + 1; v = sprintf("%.3f", k); sub(/\.?0+$/, "", v); print v }'
}

# ── Running programs ──────────────────────────────────────────────────────────

# run_timed <kill-after> <input> <output> <stderr> <command...>
# Sets RUN_STATUS (124 when killed for taking too long) and RUN_ELAPSED (seconds).
run_timed() {
    local kill="$1" input="$2" output="$3" err="$4"
    shift 4
    local start="$EPOCHREALTIME"
    RUN_STATUS=0
    # The subshell keeps bash's "Segmentation fault" job message out of the terminal.
    (timeout -k 1 "$kill" "$@" < "$input" > "$output" 2> "$err"; exit $?) 2> /dev/null || RUN_STATUS=$?
    ((RUN_STATUS == 137)) && RUN_STATUS=124
    if ((RUN_STATUS > 128)) && [[ -s "$err" ]]; then
        sed -i '/^timeout: the monitored command dumped core$/d' "$err"
    fi
    local end="$EPOCHREALTIME"
    local us=$((10#${end/./} - 10#${start/./}))
    printf -v RUN_ELAPSED '%d.%03d' $((us / 1000000)) $((us % 1000000 / 1000))
}

# describe_status <status>: "exit code 3" or "signal SEGV".
describe_status() {
    if (($1 > 128)); then
        printf 'signal %s' "$(kill -l "$(($1 - 128))" 2> /dev/null || echo "$(($1 - 128))")"
    else
        printf 'exit code %d' "$1"
    fi
}

# ── Building ──────────────────────────────────────────────────────────────────

# compile_flags.txt has one argument per line. Paths after -I and -isystem are relative to the
# repository root, as clangd reads them; builds run elsewhere, so they are made absolute.
BASE_FLAGS=()
prev=''
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$prev" == -I || "$prev" == -isystem ]] && [[ "$line" != /* ]]; then
        line="$REPO_ROOT/$line"
    fi
    BASE_FLAGS+=("$line")
    prev="$line"
done < "$REPO_ROOT/compile_flags.txt"
unset prev
DEBUG_FLAGS=("${BASE_FLAGS[@]}" -O0 -g3 -fno-omit-frame-pointer
    -fsanitize=address,undefined -fno-sanitize-recover=undefined
    -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC -DLOCAL)
# Release builds use judge-like flags: asserts stay enabled and LOCAL is not defined.
RELEASE_FLAGS=("${BASE_FLAGS[@]}" -O2 -pipe)

# extra_flags <problem-dir>: sets EXTRA_FLAGS from the problem's .compile_flags file.
extra_flags() {
    EXTRA_FLAGS=()
    local file="$1/.compile_flags" line
    [[ -f "$file" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*# ]] && continue
        read -ra words <<< "$line"
        EXTRA_FLAGS+=("${words[@]}")
    done < "$file"
}

compiler_id() {
    if [[ -z "${COMPILER_ID:-}" ]]; then
        COMPILER_ID="$("$CXX" --version | head -n 1)"
    fi
    printf '%s\n' "$COMPILER_ID"
}

# ensure_pch <mode>: builds a precompiled bits/stdc++.h for <mode> and prints the directory
# to pass with -I. Prints nothing for compilers other than GCC.
ensure_pch() {
    local mode="$1" dir="$BIN_DIR/pch/$1"
    "$CXX" -dM -E -x c++ /dev/null 2> /dev/null | grep -q '__clang__' && return 0

    local -a flags
    if [[ "$mode" == debug ]]; then flags=("${DEBUG_FLAGS[@]}"); else flags=("${RELEASE_FLAGS[@]}"); fi
    local want
    want="$(compiler_id)"$'\n'"${flags[*]}"
    if [[ -f "$dir/stamp" && -f "$dir/bits/stdc++.h.gch" && -f "$dir/bits/stdc++.h" && "$(< "$dir/stamp")" == "$want" ]]; then
        printf '%s\n' "$dir"
        return 0
    fi

    local header
    header="$(echo '#include <bits/stdc++.h>' | "$CXX" "${flags[@]}" -x c++ -E -H - 2>&1 > /dev/null | head -n 1)"
    header="${header#. }"
    [[ -f "$header" ]] || return 0

    note "precompiling bits/stdc++.h ($mode); this happens once per compiler and flag change"
    mkdir -p "$BIN_DIR/pch"
    local tmp
    tmp="$(mktemp -d "$BIN_DIR/pch/.tmp.XXXXXX")"
    mkdir -p "$tmp/bits"
    if ! "$CXX" "${flags[@]}" -x c++-header "$header" -o "$tmp/bits/stdc++.h.gch"; then
        rm -rf "$tmp"
        warn "could not precompile bits/stdc++.h; compiling without it"
        return 0
    fi
    # GCC can only use the .gch for the first #include <bits/stdc++.h>. Later includes, such as
    # the one in include/debug.hpp, find this file instead and continue to the real header.
    printf '#include_next <bits/stdc++.h>\n' > "$tmp/bits/stdc++.h"
    printf '%s' "$want" > "$tmp/stamp"
    rm -rf "$dir"
    mv "$tmp" "$dir"
    printf '%s\n' "$dir"
}

# build <mode> <source> <output> <problem-dir>
# Compiles <source> unless <output> is newer than it and was built with the same command.
build() {
    local mode="$1" src="$2" out="$3" dir="$4"
    [[ -f "$src" ]] || die "expected $src"

    local -a flags
    case "$mode" in
        debug) flags=("${DEBUG_FLAGS[@]}") ;;
        release) flags=("${RELEASE_FLAGS[@]}") ;;
        *) die "invalid build mode: $mode" ;;
    esac
    extra_flags "$dir"
    flags+=("${EXTRA_FLAGS[@]}")

    local pch_dir
    pch_dir="$(ensure_pch "$mode")"
    local -a cmd=("$CXX" "${flags[@]}")
    [[ -n "$pch_dir" ]] && cmd+=(-I "$pch_dir")
    cmd+=("$src" -o "$out")

    local stamp="$out.cmd" want
    want="$(compiler_id)"$'\n'"${cmd[*]}"
    if [[ -x "$out" && "$out" -nt "$src" && -f "$stamp" && "$(< "$stamp")" == "$want" ]] &&
        [[ -z "$pch_dir" || "$out" -nt "$pch_dir/bits/stdc++.h.gch" ]]; then
        return 0
    fi

    mkdir -p "$(dirname "$out")"
    rm -f "$stamp"
    note "compiling $(basename "$src") ($mode)"
    "${cmd[@]}" || die "compilation failed: $(basename "$src")"
    printf '%s' "$want" > "$stamp"
}
