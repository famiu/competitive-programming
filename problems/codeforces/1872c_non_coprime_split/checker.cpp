#include <bits/stdc++.h>
#include "checker.hpp"
using namespace std;

int main(int argc, char** argv)
{
	auto [input, output, answer] = open_files(argc, argv);

	int t = input.read<int>("t");
	for (int tc = 1; tc <= t; tc++) {
		auto l = input.read<long long>("l");
		auto r = input.read<long long>("r");

		bool exists = answer.read<long long>("a") != -1;
		if (exists) answer.read<long long>("b");

		auto a = output.read<long long>("a");
		if (a == -1) {
			ensure(!exists, "test {}: printed -1, but a split of some n in [{}, {}] exists", tc, l, r);
			continue;
		}
		auto b = output.read<long long>("b");
		ensure(a >= 1 && b >= 1, "test {}: a = {} and b = {} must be positive", tc, a, b);
		ensure(l <= a + b && a + b <= r, "test {}: a + b = {} is outside [{}, {}]", tc, a + b, l, r);
		ensure(gcd(a, b) != 1, "test {}: gcd({}, {}) = 1", tc, a, b);
		if (!exists) fail("test {}: {} {} is valid, but the answer is -1", tc, a, b);
	}
	output.expect_eof();
}
