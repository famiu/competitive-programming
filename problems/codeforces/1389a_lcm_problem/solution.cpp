#include <bits/stdc++.h>
using namespace std;

using ll = long long;

void solve()
{
	ll l, r;
	cin >> l >> r;
	auto [x, y] = (2 * l <= r) ? make_pair(l, 2 * l) : make_pair(-1LL, -1LL);
	cout << x << " " << y << "\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
