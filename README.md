# Competitive programming

My solutions to competitive programming problems, plus the tooling to fetch, build, test and stress-test them. Problems are fetched using [cpfetch](https://github.com/famiu/cpfetch).

## Setup

```sh
just doctor   # check that the required tools are installed
just setup    # install the Chromium browser cpfetch uses
```

## Usage

```sh
cd "$(just new https://codeforces.com/problemset/problem/4/A)"
just test          # build and check every sample
just test 02       # one test; names and globs work, e.g. 'custom_*'
just run 02        # debug build on tests/02.in, with dbg() output
just add-test      # paste a new input (and expected output) as tests/custom_NN
just copy          # put solution.cpp on the clipboard to submit
```

`just new` fetches each URL into `problems/<site>/<problem>/`, creates `solution.cpp` from `templates/solution.cpp` and prints the problem directories on stdout. It also accepts several URLs at once, or a local directory to scaffold without fetching.

Recipes find the problem by walking up from the current directory to the nearest folder that contains `solution.cpp` or `meta.json`, so they work from anywhere inside a problem, including `tests/`. Passing a directory as the first argument selects a different problem. `just` with no arguments lists every recipe.

## Problem directories

```text
problems/<site>/<problem>/
├── solution.cpp
├── problem.md        statement (cpfetch)
├── meta.json         URL, name and limits (cpfetch)
├── tests/
│   ├── 01.in, 01.out             samples (cpfetch)
│   ├── custom_01.in, .out        from `just add-test`
│   └── stress_01.in, .out        from `just stress-save`
├── brute.cpp, generator.cpp      from `just gen-stress`
├── checker.cpp | checker.py | checker
├── .compare          built-in comparison mode
├── .compile_flags    extra compiler flags, one or more per line
└── .no-lint          skips `just lint`
```

`just refetch-all` and re-fetching a problem replace `problem.md`, `meta.json` and the numbered samples, and leave every other file alone.

## Testing

```sh
just test          # release build, judge-like flags
just test-debug    # sanitizers + dbg(), 3x time limit
just watch         # re-run tests on every change (needs entr)
```

Verdicts are `PASS`, `WA`, `TLE`, `RE`, and `OUT` (no `.out` file, output is just printed). The time limit comes from `meta.json`, or 2s if there isn't one.

Output is compared line by line, ignoring trailing whitespace. Put `tokens` or `float 1e-6` in `.compare` for token-wise or float-tolerant comparison.

For problems with multiple valid answers, `just gen-checker` creates `checker.cpp`. It's called as `checker <input> <output> <answer>` (testlib order) and accepts by exiting 0. `checker.py` or an executable `checker` work too.

## Stress testing

```sh
just gen-stress    # create brute.cpp and generator.cpp
just stress        # run until something fails
just stress 1000   # or for a fixed number of iterations
just stress-save   # keep the failing case as tests/stress_NN
```

The generator gets the iteration number as its seed. Failures go to `.stress/`; `just run .stress/failing.in` reproduces them.

## Other recipes

```sh
just bench         # time the release build on the largest test
just info          # limits, test count, checker
just fmt           # clang-format
just lint          # clang-tidy
just bump-cpfetch  # update the pinned cpfetch commit
```

## Environment variables

- `TIME_LIMIT_FACTOR`: scale all time limits (default `1`)
- `DEFAULT_TIME_LIMIT`: seconds, when `meta.json` has no limit (default `2`)
- `STRESS_JOBS`: parallel stress iterations (default: CPU count)
- `BENCH_RUNS`: runs per bench (default `3`)
- `DIFF_PREVIEW_LINES`: max lines shown for diffs and stderr (default `80`)
