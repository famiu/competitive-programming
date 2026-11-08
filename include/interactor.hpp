// Helpers for interactors. `just test`, `just run` and `just stress` run an interactor as
//   interactor <input> [<answer>]
// with its stdin connected to the solution's output and its stdout to the solution's input.
// <answer> is the test's .out file, passed only when it exists.
//
// Exit codes are those of checker.hpp: 0 accepts, 1 is a wrong answer and 2 is an interactor
// error. Messages go to stderr and are shown on rejection. Reading past the end of the
// solution's output, which happens when it exits early, is a wrong answer.
#pragma once

#include <bits/stdc++.h>
#include "checker.hpp"

// Sends one line to the solution and flushes it.
template <class... Args>
void send(std::format_string<Args...> fmt, Args&&... args)
{
	std::println(std::cout, fmt, std::forward<Args>(args)...);
	std::cout.flush();
}

struct Interaction
{
	Stream input, solution;
	std::optional<Stream> answer;
};

inline Interaction open_interaction(int argc, char** argv)
{
	judge_name = "interactor";
	if (argc != 2 && argc != 3) fail("usage: {} <input> [<answer>]", argc > 0 ? argv[0] : "interactor");
	std::optional<Stream> answer;
	if (argc == 3) answer.emplace(argv[2], "answer", false);
	return {{argv[1], "input", false}, {std::cin, "output", true}, std::move(answer)};
}
