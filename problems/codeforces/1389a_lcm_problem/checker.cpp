#include <bits/stdc++.h>
#include "checker.hpp"
using namespace std;

void check()
{
	long long l, r;
	in >> l >> r;

	long long ax, ay;
	ans >> ax >> ay;
	bool exists = ax != -1;

	long long x, y;
	out >> x >> y;
	if (x == -1 && y == -1) {
		if (exists) wrong("printed -1 -1, but a valid pair in [{}, {}] exists", l, r);
		return;
	}
	if (!(l <= x && x < y && y <= r)) wrong("need {} <= x < y <= {}, got x = {}, y = {}", l, r, x, y);
	long long m = x / gcd(x, y) * y;
	if (!(l <= m && m <= r)) wrong("lcm({}, {}) = {} is outside [{}, {}]", x, y, m, l, r);
	if (!exists) fail("{} {} is valid, but the answer is -1 -1", x, y);
}

int main(int argc, char** argv)
{
	init(argc, argv);
	int t = 1;
	in >> t;
	while (t--)
		check();
}
