#include <bits/stdc++.h>
using namespace std;

using ll = long long;

vector<int> palindromes;

bool is_palindrome(int x)
{
	int a = x;
	int b = 0;
	while (x != 0) {
		b = b * 10 + (x % 10);
		x /= 10;
	}

	return a == b;
}

void solve()
{
	int n;
	cin >> n;

	unordered_map<int, int> a(n);
	ll ans = 0;
	for (int i = 0; i < n; i++) {
		int x;
		cin >> x;
		a[x]++;

		for (auto& p : palindromes) {
			if (a.find(p ^ x) != a.end())
				ans += a[p ^ x];
		}
	}

	cout << ans << "\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	for (int i = 0; i < (2 << 15); i++)
		if (is_palindrome(i))
			palindromes.push_back(i);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
