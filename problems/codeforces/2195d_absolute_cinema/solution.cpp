#include <bits/stdc++.h>
using namespace std;

using ll = long long;

void solve()
{
	int n;
	cin >> n;
	vector<ll> f(n);
	for (auto& x : f)
		cin >> x;

	// f(x) = sum(i=1..n, a_i * abs(i - x))
	// f(1) = a_1 * 0 + a_2 * 1 + a_3 * 2 + a_4 * 3 + a_5 * 4 + ... + a_n * (n-1)
	// f(2) = a_1 * 1 + a_2 * 0 + a_3 * 1 + a_4 * 2 + a_5 * 3 + ... + a_n * (n-2)
	// f(3) = a_1 * 2 + a_2 * 1 + a_3 * 0 + a_4 * 1 + a_5 * 2 + ... + a_n * (n-3)
	// f(4) = a_1 * 3 + a_2 * 2 + a_3 * 1 + a_4 * 0 + a_5 * 1 + ... + a_n * (n-4)
	// ...
	// f(n) = a_1 * (n-1) + a_2 * (n-2) + ... a_n * 0
	//
	// (f(1) + f(n)) / (n-1) = sum(a_i) = S
	// (f(x) - f(x+1)) = -(a_1 + ... a_x) + a_(x+1) + ... + a_n
	ll S = (f[0] + f[n - 1]) / (n - 1);
	ll pfx = 0;
	for (int i = 0; i < n - 1; i++) {
		ll elem = f[i] - f[i + 1];
		elem = (S - elem) / 2 - pfx;
		pfx += elem;
		cout << elem << " ";
	}
	cout << S - pfx << "\n";
}
int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t;
	cin >> t;
	while (t--)
		solve();
}
