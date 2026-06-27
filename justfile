#!/usr/bin/env -S just --justfile

# ── Toolchain ─────────────────────────────────────────────────────────────────
cxx := env("CXX", "g++")
repo_root := justfile_directory()
bin := repo_root / ".bin"
templates := repo_root / "templates"
problems := repo_root / "problems"
cpfetch_cmd := "uvx --from git+https://github.com/famiu/cpfetch cpfetch"

# ── Configuration ─────────────────────────────────────────────────────────────
diff_preview_lines := env("DIFF_PREVIEW_LINES", "80")

# ── Timeouts ──────────────────────────────────────────────────────────────────
test_timeout := env("TEST_TIMEOUT", "2.0s")
stress_timeout := env("STRESS_TIMEOUT", "3.0s")
bench_timeout := env("BENCH_TIMEOUT", "10s")

# ── Additional configuration ──────────────────────────────────────────────
watch_cooldown := env("WATCH_COOLDOWN", "0.1")
stress_parallel := env("STRESS_PARALLEL", "0")
time_limit_factor := env("TIME_LIMIT_FACTOR", "1")

# ── Compile flags ─────────────────────────────────────────────────────────────
[private]
_base := "-std=c++23 -Wall -Wextra -Wshadow -Wconversion -pedantic"
[private]
_debug := _base + " -O0 -g3 -fno-omit-frame-pointer -fsanitize=address,undefined -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC"
[private]
_release := _base + " -O2 -pipe -DNDEBUG"

# ── Public Recipes ────────────────────────────────────────────────────────────

_default: help

# Show available recipes
help:
    @just --list

