#include <bits/stdc++.h>
using namespace std;

int query(int l, int r)
{
	cout << "? " << l << " " << r << endl;
	int a;
	cin >> a;
	if (a == -1)
		exit(0);

	return a;
}

void solve()
{
	int n;
	cin >> n;

	int a = query(1, n);
	if (a == n) {
		cout << "! NO" << endl;
		return;
	}
	a = query(a + 1, n);
	if (a == 0) {
		cout << "! NO" << endl;
	} else {
		cout << "! YES" << endl;
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
