#include <bits/stdc++.h>
using namespace std;

#ifdef LOCAL
#include "debug.hpp"
#else
#define dbg(...) ((void)sizeof((__VA_OPT__(__VA_ARGS__, ) 0)))
#endif

using ll = long long;
using ull = unsigned long long;
using ld = long double;
#ifdef __SIZEOF_INT128__
using i128 = __int128;
using u128 = unsigned __int128;
#endif

void solve()
{
	int n;
	cin >> n;
	vector<ll> a(n);
	for (auto& x : a)
		cin >> x;

	for (int mask = 1; mask < (1 << n) - 1; mask++) {
		ll mn = LLONG_MAX, g = 0;
		for (int i = 0; i < n; i++) {
			if (mask >> i & 1)
				mn = min(mn, a[i]);
			else
				g = gcd(g, a[i]);
		}
		if (mn == g) {
			cout << "Yes\n";
			return;
		}
	}
	cout << "No\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
