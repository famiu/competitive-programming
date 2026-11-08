// Helpers for checkers. `just test` and `just stress` run a checker as
//   checker <input> <output> <answer>
// where <output> is the solution's output and <answer> is the expected output (testlib order).
//
// init(argc, argv) opens the three files as `in`, `out` and `ans`, read with >> (see judge.hpp).
// Exiting with tokens left in `out` is a wrong answer, unless the checker already gave a verdict.
#pragma once

#include <bits/stdc++.h>
#include "judge.hpp"

// The solution's output.
inline Stream out("out");

inline void init(int argc, char** argv)
{
	judge_detail::role = "checker";
	if (argc != 4) fail("usage: {} <input> <output> <answer>", argc > 0 ? argv[0] : "checker");
	in.open(argv[1], false);
	out.open(argv[2], true);
	ans.open(argv[3], false);
}

namespace judge_detail {

struct leftover_check
{
	~leftover_check()
	{
		if (done || !out.is_open()) return;
		if (std::string token = out.next_token(); !token.empty()) {
			std::println(std::cerr, "wrong answer: out: unexpected extra output starting with \"{}\"", token);
			std::_Exit(1);
		}
	}
};

inline leftover_check leftover_check_at_exit;

}  // namespace judge_detail
