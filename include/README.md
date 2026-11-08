# Helpers

Reference for the headers that generators, checkers and interactors include. `debug.hpp` (`dbg`) is covered in the main README.

## Generators: `gen.hpp`

`generator.cpp` runs as `generator <seed>` and prints one test input on stdout. `just stress` passes the iteration number as the seed, so every input can be reproduced with `just gen <seed>`.

| Helper | Description |
|---|---|
| `seed(argc, argv)` | seeds `rng` from `argv[1]` (1 when absent); call it first |
| `rnd(lo, hi)` | uniform value in `[lo, hi]`; for floating-point types, in `[lo, hi)` |
| `rnd_vec(n, lo, hi)` | `vector` of `n` values from `rnd(lo, hi)` |
| `rnd_distinct(n, lo, hi)` | `vector` of `n` distinct integers in `[lo, hi]`, in random order; needs `hi - lo + 1 >= n` |
| `rnd_perm(n, first = 1)` | `vector<int>` holding `first, …, first + n - 1` in random order |
| `pick(c)` | uniformly chosen element of the non-empty container `c` |
| `rnd_str(n, alphabet = "abc…z")` | `string` of `n` characters drawn from `alphabet`; small alphabets such as `"ab"` find bugs faster |
| `rnd_tree(n)` | `vector<pair<int, int>>` of the `n - 1` edges of a random tree on vertices `1..n` |
| `rnd_graph(n, m, connected = false)` | `vector<pair<int, int>>` of `m` edges on vertices `1..n`, with no self-loops or repeated edges; `connected` needs `m >= n - 1` |
| `out(args...)` | prints the arguments on one line, separated by spaces; a container prints its elements, so `out(n, v)` prints `n` and then every element of `v` |
| `out_edges(edges)` | prints one `u v` line per edge of a `rnd_tree` or `rnd_graph` result |
| `rng` | the `std::mt19937_64` behind all of these, for `std::shuffle` and the like |

`rnd` returns the common type of `lo` and `hi`: `rnd(1, n)` with a `long long n` is a `long long`, and `rnd(1, 1e9)` is a `double`, so write `(int)1e9` or `(long long)1e18`. `rnd_vec` and `rnd_distinct` return a `vector` of that same type.

```cpp
seed(argc, argv);
int n = rnd(1, 8);
out(n);
out(rnd_vec(n, 1, 10));  // e.g. "3 7 1 9 ..."
```

## Checkers: `checker.hpp`

`checker.cpp` is used instead of the built-in comparison when it exists. It runs as `checker <input> <output> <answer>`: the test input, the solution's output and the expected output. In `just test` the expected output is the test's `.out` file, and tests without one are not checked; in `just stress` it is `brute.cpp`'s output. It exits 0 to accept, 1 for a wrong answer and 2 for a checker error. Its messages go to stderr and are shown when it rejects.

The files are read through streams, with `>>` as with `cin`; in the table, `s` is any of them.

| Helper | Description |
|---|---|
| `init(argc, argv)` | opens the files as the streams `in` (the test input), `out` (the solution's output) and `ans` (the expected output); call it first |
| `s >> x` | reads the next token into `x`: an integer, a floating-point number, a `string`, or a `char` (one character) |
| `s >> p` | reads each part of the pair or tuple `p` |
| `s.yes()` | reads YES or NO in any case, as most judges accept; true for YES |
| `s >> v` | reads every element of the vector `v`, which must already have its size; elements can be pairs, e.g. `vector<pair<int, int>> edges(m)` |
| `wrong(fmt, args...)` | rejects with a wrong answer (exit 1); does not return |
| `fail(fmt, args...)` | stops with a checker error (exit 2), for problems in the checker itself or its files; does not return |
| `close_enough(expected, actual, eps = 1e-6)` | whether `abs(expected - actual) <= eps * max(1, abs(expected))`, for floating-point answers |

A read that fails, at the end of the file or on a token that does not fit the variable, stops the checker with a message such as `out: expected an integer, got end of file`. A failure in `out` is a wrong answer; a failure in `in` or `ans` is a checker error, since those files come from the tests. A checker that exits 0 with tokens left in `out` rejects them as extra output. `fmt` and `args` work as in `std::format`, e.g. `wrong("expected {}, got {}", expected, actual)`.

```cpp
void check()
{
	long long expected, actual;
	ans >> expected;
	out >> actual;
	if (actual != expected) wrong("expected {}, got {}", expected, actual);
}

int main(int argc, char** argv)
{
	init(argc, argv);
	int t = 1;
	in >> t;
	while (t--)
		check();
}
```

## Interactors: `interactor.hpp`

An interactive problem's tests are inputs for `interactor.cpp`, which holds the hidden data and judges the solution. You choose the format of the `.in` files; the hack format from the statement is usually the easiest. A `.out` file is optional.

`interactor.cpp` runs as `interactor <input> [<answer>]`, with the test's `.in` file and, when it exists, its `.out` file. Whatever it prints goes to the solution's stdin, and whatever the solution prints comes to its stdin. It exits like a checker: 0 accepts, 1 is a wrong answer and 2 is an interactor error. It should exit 0 once the solution has answered the last test case.

| Helper | Description |
|---|---|
| `init(argc, argv)` | opens the streams `in` (the test input), `ans` (the `.out` file) and `sol` (what the solution prints); call it first |
| `send(args...)` | sends the arguments to the solution on one line, separated by spaces, and flushes it; a container sends its elements |

`>>`, `wrong`, `fail` and `close_enough` work as in checkers. Reading past the end of `sol`, which happens when the solution exits early, is a wrong answer, and reading `ans` for a test without a `.out` file is an interactor error. The tools stop the solution as soon as the interactor rejects it.

Count queries per test case. On Codeforces, the judge sends `-1` before rejecting a query, so the solution exits instead of reading on.

```cpp
void interact()
{
	long long secret;
	in >> secret;
	for (int queries = 0;; queries++) {
		string type;
		sol >> type;
		if (type == "!") {
			long long actual;
			sol >> actual;
			if (actual != secret) wrong("expected {}, got {}", secret, actual);
			return;
		}
		if (queries == 30) {
			send(-1);
			wrong("too many queries");
		}
		long long guess;
		sol >> guess;
		send(guess < secret ? "<" : guess > secret ? ">" : "=");
	}
}

int main(int argc, char** argv)
{
	init(argc, argv);
	int t = 1;
	in >> t;
	send(t);
	while (t--)
		interact();
}
```
