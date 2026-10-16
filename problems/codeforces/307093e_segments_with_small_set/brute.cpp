#include <bits/stdc++.h>
using namespace std;

#ifdef LOCAL
#include "debug.hpp"
#else
#define dbg(...) ((void)sizeof((__VA_OPT__(__VA_ARGS__, ) 0)))
#endif

using ll = long long;
using u32 = uint32_t;
using u64 = uint64_t;

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int n, k;
	cin >> n >> k;
	vector<int> a(n);
	for (auto& x : a)
		cin >> x;

	ll segments = 0;
	for (int l = 0; l < n; l++) {
		for (int r = l; r < n; r++) {
			set<int> distinct(a.begin() + l, a.begin() + r + 1);
			if (static_cast<int>(distinct.size()) <= k) segments++;
		}
	}

	cout << segments << "\n";
}
