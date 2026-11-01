#include <bits/stdc++.h>
using namespace std;

using ll = long long;

void solve()
{
	int l, r;
	cin >> l >> r;
	// Case 1: r / 2 == 1: impossible, -1
	// Case 2: r == l, r odd: only possible if a+b == r, one odd, one even
	// Case 3: r == l, r even: a = b = r/2
	// Case 4: r - l >= 1: pick a = b = floor(r/2)
	//
	// For Case 2: let r|m = 0 for some value 1 < m < r, and r' = r/m, and a' + b' = r'
	// Therefore, r = mr' = m(a' + b').
	// Now, let a = ma' and b = mb'. Then, gcd(a,b) = m != 1
	if (r / 2 == 1) {
		cout << "-1\n";
	} else if (r == l && r % 2 != 0) {
		int a = -1, b = -1;
		for (ll i = 3; i * i <= r; i += 2) {
			if (r % i == 0) {
				int rp = r / i;
				if (rp % 2 == 0) {
					a = b = rp / 2;
				} else {
					a = i * (rp / 2);
					b = i * (rp / 2 + 1);
				}
				break;
			}
		}

		if (a == -1)
			cout << "-1\n";
		else
			cout << a << " " << b << "\n";
	} else {
		cout << r / 2 << " " << r / 2 << "\n";
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
