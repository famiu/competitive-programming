// Helpers for checkers. `just test` and `just stress` run a checker as
//   checker <input> <output> <answer>
// where <output> is the solution's output and <answer> is the expected output (testlib order).
//
// Exit codes: 0 accepts, 1 is a wrong answer and 2 is a checker error, e.g. when the input or
// the expected answer cannot be read. Messages go to stderr and are shown on rejection.
#pragma once

#include <bits/stdc++.h>

template <class... Args>
[[noreturn]] void wrong(std::format_string<Args...> fmt, Args&&... args)
{
	std::println(std::cerr, "wrong answer: {}", std::format(fmt, std::forward<Args>(args)...));
	std::exit(1);
}

template <class... Args>
[[noreturn]] void fail(std::format_string<Args...> fmt, Args&&... args)
{
	std::println(std::cerr, "checker error: {}", std::format(fmt, std::forward<Args>(args)...));
	std::exit(2);
}

// Rejects with a wrong answer unless `cond` holds.
template <class... Args>
void ensure(bool cond, std::format_string<Args...> fmt, Args&&... args)
{
	if (!cond) wrong(fmt, std::forward<Args>(args)...);
}

// True when `actual` is within `eps` of `expected`, absolutely or relatively.
inline bool close_enough(long double expected, long double actual, long double eps = 1e-6L)
{
	return std::abs(expected - actual) <= eps * std::max(1.0L, std::abs(expected));
}

// Reads whitespace-separated tokens from one file. Problems reading the solution's output
// are wrong answers; problems reading the input or the expected answer are checker errors.
class Stream
{
public:
	Stream(const char* path, std::string name, bool is_output)
		: file_(path), name_(std::move(name)), is_output_(is_output)
	{
		if (!file_) fail("cannot open {} ({})", name_, path);
	}

	// Reads one token as T (an integer, floating-point or string type).
	template <class T>
	T read(std::string_view what)
	{
		std::string token;
		if (!(file_ >> token)) reject("{}: expected {}, got end of file", name_, what);
		if constexpr (std::is_convertible_v<std::string, T>) {
			return token;
		} else {
			T value{};
			auto [end, ec] = std::from_chars(token.data(), token.data() + token.size(), value);
			if (ec != std::errc() || end != token.data() + token.size())
				reject("{}: expected {}, got \"{}\"", name_, what, token);
			return value;
		}
	}

	// Reads one value and checks that it is in [lo, hi].
	template <class T>
	T read(T lo, T hi, std::string_view what)
	{
		T value = read<T>(what);
		if (value < lo || value > hi) reject("{}: {} is {}, outside [{}, {}]", name_, what, value, lo, hi);
		return value;
	}

	// Reads n values.
	template <class T>
	std::vector<T> read_vec(int n, std::string_view what)
	{
		std::vector<T> v(n);
		for (auto& x : v) x = read<T>(what);
		return v;
	}

	// Rejects anything left after the expected tokens.
	void expect_eof()
	{
		std::string token;
		if (file_ >> token) reject("{}: unexpected extra output starting with \"{}\"", name_, token);
	}

private:
	template <class... Args>
	[[noreturn]] void reject(std::format_string<Args...> fmt, Args&&... args)
	{
		std::string message = std::format(fmt, std::forward<Args>(args)...);
		if (is_output_) wrong("{}", message);
		fail("{}", message);
	}

	std::ifstream file_;
	std::string name_;
	bool is_output_;
};

struct Files
{
	Stream input, output, answer;
};

inline Files open_files(int argc, char** argv)
{
	if (argc != 4) fail("usage: {} <input> <output> <answer>", argc > 0 ? argv[0] : "checker");
	return {{argv[1], "input", false}, {argv[2], "output", true}, {argv[3], "answer", false}};
}
