#include <bits/stdc++.h>
#include <numeric>
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

	int n;
	ll s;
	cin >> n >> s;
	vector<int> a(n);
	for (auto& x : a)
		cin >> x;

	int shortest = -1;
	for (int i = 0; i < n; i++) {
		for (int j = i + 1; j <= n; j++) {
			ll sum = accumulate(a.begin() + i, a.begin() + j, 0LL);
			if (sum >= s)
				shortest = shortest == -1 ? j - i : min(shortest, j - i);
		}
	}

	cout << shortest << "\n";
}
