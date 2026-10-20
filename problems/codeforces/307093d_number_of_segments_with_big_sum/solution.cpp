#include <bits/stdc++.h>
using namespace std;

using ll = long long;

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);
	ll n, s;
	cin >> n >> s;
	vector<int> a(n);
	for (auto& x : a)
		cin >> x;

	ll sum = 0, ans = 0;

	for (int l = 0, r = 0; l < n; l++) {
		while (r < n && sum < s)
			sum += a[r++];
		if (sum < s)
			break;
		ans += n - r + 1;
		sum -= a[l];
	}
	cout << ans << endl;
}
