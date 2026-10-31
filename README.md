# Competitive programming

My solutions to competitive programming problems, plus the tooling to fetch, build, test and stress-test them. Problems are fetched using the [Competitive Companion](https://github.com/jmerle/competitive-companion) browser extension.

> [!NOTE]
> The tooling in this repository includes AI-generated code. I didn't want to spend time perfecting tooling rather than solving problems, which is the fun part for me. All problem solutions are still entirely written by me.

## Setup

```sh
just doctor   # check that the required tools are installed
```

Install Competitive Companion in the browser. It sends problems to port 1327 by default, which is what `just listen` uses (`CP_LISTEN_PORT` to change it).

## Usage

```sh
cd "$(just listen --once)"   # then click Competitive Companion on the problem page
just test          # build and check every sample
just test 02       # one test; names and globs work, e.g. 'custom_*'
just run 02        # debug build on tests/02.in, with dbg() output
just add-test      # paste a new input (and expected output) as tests/custom_NN
just open          # open the problem page
just ship          # run every test, and put solution.cpp on the clipboard if all pass
just copy          # put solution.cpp on the clipboard without testing
just commit        # commit a newly solved problem as "feat: solve <site>/<problem>"
just commit-update # commit changes to it later, as "<type>: update <site>/<problem>"
```

`just listen` writes each problem it receives to `problems/<site>/<id>_<name>/` (e.g. `codeforces/2200d_portal`) with `meta.json`, the samples and `solution.cpp` from `templates/solution.cpp`, and prints the directory. Clicking on a contest page sends the whole contest. Without `--once` it keeps listening until Ctrl-C. Receiving a problem again only replaces `meta.json` and the numbered samples.

The template reads a test count and calls `solve()` once per test. For problems with a single test, comment out `cin >> t;`.

Recipes find the problem by walking up from the current directory to the nearest folder that contains `solution.cpp` or `meta.json`, so they work from anywhere inside a problem, including `tests/`. Passing a directory as the first argument selects a different problem. `just` with no arguments lists every recipe.

## Problems set up by hand

```sh
cd "$(just new -t 1 scratch/foo)"  # solution.cpp, and meta.json with a 1s time limit
just add-test --sample             # paste a sample's input and output as the next tests/NN
```

`just new` takes paths relative to the repository root and refuses directories that already have `solution.cpp`. Without `-t`, tests use `DEFAULT_TIME_LIMIT`.

`scratch/` is gitignored. Every recipe except `commit` works in. `just archive` moves a problem from `scratch/` to `problems/`; see [Contests](#contests).

`just limit 3` sets the current problem's time limit to 3s, and `just limit 3 512` also sets the memory limit in MB. When a problem has no time limit, `just test` and `just info` say that the default is being used.

## Contests

```sh
just listen --contest           # then click Competitive Companion on the contest page
just listen --contest r1000     # the same, with a shorter folder name
just contest bapsoj a-k -t 1    # by hand, for sites Competitive Companion doesn't support
cd scratch/bapsoj/c && just limit 3
```

Contest problems go to `scratch/<contest>/<letter>/`, so switching problems is `cd ../c`. `meta.json` records the contest in `contest`.

`just listen --contest` names the folder after the contest Competitive Companion sends, e.g. `codeforces_round_1000_div_2`, unless a name is given. The letter comes from the problem's name ("A. ", "B - "); names without one use the slugified name instead.

`just contest <name> <count|range>` creates `scratch/<name>/a`, `b`, … for a count (`5`) or a letter range (`a-k`, or `c` for one problem). Problems that already exist are skipped, so a wider range adds only the missing ones. `-t` takes one time limit for every problem it creates; `just limit` sets a different one for a single problem. Samples are added with `just add-test --sample`.

```sh
just archive                          # move this problem to problems/<site>/<id>_<name>
just archive bapsoj "Perfect Couple"  # when meta.json has no URL to name it from
just archive --commit                 # then commit it, as `just commit` does
```

`just archive` names the problem the same way `just listen` does, from `meta.json`'s URL, site and name. A site and name given on the command line replace the ones in `meta.json`. It keeps `contest` in `meta.json`, removes the contest folder once it is empty, and prints the new directory, so `cd "$(just archive)"` follows the problem. Unsolved problems stay in `scratch/`.

`just ship` stops without copying when a test fails, a test has no expected output, there are no tests, or the problem is interactive; `--force` copies anyway. It also lists leftover `freopen`, `cerr`, `clog` and `#define LOCAL` lines, but still copies.

## Problem directories

```text
problems/<site>/<problem>/
├── solution.cpp
├── meta.json         URL, name, limits, interactive
├── tests/
│   ├── 01.in, 01.out             samples, from `just listen` or `just add-test --sample`
│   ├── custom_01.in, .out        from `just add-test`
│   └── stress_01.in, .out        from `just stress-save`
├── brute.cpp, generator.cpp      from `just gen-stress`
├── checker.cpp | checker.py | checker
├── .compare          built-in comparison mode
├── .compile_flags    extra compiler flags, one or more per line
└── .no-lint          skips `just lint`
```

## Testing

```sh
just test          # release build, judge-like flags
just test-debug    # sanitizers + dbg(), 3x time limit
just watch         # re-run tests on every change (needs entr)
```

`dbg(a, b)` prints the values with their names to stderr in debug builds (`include/debug.hpp`) and compiles to nothing anywhere else.

Verdicts are `PASS`, `WA`, `TLE`, `RE`, and `OUT` (no `.out` file, output is just printed). The time limit comes from `meta.json`, or 2s if there isn't one.

Output is compared line by line, ignoring trailing whitespace. Put `tokens` or `float 1e-6` in `.compare` for token-wise or float-tolerant comparison.

For problems with multiple valid answers, `just gen-checker` creates `checker.cpp`, using the helpers in `include/checker.hpp`. It's called as `checker <input> <output> <answer>` (testlib order) and accepts by exiting 0. `checker.py` or an executable `checker` work too.

## Stress testing

```sh
just gen-stress    # create brute.cpp and generator.cpp
just stress        # run until something fails
just stress 1000   # or for a fixed number of iterations
just stress-save   # keep the failing case as tests/stress_NN
```

The generator gets the iteration number as its seed, and `include/gen.hpp` has the random helpers (`rnd`, `rnd_vec`, `rnd_tree`, `rnd_graph`, `out`, …). Failures go to `.stress/`; `just run .stress/failing.in` reproduces them. `just add-test` fills in an expected output left empty by running `brute.cpp`.

## Other recipes

```sh
just bench         # time the release build on the largest test
just info          # limits, test count, checker
just fmt           # clang-format
just lint          # clang-tidy
```

## Environment variables

- `TIME_LIMIT_FACTOR`: scale all time limits (default `1`)
- `DEFAULT_TIME_LIMIT`: seconds, when `meta.json` has no limit (default `2`)
- `STRESS_JOBS`: parallel stress iterations (default: CPU count)
- `BENCH_RUNS`: runs per bench (default `3`)
- `DIFF_PREVIEW_LINES`: max lines shown for diffs and stderr (default `80`)
