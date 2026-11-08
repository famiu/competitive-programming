#include <bits/stdc++.h>
#include "interactor.hpp"
using namespace std;

int main(int argc, char** argv)
{
	auto [input, solution, answer] = open_interaction(argc, argv);

	// Typically: read the hidden data, send the solution what it may know, answer its queries,
	// then check its final answer.
	auto secret = input.read<long long>("the secret");
	int queries = 0;
	while (true) {
		auto type = solution.read<string>("\"?\" or \"!\"");
		if (type == "?") {
			if (++queries > 30) wrong("more than 30 queries");
			auto guess = solution.read<long long>("a guess");
			send("{}", guess < secret ? "<" : guess > secret ? ">" : "=");
		} else if (type == "!") {
			auto actual = solution.read<long long>("the answer");
			ensure(actual == secret, "expected {}, got {}", secret, actual);
			return 0;
		} else {
			wrong("expected \"?\" or \"!\", got \"{}\"", type);
		}
	}
}
