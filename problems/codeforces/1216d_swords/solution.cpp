#include <bits/stdc++.h>
using namespace std;

using ll = long long;

void solve()
{
	int n;
	cin >> n;
	vector<ll> a(n);
	ll remaining = 0;
	ll x = -1;
	for (auto& e : a) {
		cin >> e;
		remaining += e;
		x = max(x, e);
	}

	ll z = 0;
	for (auto& e : a) {
		z = gcd(z, x - e);
	}

	ll ans = (n * x - remaining) / z;

	cout << ans << " " << z << "\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	// cin >> t;
	while (t--)
		solve();
}
