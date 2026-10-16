#include <bits/stdc++.h>
#include "gen.hpp"
using namespace std;

int main(int argc, char** argv)
{
	seed(argc, argv);

	int n = rnd(1, 8);
	int k = rnd(1, n);
	out(n, k);
	out(rnd_vec(n, 1, rnd(1, 8)));
}
