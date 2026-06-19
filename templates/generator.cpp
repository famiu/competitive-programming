#include <bits/stdc++.h>
using namespace std;

int main(int argc, char** argv)
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    uint64_t seed = 1;
    if (argc >= 2) {
        seed = stoull(argv[1]);
    }

    mt19937_64 rng(seed);

    return 0;
}