# Scaffold a problem directory with solution.cpp
[no-cd]
new path=".":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{ path }}"
    if [[ "$target" =~ ^https?:// ]]; then
        dir="$({{ cpfetch_cmd }} fetch "$target" --nest --out-dir "{{ problems }}")"
        just --justfile "{{ justfile() }}" _scaffold "problem" "$dir"
    else
        just --justfile "{{ justfile() }}" _scaffold "problem" "{{ path }}"
    fi

# Scaffold brute.cpp and generator.cpp for stress-testing
[no-cd]
gen-stress path=".": (_scaffold "stress" path)

# Fetch problem statement + tests into an arbitrary directory
[no-cd]
fetch url dir=".":
    {{ cpfetch_cmd }} fetch "{{ url }}" --out-dir "{{ dir }}"

# Re-render problem.md for all existing problems from .meta.json
refetch-all:
    {{ cpfetch_cmd }} refetch --problems-dir "{{ problems }}"

# Show problem metadata (name, platform, limits, URL)
[no-cd]
info path=".":
    "{{ repo_root }}/scripts/info.sh" "{{ path }}"

# Debug-build solution.cpp and run it interactively (stdin passes through; no timeout)
[no-cd]
run path=".": (_run "debug" path)

# Compile and run all tests/*.in against tests/*.out; supports custom checkers
# `case` (2nd positional) — comma-separated glob patterns; quote if contains glob chars (e.g. "0*")
[no-cd]
test path="." case="*": (_test "release" path case)

# Compile in debug mode and run all tests/*.in against tests/*.out; supports custom checkers
[no-cd]
test-debug path="." case="*": (_test "debug" path case)

# Release-build solution.cpp and run it with wall-clock and memory stats
[no-cd]
bench path=".": (_bench path)

# Watch for file changes and re-run tests (requires entr)
[no-cd]
watch path="." case="*":
    #!/usr/bin/env bash
    set -euo pipefail
    target="$(realpath -m "{{ path }}")"
    source "{{ repo_root }}/scripts/colors.sh"
    source "{{ repo_root }}/scripts/check_helper.sh"
    require_in_repo "$target" "{{ repo_root }}"
    if ! command -v entr &>/dev/null; then
        error "entr is not installed"
        exit 1
    fi
    printf "${CYAN}Watching:${RESET} %s/*.cpp\n" "$target"
    while sleep "{{ watch_cooldown }}"; do
        shopt -s nullglob
        cpp_files=("$target"/*.cpp)
        shopt -u nullglob
        (( ${#cpp_files[@]} == 0 )) && continue
        ls "$target"/*.cpp 2>/dev/null | entr -d -c \
            just --justfile '{{ justfile() }}' test '{{ path }}' '{{ case }}' && break
    done

# Format C++ source files with clang-format
[no-cd]
fmt path=".":
    #!/usr/bin/env bash
    set -euo pipefail
    target="$(realpath -m "{{ path }}")"
    source "{{ repo_root }}/scripts/check_helper.sh"
    require_in_repo "$target" "{{ repo_root }}"
    if ! command -v clang-format &>/dev/null; then
        error "clang-format is not installed"
        exit 1
    fi
    shopt -s nullglob
    files=("$target"/*.cpp)
    if (( ${#files[@]} == 0 )); then
        echo "no .cpp files in $target"
        exit 0
    fi
    source "{{ repo_root }}/scripts/colors.sh"
    clang-format -i "${files[@]}"
    for f in "${files[@]}"; do
        success_dim "formatted: $f"
    done

# Lint C++ source files with clang-tidy (skip with .no-lint marker)
[no-cd]
lint path=".":
    #!/usr/bin/env bash
    set -euo pipefail
    target="$(realpath -m "{{ path }}")"
    source "{{ repo_root }}/scripts/check_helper.sh"
    require_in_repo "$target" "{{ repo_root }}"
    if [[ -f "$target/.no-lint" ]]; then
        echo "skipping (found .no-lint)"
        exit 0
    fi
    if ! command -v clang-tidy &>/dev/null; then
        error "clang-tidy is not installed"
        exit 1
    fi
    shopt -s nullglob
    files=("$target"/*.cpp)
    if (( ${#files[@]} == 0 )); then
        echo "no .cpp files in $target"
        exit 0
    fi
    clang-tidy --quiet "${files[@]}" -- {{ _base }}

# Generate root compile_flags.txt and per-problem compile_commands.json for clangd
gen-flags:
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{ repo_root }}/scripts/colors.sh"
    source "{{ repo_root }}/scripts/check_helper.sh"

    # Root compile_flags.txt (one flag per line, from _base)
    IFS=' ' read -ra flags <<< "{{ _base }}"
    printf '%s\n' "${flags[@]}" > "{{ repo_root }}/compile_flags.txt"
    success_dim "generated: compile_flags.txt"

    # Per-problem compile_commands.json (only where .compile_flags exists)
    while IFS= read -r -d '' cf; do
        dir="$(dirname "$cf")"
        shopt -s nullglob
        cpp_files=("$dir"/*.cpp)
        (( ${#cpp_files[@]} == 0 )) && continue
        extra_flags=$(read_compile_flags "$dir")
        entries="[]"
        for src in "${cpp_files[@]}"; do
            src_name="$(basename "$src")"
            entry=$(jq -nc \
                --arg dir "$(realpath "$dir")" \
                --arg cmd "{{ cxx }} {{ _base }}$extra_flags -c $src_name" \
                --arg file "$src_name" \
                '{directory: $dir, command: $cmd, file: $file}')
            entries=$(jq -n --argjson e "$entry" --argjson es "$entries" '$es + [$e]')
        done
        printf '%s\n' "$entries" > "$dir/compile_commands.json"
        success_dim "generated: $dir/compile_commands.json"
    done < <(find "{{ problems }}" -name '.compile_flags' -print0)

# Stress-test solution.cpp against brute.cpp using generator.cpp; saves failures to .stress/
[no-cd]
stress path=".": (_stress path)

# Remove all generated binaries and .stress/ artifacts (optionally per problem)
[no-cd]
clean path="":
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{ repo_root }}/scripts/colors.sh"
    target="{{ path }}"
    if [[ -n "$target" ]]; then
        target="$(realpath -m "$target")"
        source "{{ repo_root }}/scripts/check_helper.sh"
        require_in_repo "$target" "{{ repo_root }}"
        rel_dir="$(resolve_rel_dir "$target" "{{ repo_root }}")"
        rm -rf "{{ bin }}/debug/$rel_dir"
        rm -rf "{{ bin }}/release/$rel_dir"
        success_dim "removed: {{ bin }}/debug/$rel_dir"
        success_dim "removed: {{ bin }}/release/$rel_dir"
        rm -rf "$target/.stress"
        success_dim "removed: $target/.stress"
    else
        rm -rf "{{ bin }}"
        success_dim "removed: {{ bin }}"
        while IFS= read -r -d '' dir; do
            rm -rf "$dir"
            success_dim "removed: $dir"
        done < <(find "{{ repo_root }}" -mindepth 2 -type d -name ".stress" -print0)
    fi

# Install Python tools and Playwright Chromium
install_fetch_deps:
    {{ cpfetch_cmd }} --help
    uvx --from git+https://github.com/famiu/cpfetch cpfetch setup

# ── Private Implementations ───────────────────────────────────────────────────

# Shared scaffold backend for `new` and `gen-stress`.
[no-cd]
[private]
_scaffold kind path:
    #!/usr/bin/env bash
    set -euo pipefail
    source "{{ repo_root }}/scripts/colors.sh"
    kind="{{ kind }}"
    target="$(realpath -m "{{ path }}")"
    repo="{{ repo_root }}"

    case "$target" in
        "$repo"|"$repo"/*) ;;
        *)
            error "path must be inside the repository: $target"
            exit 1
            ;;
    esac

    if [[ "$target" == "$repo" ]]; then
        error "refusing to scaffold the repository root; pass a problem path"
        exit 1
    fi

    # Copy template file from templates/ to destination.
    # Never overwrite user-written solutions/helpers.
    copy_template_if_missing() {
        local name="$1"
        local dest="$target/$name"
        local tmpl="{{ templates }}/$name"

        if [[ ! -f "$tmpl" ]]; then
            error "missing template file: $tmpl"
            exit 1
        fi

        mkdir -p "$(dirname "$dest")"
        if [[ ! -e "$dest" ]]; then
            cp "$tmpl" "$dest"
            success "created: $dest"
        fi
    }

    case "$kind" in
        problem)
            copy_template_if_missing solution.cpp
            ;;
        stress)
            copy_template_if_missing brute.cpp
            copy_template_if_missing generator.cpp
            ;;
        *)
            error "invalid scaffold kind: $kind"
            exit 1
            ;;
    esac

[no-cd]
[private]
_run mode path:
    #!/usr/bin/env bash
    set -euo pipefail
    mode="{{ mode }}"
    target="$(realpath -m "{{ path }}")"
    source "{{ repo_root }}/scripts/check_helper.sh"
    require_in_repo "$target" "{{ repo_root }}"
    rel_dir="$(resolve_rel_dir "$target" "{{ repo_root }}")"
    case "$mode" in
        debug)
            sol_bin="{{ bin }}/debug/$rel_dir/solution"
            compile_flags='{{ _debug }}'
            ;;
        release)
            sol_bin="{{ bin }}/release/$rel_dir/solution"
            compile_flags='{{ _release }}'
            ;;
        *)
            error "invalid run mode: $mode"
            exit 1
            ;;
    esac

    extra_flags=$(read_compile_flags "$target")

    if [[ ! -f "$target/solution.cpp" ]]; then
        error "expected $target/solution.cpp"
        exit 1
    fi

    mkdir -p "$(dirname "$sol_bin")"
    {{ cxx }} $compile_flags $extra_flags "$target/solution.cpp" -o "$sol_bin"
    "$sol_bin"

[no-cd]
[private]
_test mode path case:
    #!/usr/bin/env bash
    set -euo pipefail
    mode="{{ mode }}"
    target="$(realpath -m "{{ path }}")"
    source "{{ repo_root }}/scripts/check_helper.sh"
    require_in_repo "$target" "{{ repo_root }}"
    rel_dir="$(resolve_rel_dir "$target" "{{ repo_root }}")"
    case "$mode" in
        release)
            sol_bin="{{ bin }}/release/$rel_dir/solution"
            compile_flags='{{ _release }}'
            tl_factor="{{ time_limit_factor }}"
            ;;
        debug)
            sol_bin="{{ bin }}/debug/$rel_dir/solution"
            compile_flags='{{ _debug }}'
            tl_factor="$(( {{ time_limit_factor }} * 3 ))"
            ;;
        *)
            error "invalid test mode: $mode"
            exit 1
            ;;
    esac
    problem_timeout=$(read_problem_timeout "$target" "{{ test_timeout }}" "$tl_factor")

    extra_flags=$(read_compile_flags "$target")

    checker_bin="{{ bin }}/release/$rel_dir/checker"

    if [[ ! -f "$target/solution.cpp" ]]; then
        error "expected $target/solution.cpp"
        exit 1
    fi

    mkdir -p "$(dirname "$sol_bin")"
    {{ cxx }} $compile_flags $extra_flags "$target/solution.cpp" -o "$sol_bin"

    DIFF_PREVIEW_LINES="{{ diff_preview_lines }}"
    resolve_checker "$target" "$checker_bin" "{{ cxx }}" "{{ _release }}"

    inputs=()
    IFS=',' read -ra case_items <<< "{{ case }}"
    for item in "${case_items[@]}"; do
        item="${item#"${item%%[![:space:]]*}"}"
        item="${item%"${item##*[![:space:]]}"}"
        [[ -z "$item" ]] && continue
        while IFS= read -r -d '' f; do
            inputs+=("$f")
        done < <(LC_ALL=C find "$target/tests" -maxdepth 1 -type f \
            -name "$item.in" -print0 2>/dev/null | LC_ALL=C sort -z)
    done

    if (( ${#inputs[@]} == 0 )); then
        error "no test cases found in $target/tests/"
        exit 1
    fi

    actual_f="$(mktemp)"
    diff_preview_f="$(mktemp)"
    diagnostics_f="$(mktemp)"
    trap 'rm -f -- "$actual_f" "$diff_preview_f" "$diagnostics_f"' EXIT

    passed=0
    failed=0
    total="${#inputs[@]}"
    idx=0

    for input_f in "${inputs[@]}"; do
        (( idx += 1 ))
        printf -v counter "[%d/%d]" "$idx" "$total"
        expected_f="${input_f%.in}.out"
        name="$(basename "${input_f%.in}")"

        if [[ ! -f "$expected_f" ]]; then
            error "missing expected output: $expected_f"
            exit 1
        fi

        if timeout "$problem_timeout" "$sol_bin" < "$input_f" > "$actual_f"; then
            if verify_check "$input_f" "$expected_f" "$actual_f" "$diagnostics_f" "$diff_preview_f"; then
                status_pass_p "$counter" "$name"
                (( passed += 1 ))
            else
                status_fail_p "$counter" "$name"
                echo "" >&2
                if [[ "$CHECKER_TYPE" == "diff" ]]; then
                    section "--- diff preview ($name, first {{ diff_preview_lines }} lines) ---"
                    print_capped_file "$diff_preview_f" "diff"
                else
                    error "checker rejected output for case: $name"
                    if [[ -s "$diagnostics_f" ]]; then
                        section "--- checker diagnostics ($name, first {{ diff_preview_lines }} lines) ---"
                        print_capped_file "$diagnostics_f" "diagnostics"
                    fi
                fi
                echo "" >&2
                (( failed += 1 ))
            fi
        else
            status=$?
            if (( status == 124 )); then
                status_tle_p "$counter" "$name"
            else
                status_re_p "$counter" "$name"
            fi
            (( failed += 1 ))
        fi
    done

    separator
    if (( failed == 0 )); then
        printf "${GREEN}All %d tests passed${RESET}\n" "$passed"
    else
        printf "${GREEN}%d passed${RESET}, ${RED}%d failed${RESET}\n" "$passed" "$failed"
    fi
    true

# Release timing backend. Uses the first sample input when available, otherwise stdin.
[no-cd]
[private]
_bench path:
    #!/usr/bin/env bash
    set -euo pipefail
    target="$(realpath -m "{{ path }}")"
    source "{{ repo_root }}/scripts/check_helper.sh"
    require_in_repo "$target" "{{ repo_root }}"
    rel_dir="$(resolve_rel_dir "$target" "{{ repo_root }}")"
    sol_bin="{{ bin }}/release/$rel_dir/solution"

    extra_flags=$(read_compile_flags "$target")

    if [[ ! -f "$target/solution.cpp" ]]; then
        error "expected $target/solution.cpp"
        exit 1
    fi

    mkdir -p "$(dirname "$sol_bin")"
    {{ cxx }} {{ _release }} $extra_flags "$target/solution.cpp" -o "$sol_bin"

    timing_raw="$(mktemp)"
    trap 'rm -f -- "$timing_raw"' EXIT

    shopt -s nullglob
    inputs=("$target/tests/"*.in)
    if (( ${#inputs[@]} > 0 )) && [[ -f "${inputs[0]}" ]]; then
        printf "${CYAN}Timing against:${RESET} %s\n" "${inputs[0]}" >&2
        timeout "{{ bench_timeout }}" /usr/bin/time -v "$sol_bin" < "${inputs[0]}" >/dev/null 2>"$timing_raw"
        time_status=$?
    else
        timeout "{{ bench_timeout }}" /usr/bin/time -v "$sol_bin" >/dev/null 2>"$timing_raw"
        time_status=$?
    fi

    elapsed=$(awk '/Elapsed \(wall clock\) time/ { for (i=NF; i>=1; i--) if ($i ~ /^[0-9]/) { print $i; break } }' "$timing_raw")
    mem_kb=$(awk '/Maximum resident set size/ { print $NF }' "$timing_raw")

    if [[ -n "$mem_kb" ]] && (( mem_kb >= 1024 )); then
        mem_mb="$(awk "BEGIN { printf \"%.1f\", $mem_kb / 1024 }") MB"
    else
        mem_mb="${mem_kb:-?} KB"
    fi

    echo "" >&2
    printf "  ${CYAN}Wall time${RESET}     ${BOLD}%s${RESET}\n" "${elapsed:-?}" >&2
    printf "  ${CYAN}Peak memory${RESET}   %s\n" "$mem_mb" >&2
    if (( time_status == 0 )); then
        printf "  ${CYAN}Exit code${RESET}     ${GREEN}%d${RESET}\n" "$time_status" >&2
    elif (( time_status == 124 )); then
        printf "  ${CYAN}Exit code${RESET}     ${YELLOW}%d (timeout)${RESET}\n" "$time_status" >&2
    else
        printf "  ${CYAN}Exit code${RESET}     ${RED}%d${RESET}\n" "$time_status" >&2
    fi

    if [[ -f "$target/meta.json" ]] && command -v jq &>/dev/null; then
        tl_ms=$(jq -r '.time_limit // empty' "$target/meta.json" 2>/dev/null)
        ml_mb=$(jq -r '.memory_limit // empty' "$target/meta.json" 2>/dev/null)
        if [[ -n "$tl_ms" && "$tl_ms" != "null" && "$tl_ms" != "0" ]]; then
            printf "  ${CYAN}Limit (time)${RESET}  %s\n" \
                "$(awk -v tl="$tl_ms" 'BEGIN { printf "%.1fs", tl / 1000 }')" >&2
            if [[ -n "$elapsed" && "$elapsed" != "?" ]]; then
                pct=$(awk -v e="$elapsed" -v tl="$tl_ms" \
                    'BEGIN { printf "%.0f", e / (tl/1000) * 100 }')
                if awk -v e="$elapsed" -v tl="$tl_ms" \
                    'BEGIN { exit !(e <= tl/1000) }'; then
                    printf "  ${CYAN}Verdict${RESET}       ${GREEN}OK (%s%% of limit)${RESET}\n" "$pct" >&2
                else
                    printf "  ${CYAN}Verdict${RESET}       ${RED}TOO SLOW (%s%% of limit)${RESET}\n" "$pct" >&2
                fi
            fi
        fi
        if [[ -n "$ml_mb" && "$ml_mb" != "null" && "$ml_mb" != "0" ]]; then
            printf "  ${CYAN}Limit (mem)${RESET}   %s MB\n" "$ml_mb" >&2
        fi
    fi

# Stress backend. Debug-build solution/brute (ASan/UBSan), release-build generator (speed).
[no-cd]
[private]
_stress path:
    #!/usr/bin/env bash
    set -euo pipefail
    target="$(realpath -m "{{ path }}")"
    source "{{ repo_root }}/scripts/check_helper.sh"
    source "{{ repo_root }}/scripts/stress_helper.sh"
    require_in_repo "$target" "{{ repo_root }}"
    rel_dir="$(resolve_rel_dir "$target" "{{ repo_root }}")"

    for f in "$target/solution.cpp" "$target/brute.cpp" "$target/generator.cpp"; do
        if [[ ! -f "$f" ]]; then
            error "required file not found: $f"
            exit 1
        fi
    done

    sol_bin="{{ bin }}/debug/$rel_dir/solution"
    brute_bin="{{ bin }}/debug/$rel_dir/brute"
    gen_bin="{{ bin }}/release/$rel_dir/generator"
    checker_bin="{{ bin }}/release/$rel_dir/checker"

    extra_flags=$(read_compile_flags "$target")

    mkdir -p "{{ bin }}/debug/$rel_dir" "{{ bin }}/release/$rel_dir"
    {{ cxx }} {{ _debug }}   $extra_flags "$target/solution.cpp"  -o "$sol_bin"
    {{ cxx }} {{ _debug }}   $extra_flags "$target/brute.cpp"      -o "$brute_bin"
    {{ cxx }} {{ _release }} $extra_flags "$target/generator.cpp"  -o "$gen_bin"

    DIFF_PREVIEW_LINES="{{ diff_preview_lines }}"
    resolve_checker "$target" "$checker_bin" "{{ cxx }}" "{{ _release }}"

    stress_timeout_val=$(read_problem_timeout "$target" "{{ stress_timeout }}" \
        "$(( {{ time_limit_factor }} * 3 ))")

    stress_dir="$target/.stress"
    parallel="{{ stress_parallel }}"
    if [[ "$parallel" == "0" ]]; then
        parallel=$(nproc)
    fi

    if (( parallel <= 1 )); then
        run_stress "$target" "$sol_bin" "$brute_bin" "$gen_bin" "$checker_bin" \
                   "$stress_timeout_val" "{{ diff_preview_lines }}"
    else
        if ! command -v parallel &>/dev/null; then
            error "GNU parallel is not installed"
            exit 1
        fi
        mkdir -p "$stress_dir"
        rm -rf "$stress_dir/fail"
        batch_offset=1
        batch_size=$(( parallel * 100 ))
        while true; do
            if ! seq "$batch_offset" $(( batch_offset + batch_size - 1 )) | \
                parallel -j "$parallel" --halt now,fail=1 --line-buffer \
                '{{ repo_root }}/scripts/stress_iter.sh' \
                "$sol_bin" "$brute_bin" "$gen_bin" "$checker_bin" \
                "$CHECKER_TYPE" "$CHECKER_TARGET" \
                "$stress_timeout_val" "{{ diff_preview_lines }}" \
                {} "$stress_dir"; then
                fail_dir="$stress_dir/fail"
                fail_type=$(cat "$fail_dir/failing.type" 2>/dev/null || echo "unknown")
                fail_seed=$(cat "$fail_dir/failing.seed" 2>/dev/null || echo "$batch_offset")
                fail_iter=$(cat "$fail_dir/failing.iteration" 2>/dev/null || echo "$batch_offset")

                case "$fail_type" in
                    generator-tle)
                        printf "${RED}FAIL${RESET} (${YELLOW}generator TLE${RESET}) on iteration ${BOLD}%d${RESET}\n" "$fail_iter" >&2
                        ;;
                    generator-re)
                        printf "${RED}FAIL${RESET} (${RED}generator RE${RESET}) on iteration ${BOLD}%d${RESET}\n" "$fail_iter" >&2
                        ;;
                    solution-tle)
                        printf "${RED}FAIL${RESET} (${YELLOW}solution TLE${RESET}) on iteration ${BOLD}%d${RESET}\n" "$fail_iter" >&2
                        ;;
                    solution-re)
                        printf "${RED}FAIL${RESET} (${RED}solution RE${RESET}) on iteration ${BOLD}%d${RESET}\n" "$fail_iter" >&2
                        ;;
                    brute-tle)
                        printf "${RED}FAIL${RESET} (${YELLOW}brute TLE${RESET}) on iteration ${BOLD}%d${RESET}\n" "$fail_iter" >&2
                        ;;
                    brute-re)
                        printf "${RED}FAIL${RESET} (${RED}brute RE${RESET}) on iteration ${BOLD}%d${RESET}\n" "$fail_iter" >&2
                        ;;
                    mismatch)
                        printf "${BOLD}${RED}MISMATCH${RESET} on iteration ${BOLD}%d${RESET}\n" "$fail_iter" >&2
                        input_bytes=$(wc -c < "$fail_dir/failing.in" 2>/dev/null || echo 0)
                        if (( input_bytes <= 4096 )); then
                            section "--- input ---"
                            while IFS= read -r line; do
                                printf "${DIM}│${RESET} %s\n" "$line" >&2
                            done < "$fail_dir/failing.in"
                        else
                            dim "Input is $input_bytes bytes; see $fail_dir/failing.in" >&2
                        fi
                        if [[ "$CHECKER_TYPE" == "diff" ]]; then
                            section "--- normalized diff preview (expected vs actual, first {{ diff_preview_lines }} lines) ---"
                            if [[ -f "$fail_dir/failing.diff_preview" ]]; then
                                print_capped_file "$fail_dir/failing.diff_preview" "diff"
                            fi
                        else
                            error "checker rejected output on iteration $fail_iter"
                            if [[ -s "$fail_dir/failing.diagnostics" ]]; then
                                section "--- checker diagnostics (first {{ diff_preview_lines }} lines) ---"
                                print_capped_file "$fail_dir/failing.diagnostics" "diagnostics"
                            fi
                        fi
                        ;;
                    *)
                        error "Stress test failed (unknown type); artifacts in $stress_dir/"
                        ;;
                esac

                dim "Artifacts saved to: $stress_dir/" >&2
                printf "${BOLD}Repro hint:${RESET} " >&2
                printf '%q ' "$gen_bin" "$fail_seed" >&2
                printf '> %q/failing.in\n' "$stress_dir" >&2
                exit 1
            fi
            batch_offset=$(( batch_offset + batch_size ))
            printf "${GREEN}passed %d iteration(s)${RESET}\n" $(( batch_offset - 1 ))
        done
    fi
