#include <bits/stdc++.h>
#include "checker.hpp"
using namespace std;

using ll = long long;

void check()
{
	int n, k;
	in >> n >> k;
	vector<ll> a(n);
	in >> a;

	bool ok = ans.yes();
	if (ok) {
		vector<ll> skip(n);
		ans >> skip;
	}

	if (!out.yes()) {
		if (ok) wrong("NO but answer exists");
		return;
	}

	vector<ll> b(n);
	out >> b;
	auto c = b;
	ranges::sort(a);
	ranges::sort(c);
	if (a != c) wrong("not a permutation");

	int cnt = 1;
	ll s = b[0];
	for (int i = 1; i < n; i++) {
		if (b[i] * i >= s) cnt++;
		s += b[i];
	}
	if (cnt != k) wrong("cnt {} != k {}", cnt, k);
	if (!ok) fail("valid but answer is NO");
}

int main(int argc, char** argv)
{
	init(argc, argv);
	int t = 1;
	in >> t;
	while (t--)
		check();
}
