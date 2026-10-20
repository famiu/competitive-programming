#include <bits/stdc++.h>
using namespace std;

void solve()
{
	int n;
	cin >> n;
	bool sortable = true;
	for (int i = 1; i <= n; ++i) {
		int v;
		cin >> v;
		unsigned hi = max(i, v), lo = min(i, v);
		sortable &= (hi % lo == 0 && has_single_bit(hi / lo));
	}
	cout << (sortable ? "YES\n" : "NO\n");
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t;
	cin >> t;
	while (t--)
		solve();
}
