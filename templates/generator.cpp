#include <bits/stdc++.h>
#include "gen.hpp"
using namespace std;

int main(int argc, char** argv)
{
    seed(argc, argv);

    // Small inputs find bugs fastest and are easy to read.
    int n = rnd(1, 8);
    out(n);
    out(rnd_vec(n, 1, 10));
}
