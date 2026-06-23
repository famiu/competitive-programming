#include <bits/stdc++.h>
using namespace std;
using u32 = uint32_t;

constexpr u32 MAX_VAL = 1e6;
array<u32, MAX_VAL + 1> spf{};

void build_spf() {
    for (u32 i = 0; i <= MAX_VAL; i++)
        spf[i] = i;

    for (u32 i = 4; i <= MAX_VAL; i += 2)
        spf[i] = 2;

    for (u32 i = 3; i * i <= MAX_VAL; i += 2) {
        if (spf[i] != i) continue;
        for (u32 j = i * i; j <= MAX_VAL; j += 2 * i)
            if (spf[j] == j) spf[j] = i;
    }
}

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    build_spf();

    u32 t;
    cin >> t;

    for (u32 iter = 0; iter < t; iter++) {
        u32 n;
        cin >> n;

        u32 etf = n;

        while (n != 1) {
            u32 prime_div = spf[n];
            etf -= etf / prime_div;

            while (n % prime_div == 0)
                n /= prime_div;
        }

        cout << etf << "\n" ;
    }

    return 0;
}
