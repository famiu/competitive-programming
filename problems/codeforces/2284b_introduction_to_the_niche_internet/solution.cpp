#include <bits/stdc++.h>
using namespace std;

using ll = long long;

void solve()
{
	int n, k;
	cin >> n >> k;
	vector<ll> a(n);
	for (auto& x : a)
		cin >> x;

	sort(a.begin(), a.end());
	rotate(a.begin(), a.end() - k, a.end());
	reverse(a.begin() + k, a.end());

	double avg = a[0];
	int pleasant = 1;
	for (int i = 1; i < n; i++) {
		if (a[i] >= avg)
			pleasant++;
		avg = (avg * i + a[i]) / (i + 1);
	}

	if (pleasant != k) {
		cout << "NO\n";
	} else {
		cout << "YES\n";
		for (auto& x : a)
			cout << x << " ";
		cout << "\n";
	}
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
