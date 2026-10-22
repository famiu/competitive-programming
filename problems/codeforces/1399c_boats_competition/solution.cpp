#include <bits/stdc++.h>
using namespace std;

void solve()
{
	int n;
	cin >> n;
	vector<int> cnt(n + 1);
	for (int i = 0, w; i < n; i++) {
		cin >> w;
		cnt[w]++;
	}

	int k = 0;
	for (int s = 2; s <= 2 * n; s++) {
		int pairs = 0;
		for (int w = max(1, s - n); w < s - w; w++)
			pairs += min(cnt[w], cnt[s - w]);
		if (s % 2 == 0)
			pairs += cnt[s / 2] / 2;
		k = max(pairs, k);
	}

	cout << k << "\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t;
	cin >> t;
	while (t--)
		solve();
}
