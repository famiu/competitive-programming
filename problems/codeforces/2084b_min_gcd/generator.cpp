#include <bits/stdc++.h>
#include "gen.hpp"
using namespace std;

int main(int argc, char** argv)
{
	seed(argc, argv);

	out(1);
	int n = rnd(2, 8);
	out(n);
	out(rnd_vec(n, 1, rnd(1, 12)));
}
