#include <bits/stdc++.h>
#include "checker.hpp"
using namespace std;

using ll = long long;

string yn(Stream& s)
{
	auto w = s.read<string>("yes/no");
	for (auto& c : w)
		c = tolower(c);
	return w;
}

int main(int argc, char** argv)
{
	auto [input, output, answer] = open_files(argc, argv);

	int t = input.read<int>("t");
	for (int tc = 1; tc <= t; tc++) {
		int n = input.read<int>("n");
		int k = input.read<int>("k");
		auto a = input.read_vec<ll>(n, "a");

		bool ok = yn(answer) == "yes";
		if (ok) answer.read_vec<ll>(n, "b");

		auto v = yn(output);
		if (v == "no") {
			ensure(!ok, "tc {}: NO but answer exists", tc);
			continue;
		}
		ensure(v == "yes", "tc {}: bad verdict {}", tc, v);

		auto b = output.read_vec<ll>(n, "b");
		auto c = b;
		ranges::sort(a);
		ranges::sort(c);
		ensure(a == c, "tc {}: not a permutation", tc);

		int cnt = 1;
		ll s = b[0];
		for (int i = 1; i < n; i++) {
			if (b[i] * i >= s) cnt++;
			s += b[i];
		}
		ensure(cnt == k, "tc {}: cnt {} != k {}", tc, cnt, k);
		if (!ok) fail("tc {}: valid but answer is NO", tc);
	}
	output.expect_eof();
}
