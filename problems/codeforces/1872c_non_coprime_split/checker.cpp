#include <bits/stdc++.h>
#include "checker.hpp"
using namespace std;

void check()
{
	long long l, r;
	in >> l >> r;

	long long aa, ab;
	ans >> aa;
	bool exists = aa != -1;
	if (exists) ans >> ab;

	long long a;
	out >> a;
	if (a == -1) {
		if (exists) wrong("printed -1, but a split of some n in [{}, {}] exists", l, r);
		return;
	}
	long long b;
	out >> b;
	if (a < 1 || b < 1) wrong("a = {} and b = {} must be positive", a, b);
	if (a + b < l || a + b > r) wrong("a + b = {} is outside [{}, {}]", a + b, l, r);
	if (gcd(a, b) == 1) wrong("gcd({}, {}) = 1", a, b);
	if (!exists) fail("{} {} is valid, but the answer is -1", a, b);
}

int main(int argc, char** argv)
{
	init(argc, argv);
	int t = 1;
	in >> t;
	while (t--)
		check();
}
