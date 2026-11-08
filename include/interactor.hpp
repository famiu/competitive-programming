// Helpers for interactors. `just test`, `just run` and `just stress` run an interactor as
//   interactor <input> [<answer>]
// with its stdin connected to the solution's output and its stdout to the solution's input.
// <answer> is the test's .out file, passed only when it exists.
//
// init(argc, argv) opens the input as `in`, the answer as `ans` and the solution's output as
// `sol`, read with >> (see judge.hpp). Reading past the end of `sol`, which happens when the
// solution exits early, is a wrong answer. send() writes to the solution.
#pragma once

#include <bits/stdc++.h>
#include "judge.hpp"

// The solution's output.
inline Stream sol("sol");

inline void init(int argc, char** argv)
{
	judge_detail::role = "interactor";
	if (argc != 2 && argc != 3) fail("usage: {} <input> [<answer>]", argc > 0 ? argv[0] : "interactor");
	in.open(argv[1], false);
	if (argc == 3)
		ans.open(argv[2], false);
	else
		ans.set_missing("the test has no .out file");
	sol.open(std::cin, true);
}

namespace judge_detail {

template <class T>
void put(std::string& line, const T& value)
{
	if constexpr (std::ranges::input_range<T> && !std::convertible_to<T, std::string_view>) {
		for (const auto& element : value) put(line, element);
	} else {
		if (!line.empty()) line += ' ';
		std::format_to(std::back_inserter(line), "{}", value);
	}
}

}  // namespace judge_detail

// Sends the arguments to the solution on one line, separated by spaces, and flushes it.
// Containers are flattened, so send(n, v) sends n followed by the elements of v.
template <class... Args>
void send(const Args&... args)
{
	std::string line;
	(judge_detail::put(line, args), ...);
	std::println(std::cout, "{}", line);
	std::cout.flush();
}
