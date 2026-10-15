#include <bits/stdc++.h>
#include "gen.hpp"
using namespace std;

int main(int argc, char** argv)
{
	seed(argc, argv);

	int n = rnd(1, 8);
	vector<int> a = rnd_vec(n, 1, 10);
	long long total = accumulate(a.begin(), a.end(), 0LL);
	out(n, rnd(1LL, total + 5));
	out(a);
}
