#include <bits/stdc++.h>
using namespace std;

using ll = long long;

void solve()
{
	int n;
	cin >> n;
	vector<ll> a(n);
	for (auto& x : a)
		cin >> x;

	auto it = min_element(a.begin(), a.end());
	ll min = *it;
	a.erase(it);

	ll r = 0;
	for (auto x : a)
		if (x % min == 0)
			r = gcd(r, x);

	if (r == min)
		cout << "Yes\n";
	else
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
