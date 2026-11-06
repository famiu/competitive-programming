#include <bits/stdc++.h>
#include "gen.hpp"
using namespace std;

int main(int argc, char** argv)
{
	seed(argc, argv);

	// Small inputs find bugs fastest and are easy to read.
	int t = 1;
	out(t);
	size_t n = rnd(3, 25);
	out(rnd_str(n, "01"));
}
