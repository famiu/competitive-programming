// dbg(a, b, ...) prints "file:line [a = 1, b = 2]" to stderr. Solutions include this header
// only when LOCAL is defined (debug builds), so it never reaches a submission.
//
// Values are printed with std::format when possible. Otherwise ranges, pairs and tuples are
// printed element by element, and other types use operator<< if they define it.
#pragma once

#include <bits/stdc++.h>
#include <unistd.h>

#define dbg(...) ::dbg_detail::print(__FILE__, __LINE__, #__VA_ARGS__ __VA_OPT__(, ) __VA_ARGS__)

namespace dbg_detail {

template <class T>
concept streamable = requires(std::ostream& os, const T& value) { os << value; };

template <class T>
concept tuple_like = requires { std::tuple_size<T>::value; };

template <class T>
void write(std::string& out, const T& value)
{
	if constexpr (std::formattable<T, char>) {
		std::format_to(std::back_inserter(out), "{}", value);
	} else if constexpr (tuple_like<T>) {
		auto write_parts = [&](const auto&... parts) {
			const char* sep = "";
			((out += sep, write(out, parts), sep = ", "), ...);
		};
		out += '(';
		std::apply(write_parts, value);
		out += ')';
	} else if constexpr (std::ranges::input_range<const T>) {
		out += '[';
		const char* sep = "";
		for (const auto& element : value) {
			out += sep;
			write(out, element);
			sep = ", ";
		}
		out += ']';
	} else if constexpr (streamable<T>) {
		std::ostringstream ss;
		ss << value;
		out += ss.str();
	} else {
		static_assert(false, "dbg cannot print this type; give it operator<< or a std::formatter");
	}
}

// Splits the next argument's source text off `names`, ignoring commas inside brackets and quotes.
inline std::string_view next_name(std::string_view& names)
{
	int depth = 0;
	char quote = 0;
	size_t i = 0;
	for (; i < names.size(); i++) {
		char c = names[i];
		if (quote) {
			if (c == '\\')
				i++;
			else if (c == quote)
				quote = 0;
			continue;
		}
		if (c == '"' || c == '\'') quote = c;
		if (c == '(' || c == '[' || c == '{') depth++;
		if (c == ')' || c == ']' || c == '}') depth--;
		if (c == ',' && depth == 0) break;
	}
	std::string_view name = names.substr(0, i);
	names.remove_prefix(std::min(i + 1, names.size()));
	while (!names.empty() && names.front() == ' ') names.remove_prefix(1);
	return name;
}

template <class... Args>
void print(std::string_view file, int line, std::string_view names, const Args&... args)
{
	static const bool color = isatty(STDERR_FILENO);
	file = file.substr(file.find_last_of('/') + 1);

	std::string out;
	if (color) out += "\033[2m";
	std::format_to(std::back_inserter(out), "{}:{}", file, line);
	if (color) out += "\033[0m";
	out += " [";
	const char* sep = "";
	((out += sep, out += next_name(names), out += " = ", write(out, args), sep = ", "), ...);
	out += "]\n";
	std::cerr << out;
}

}  // namespace dbg_detail
