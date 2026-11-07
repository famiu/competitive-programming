#include <bits/stdc++.h>
using namespace std;

void solve()
{
	int n, k;
	cin >> n >> k;

	int a_odd = 0, b_odd = 0, x;
	for (int i = 0; i < n; i++) {
		cin >> x;
		a_odd += (x % 2);
	}
	for (int i = 0; i < n; i++) {
		cin >> x;
		b_odd += (x % 2);
	}

	// a' = 2a + k
	// 2a is always even, so 2a + k always has parity of k
	// k even: can convert odd to even
	// k odd: can convert even to odd
	bool can_convert = (k % 2 == 0 ? (a_odd >= b_odd) : (b_odd >= a_odd));
	cout << (can_convert ? "YES\n" : "NO\n");
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
