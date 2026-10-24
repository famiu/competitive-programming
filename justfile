#!/usr/bin/env -S just --justfile

# Recipes that take [dir] find the problem directory by walking up from <dir>, or from the
# current directory when <dir> is omitted, to the nearest folder with solution.cpp or meta.json.
# The scripts in scripts/ implement the recipes and document their arguments.

set positional-arguments
set no-exit-message

scripts := justfile_directory() / "scripts"

[private]
default:
    @just --justfile '{{ justfile() }}' --list --unsorted

# ── Problems ──────────────────────────────────────────────────────────────────

# Receive problems from Competitive Companion and print their dirs; --once stops after one problem or contest
[group('problems')]
listen *args:
    @'{{ scripts }}/listen.py' "$@"

# Create problem directories with solution.cpp and print them; paths are relative to the repository root: new [-t seconds] dir...
[group('problems')]
new *args:
    @'{{ scripts }}/scaffold.sh' new "$@"

# Open the problem's page in the browser
[group('problems')]
[no-cd]
open *args:
    @'{{ scripts }}/open.sh' "$@"

# Show the problem's name, limits, URL, test count and checker
[group('problems')]
[no-cd]
info *args:
    @'{{ scripts }}/info.sh' "$@"

# Add tests/custom_NN from stdin or files; an expected output left empty comes from brute.cpp if present. --sample adds the next sample as tests/NN
[group('problems')]
[no-cd]
add-test *args:
    @'{{ scripts }}/add_test.sh' "$@"

# Copy solution.cpp to the clipboard
[group('problems')]
[no-cd]
copy *args:
    @'{{ scripts }}/copy.sh' "$@"

# Commit a newly solved problem as "feat: solve <site>/<problem>"; extra arguments go to git commit
[group('problems')]
[no-cd]
commit *args:
    @'{{ scripts }}/commit.sh' new "$@"

# Commit changes to an already-committed problem, choosing the type in the editor
[group('problems')]
[no-cd]
commit-update *args:
    @'{{ scripts }}/commit.sh' update "$@"

# ── Running ───────────────────────────────────────────────────────────────────

# Debug-build and run solution.cpp on stdin, a file, or a test name: run [dir] [input]
[group('run')]
[no-cd]
run *args:
    @'{{ scripts }}/run.sh' "$@"

# Release-build and check tests/*.in against .out: test [dir] [case...] (names or globs)
[group('run')]
[no-cd]
test *args:
    @'{{ scripts }}/test.sh' release "$@"

# Like test, but with a debug build (sanitizers, LOCAL defined, 3x time limit)
[group('run')]
[no-cd]
test-debug *args:
    @'{{ scripts }}/test.sh' debug "$@"

# Re-run test whenever sources, tests or checkers change (requires entr)
[group('run')]
[no-cd]
watch *args:
    @'{{ scripts }}/watch.sh' "$@"

# Time the release build on one input (default: largest test): bench [dir] [input]
[group('run')]
[no-cd]
bench *args:
    @'{{ scripts }}/bench.sh' "$@"

# ── Stress testing ────────────────────────────────────────────────────────────

# Create brute.cpp and generator.cpp
[group('stress')]
[no-cd]
gen-stress *args:
    @'{{ scripts }}/scaffold.sh' stress "$@"

# Compare solution.cpp with brute.cpp on generated inputs: stress [dir] [iterations]
[group('stress')]
[no-cd]
stress *args:
    @'{{ scripts }}/stress.sh' "$@"

# Save the last failing stress case as tests/stress_NN
[group('stress')]
[no-cd]
stress-save *args:
    @'{{ scripts }}/stress_save.sh' "$@"

# Create checker.cpp for problems with more than one correct answer
[group('stress')]
[no-cd]
gen-checker *args:
    @'{{ scripts }}/scaffold.sh' checker "$@"

# ── Code ──────────────────────────────────────────────────────────────────────

# Format the problem's .cpp files with clang-format
[group('code')]
[no-cd]
fmt *args:
    @'{{ scripts }}/fmt.sh' "$@"

# Lint the problem's .cpp files with clang-tidy (skipped when .no-lint exists)
[group('code')]
[no-cd]
lint *args:
    @'{{ scripts }}/lint.sh' "$@"

# Write compile_commands.json for clangd in problems that have .compile_flags
[group('code')]
gen-flags:
    @'{{ scripts }}/gen_flags.sh'

# ── Maintenance ───────────────────────────────────────────────────────────────

# Check that the tools the recipes use are installed
[group('maintenance')]
doctor:
    @'{{ scripts }}/doctor.sh'

# Remove build outputs and .stress/ artifacts, for one problem or everything: clean [dir]
[group('maintenance')]
[no-cd]
clean *args:
    @'{{ scripts }}/clean.sh' "$@"
