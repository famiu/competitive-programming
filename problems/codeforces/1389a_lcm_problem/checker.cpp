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

		bool exists = answer.read<long long>("x") != -1;
		answer.read<long long>("y");

		auto x = output.read<long long>("x");
		auto y = output.read<long long>("y");
		if (x == -1 && y == -1) {
			ensure(!exists, "test {}: printed -1 -1, but a valid pair in [{}, {}] exists", tc, l, r);
			continue;
		}
		ensure(l <= x && x < y && y <= r, "test {}: need {} <= x < y <= {}, got x = {}, y = {}", tc, l, r, x, y);
		long long m = x / gcd(x, y) * y;
		ensure(l <= m && m <= r, "test {}: lcm({}, {}) = {} is outside [{}, {}]", tc, x, y, m, l, r);
		if (!exists) fail("test {}: {} {} is valid, but the answer is -1 -1", tc, x, y);
	}
	output.expect_eof();
}
