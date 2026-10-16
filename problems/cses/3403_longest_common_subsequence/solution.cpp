#include <bits/stdc++.h>
using namespace std;

using i32 = int;
using i64 = long long;
using u32 = unsigned int;
using u64 = unsigned long long;
using i128 = __int128;
using u128 = unsigned __int128;

i32 main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	i32 n, m;
	cin >> n >> m;
	vector<i32> a(n), b(m);
	for (auto& x : a) cin >> x;
	for (auto& x : b) cin >> x;

	vector<vector<i32>> memo(n + 1, vector<i32>(m + 1, 0));
	for (i32 i = n - 1; i >= 0; --i) {
		for (i32 j = m - 1; j >= 0; --j) {
			memo[i][j] = a[i] == b[j] ? 1 + memo[i + 1][j + 1] : max(memo[i + 1][j], memo[i][j + 1]);
		}
	}

	vector<i32> lcs;
	for (i32 i = 0, j = 0; i < n && j < m;) {
		if (a[i] == b[j]) {
			lcs.push_back(a[i]);
			++i, ++j;
		} else if (memo[i + 1][j] >= memo[i][j + 1]) {
			++i;
		} else {
			++j;
		}
	}

	cout << lcs.size() << '\n';
	for (auto x : lcs) cout << x << ' ';
	cout << '\n';
}
