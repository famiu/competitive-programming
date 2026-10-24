#include <bits/stdc++.h>
using namespace std;

using ll = long long;
using ull = unsigned long long;
using ld = long double;

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);
	ll n;
	cin >> n;
	char c;
	ll lectures = 0, cups = 0;
	while (n--) {
		cin >> c;
		if (c == '1') {
			lectures++;
			cups = 2;
		} else if (cups > 0) {
			lectures++;
			cups--;
		}
	}
	cout << lectures << endl;
}
