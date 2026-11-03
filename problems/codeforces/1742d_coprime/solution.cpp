#include <bits/stdc++.h>
using namespace std;

void solve()
{
	int n;
	cin >> n;
	array<int, 1001> idx{};
	vector<int> uniq;
	for (int i = 0; i < n; ++i) {
		int v;
		cin >> v;

		if (!idx[v])
			uniq.push_back(v);
		idx[v] = i + 1;
	}

	int ans = -1;
	for (int i = 0; i < uniq.size(); ++i)
		for (int j = i; j < uniq.size(); ++j)
			if (gcd(uniq[i], uniq[j]) == 1)
				ans = max(ans, idx[uniq[i]] + idx[uniq[j]]);

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
