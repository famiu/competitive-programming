#include <bits/stdc++.h>
using namespace std;

void solve()
{
	string s;
	cin >> s;

	bool can_split = false;
	bool can_merge = false;
	for (int i = 1; i < s.size() - 1; ++i) {
		if (s[i] == s[i - 1] && s[i] == s[i + 1])
			can_split = true;
		if (s[i] != s[i - 1] && s[i - 1] == s[i + 1])
			can_merge = true;
	}

	cout << 1 + can_split + can_merge << "\n";
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t = 1;
	cin >> t;
	while (t--)
		solve();
}
