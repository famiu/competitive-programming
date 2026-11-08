#include <bits/stdc++.h>
#include "checker.hpp"
using namespace std;

void check()
{
	// read the test case from in
	long long expected, actual;
	ans >> expected;
	out >> actual;
	if (actual != expected) wrong("expected {}, got {}", expected, actual);
}

int main(int argc, char** argv)
{
	init(argc, argv);
	int t = 1;
	in >> t;
	while (t--)
		check();
}
