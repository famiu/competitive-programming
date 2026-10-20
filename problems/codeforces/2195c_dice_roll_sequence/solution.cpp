#include <bits/stdc++.h>
using namespace std;

void solve()
{
	int n;
	cin >> n;
	vector<int> a(n);
	for (auto& x : a)
		cin >> x;

	int ops = 0;
	for (int i = n - 2; i >= 0; i--) {
		if (a[i] == a[i + 1] || 7 - a[i] == a[i + 1]) {
			ops++;
			i--;
		}
	}

	cout << ops << endl;
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);
	int t;
	cin >> t;
	while (t--) {
		solve();
	}
}
