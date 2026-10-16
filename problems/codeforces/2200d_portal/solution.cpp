#include <bits/stdc++.h>
using namespace std;

void smallest_permutation(const vector<int>& p, int x, int y)
{
	int in_start = x;
	for (int i = x + 1; i < y; i++)
		if (p[i] < p[in_start])
			in_start = i;

	int out_end;
	for (out_end = 0; out_end < x; out_end++)
		if (p[out_end] > p[in_start])
			break;
	if (out_end == x)
		for (out_end = y; out_end < p.size(); out_end++)
			if (p[out_end] > p[in_start])
				break;

	for (int i = 0; i < min(x, out_end); i++)
		cout << p[i] << " ";
	for (int i = y; i < out_end; i++)
		cout << p[i] << " ";
	for (int i = in_start; i < y; i++)
		cout << p[i] << " ";
	for (int i = x; i < in_start; i++)
		cout << p[i] << " ";
	for (int i = out_end; i < x; i++)
		cout << p[i] << " ";
	for (int i = max(y, out_end); i < p.size(); i++)
		cout << p[i] << " ";

	cout << "\n";
}

int main()
{
	ios::sync_with_stdio(false);
	cin.tie(nullptr);

	int t;
	cin >> t;
	for (int i = 0; i < t; i++) {
		int n, x, y;
		cin >> n >> x >> y;
		vector<int> p(n);
		for (int j = 0; j < n; j++) {
			cin >> p[j];
		}
		smallest_permutation(p, x, y);
	}

	return 0;
}
