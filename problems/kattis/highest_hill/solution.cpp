#include <bits/stdc++.h>
using namespace std;

using ll = long long;

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);
	int n;
	cin >> n;
	vector<ll> h(n);
	for (auto& x : h) cin >> x;
	vector<size_t> a;
	vector<size_t> d;
	a.reserve(n);
	d.reserve(n);

	for (int i = 0; i < n - 1; i++)
		if (h[i] < h[i + 1])
			a.push_back(i);
	a.push_back(n - 1);

	for (int i = 0; i < n - 1; i++)
		if (h[i] > h[i + 1])
			d.push_back(i);

	size_t ap = 0, dp = 0;
	ll ans = 0;
	for (; ap < a.size() && dp < d.size();) {
		while (dp < d.size() && a[ap] > d[dp])
			dp++;
		if (dp == d.size())
			break;
		size_t end = ap;
		while (end < a.size() && a[end] < d[dp])
			end++;
		ans = max(ans, min(h[d[dp]] - h[a[ap]], h[d[dp]] - h[a[end]]));
		ap = end;
	}
	cout << ans << "\n";
}
