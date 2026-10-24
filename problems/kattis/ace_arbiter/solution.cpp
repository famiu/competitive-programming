#include <bits/stdc++.h>
using namespace std;

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);
	int n;
	cin >> n;
	int a = 0, b = 0;
	for (int i = 1; i <= n; ++i) {
		string str;
		cin >> str;
		int x, y;
		sscanf(str.c_str(), "%d-%d", &x, &y);
		bool alice_serve = (x + y) % 4 == 0 || (x + y) % 4 == 3;
		auto [anew, bnew] = alice_serve ? make_pair(x, y) : make_pair(y, x);
		if ((a == 11 || b == 11) && (anew != a || bnew != b)) {
			cout << "error " << i << "\n";
			return 0;
		}
		if (anew < a || bnew < b || anew > 11 || bnew > 11 || (anew == 11 && bnew == 11)) {
			cout << "error " << i << "\n";
			return 0;
		}
		a = anew;
		b = bnew;
	}
	cout << "ok\n";
}
