#include <bits/stdc++.h>
using namespace std;

using ll = long long;

void solve()
{
	int n;
	cin >> n;
	vector<int> a(n);
	for (auto& x : a)
		cin >> x;

	sort(a.begin(), a.end(), greater<int>());

	ll x = 0, y = 0;
	for (int i = 0; i < n; i++) {
		if (x < y) {
			x += (1LL << a[i]);
		} else {
			y += (1LL << a[i]);
		}
	}
	cout << x * y << "\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
