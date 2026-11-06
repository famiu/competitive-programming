#include <bits/stdc++.h>
using namespace std;

using ll = long long;

void solve()
{
	int n;
	cin >> n;
	ll area = n / 2 * (n - n / 2);
	cout << area << "\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
