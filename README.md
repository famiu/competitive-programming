# Competitive programming

My solutions to competitive programming problems, plus the tooling to fetch, build, test and stress-test them. Problems are fetched using the [Competitive Companion](https://github.com/jmerle/competitive-companion) browser extension.

> [!NOTE]
> The tooling in this repository includes AI-generated code. I didn't want to spend time perfecting tooling rather than solving problems, which is the fun part for me. All problem solutions are still entirely written by me.

## Setup

```sh
just doctor   # check that the required tools are installed
```

Install Competitive Companion in the browser. `just listen` uses its default port, 1327 (`CP_LISTEN_PORT` to change it).

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

Problems go to `problems/<site>/<id>_<name>/`. Clicking on a contest page sends the whole contest, and without `--once`, `just listen` keeps listening. Receiving a problem again only replaces `meta.json` and the numbered samples.

For problems with a single test, comment out `cin >> t;` in the solution.

Recipes work from anywhere inside a problem, or take a problem directory as their first argument. `just` lists every recipe.

## Problems set up by hand

```sh
cd "$(just new -t 1 scratch/foo)"  # solution.cpp, and meta.json with a 1s time limit
just add-test --sample             # paste a sample's input and output as the next tests/NN
just limit 3 512                   # set the time limit to 3s and the memory limit to 512 MB
```

`just new` paths are relative to the repository root. `scratch/` is gitignored.

## Contests

```sh
just listen --contest           # then click Competitive Companion on the contest page
just listen --contest r1000     # the same, with a shorter folder name
just contest bapsoj a-k -t 1    # by hand, for sites Competitive Companion doesn't support
```

Contest problems go to `scratch/<contest>/<letter>/`, so switching problems is `cd ../c`. `just contest` takes a count (`5`) or a letter range (`a-k`) and skips problems that already exist.

```sh
just archive                          # move this problem to problems/<site>/<id>_<name>
just archive bapsoj "Perfect Couple"  # when meta.json has no URL to name it from
just archive --commit                 # then commit it, as `just commit` does
```

`cd "$(just archive)"` follows the problem to its new directory.

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

`dbg(a, b)` prints the values with their names in debug builds and compiles to nothing otherwise. Debug builds also print an `input check:` warning when the input is read past its end or not fully read.

Verdicts are `PASS`, `WA`, `TLE`, `RE`, and `OUT` (no `.out` file, output is just printed).

Output is compared line by line, ignoring trailing whitespace. Put `tokens` or `float 1e-6` in `.compare` for token-wise or float-tolerant comparison. For problems with multiple valid answers, `just gen-checker` creates `checker.cpp`, called as `checker <input> <output> <answer>` and accepting by exiting 0.

## Stress testing

```sh
just gen-stress    # create brute.cpp and generator.cpp
just test-brute    # check brute.cpp against the tests
just gen           # preview the inputs for seeds 1-5
just gen 1-20      # or for a range of seeds
just gen 7         # print the input for seed 7
just stress        # run until something fails
just stress 1000   # or for a fixed number of iterations
just stress-save   # keep the failing case as tests/stress_NN
```

`just stress` first checks brute.cpp against the tests and that the generator's output varies with the seed, and treats `input check:` warnings as failures. The generator gets the iteration number as its seed; `include/gen.hpp` has the random helpers. `just run .stress/failing.in` reproduces a failure, and `just gen 7 | just run` runs the solution on one generated input.

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
