// Shared helpers for checker.hpp and interactor.hpp; include one of those instead.
//
// Exit codes: 0 accepts, 1 is a wrong answer and 2 is an error in the checker or interactor,
// e.g. when the input or the expected answer cannot be read. Messages go to stderr and are shown
// on rejection.
#pragma once

#include <bits/stdc++.h>

namespace judge_detail {

// Names the program in the messages of fail(); set by init().
inline std::string_view role = "checker";

// Set before exiting with a verdict, so that the exit-time checks stay quiet.
inline bool done = false;

}  // namespace judge_detail

template <class... Args>
[[noreturn]] void wrong(std::format_string<Args...> fmt, Args&&... args)
{
	judge_detail::done = true;
	std::println(std::cerr, "wrong answer: {}", std::format(fmt, std::forward<Args>(args)...));
	std::exit(1);
}

template <class... Args>
[[noreturn]] void fail(std::format_string<Args...> fmt, Args&&... args)
{
	judge_detail::done = true;
	std::println(std::cerr, "{} error: {}", judge_detail::role, std::format(fmt, std::forward<Args>(args)...));
	std::exit(2);
}

// True when `actual` is within `eps` of `expected`, absolutely or relatively.
inline bool close_enough(long double expected, long double actual, long double eps = 1e-6L)
{
	return std::abs(expected - actual) <= eps * std::max(1.0L, std::abs(expected));
}

// Reads whitespace-separated tokens with >>. A read that fails, at the end of the stream or on a
// token that does not parse as the variable's type, is a wrong answer when the stream holds the
// solution's output and an error otherwise. >> into a pair or tuple reads each part, and >> into a
// vector reads every element.
class Stream
{
public:
	explicit Stream(std::string name) : name_(std::move(name)) {}

	void open(const char* path, bool is_output)
	{
		file_ = std::make_unique<std::ifstream>(path);
		if (!*file_) fail("cannot open {} ({})", name_, path);
		open(*file_, is_output);
	}

	void open(std::istream& in, bool is_output)
	{
		in_ = &in;
		is_output_ = is_output;
	}

	// Why the stream cannot be read when it was never opened.
	void set_missing(std::string reason) { missing_ = std::move(reason); }

	bool is_open() const { return in_ != nullptr; }

	// The next token, or an empty string at the end of the stream.
	std::string next_token()
	{
		check_open();
		std::string token;
		*in_ >> token;
		return token;
	}

	// Reads YES or NO in any case, as most judges accept; true for YES.
	bool yes()
	{
		check_open();
		std::string t = token("YES or NO");
		std::string lower = t;
		for (auto& c : lower) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
		if (lower != "yes" && lower != "no") reject("{}: expected YES or NO, got \"{}\"", name_, t);
		return lower == "yes";
	}

	template <class T>
	Stream& operator>>(T& value)
	{
		check_open();
		if constexpr (std::same_as<T, std::string>) {
			value = token("a string");
		} else if constexpr (std::same_as<T, char>) {
			if (!(*in_ >> value)) reject("{}: expected a character, got end of file", name_);
		} else if constexpr (std::integral<T> || std::floating_point<T>) {
			constexpr const char* kind = std::integral<T> ? "an integer" : "a number";
			std::string t = token(kind);
			auto [end, ec] = std::from_chars(t.data(), t.data() + t.size(), value);
			if (ec == std::errc::result_out_of_range) reject("{}: {} is out of range", name_, t);
			if (ec != std::errc() || end != t.data() + t.size()) reject("{}: expected {}, got \"{}\"", name_, kind, t);
		} else if constexpr (requires { std::tuple_size<T>::value; }) {
			std::apply([this](auto&... parts) { ((*this >> parts), ...); }, value);
		} else {
			for (auto& element : value) *this >> element;
		}
		return *this;
	}

private:
	template <class... Args>
	[[noreturn]] void reject(std::format_string<Args...> fmt, Args&&... args)
	{
		std::string message = std::format(fmt, std::forward<Args>(args)...);
		if (is_output_) wrong("{}", message);
		fail("{}", message);
	}

	void check_open()
	{
		if (!in_) fail("{}: {}", name_, missing_);
	}

	std::string token(std::string_view kind)
	{
		std::string t;
		if (!(*in_ >> t)) reject("{}: expected {}, got end of file", name_, kind);
		return t;
	}

	std::unique_ptr<std::ifstream> file_;
	std::istream* in_ = nullptr;
	std::string name_;
	std::string missing_ = "not opened by init()";
	bool is_output_ = false;
};

// The test input and the expected output.
inline Stream in("in"), ans("ans");
