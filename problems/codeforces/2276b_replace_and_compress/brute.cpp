#include <bits/stdc++.h>
using namespace std;

string compress(string s)
{
	s.erase(unique(s.begin(), s.end()), s.end());
	return s;
}

void solve()
{
	string s;
	cin >> s;

	unordered_set<string> results;
	results.insert(compress(s));
	for (size_t i = 1; i + 1 < s.size(); i++) {
		string copy = s;
		copy[i] = (copy[i] == '0' ? '1' : '0');
		results.insert(compress(move(copy)));
	}

	cout << results.size() << '\n';
}

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t;
	cin >> t;
	while (t--)
		solve();
}
