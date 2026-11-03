#include <bits/stdc++.h>
using namespace std;
using ll = long long;

void solve()
{
	int n, x;
	cin >> n >> x;
	vector<int> a(n);
	for (auto& e : a)
		cin >> e;

	vector<int> pf;
	for (ll i = 2; i * i <= x; ++i) {
		if (x % i == 0) {
			pf.push_back(i);
			while (x % i == 0)
				x /= i;
		}
	}
	if (x > 1)
		pf.push_back(x);

	ll ans = 0;
	for (int i = 0; i < pf.size(); i++) {
		ll total = 0;
		for (int j = 0; j < a.size(); j++)
			if (a[j] % pf[i] == 0)
				total += a[j];
		ans = max(total, ans);
	}
	cout << ans << "\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
