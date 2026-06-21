#include <bits/stdc++.h>
#include <cassert>
using namespace std;

static constexpr inline uint32_t sqrt_flr(uint32_t n)
{
    return static_cast<uint32_t>(sqrt(n));
}

int main() {
    constexpr uint32_t MAX_VAL = 1000000;
    bitset<MAX_VAL + 1> sieve;
    sieve.set();
    sieve[0] = sieve[1] = false;

    for (uint32_t i = 2; i <= sqrt_flr(sieve.size()); i++) {
        if (!sieve[i]) {
            continue;
        }

        for (uint32_t j = i * i; j < sieve.size(); j += i) {
            sieve[j] = false;
        }
    }

    uint32_t n;
    cin >> n;
    for (uint32_t i = 0; i < n; i++) {
        uint32_t num;
        cin >> num;

        if (num == 1) {
            cout << "1\n";
            continue;
        }
        if (sieve[num]) {
            cout << "2\n";
            continue;
        }

        uint32_t divisors = 1;

        for (uint32_t j = 2; j <= sqrt_flr(num); j++) {
            if (!sieve[j]) {
                continue;
            }

            uint32_t pow = 0;

            while (num % j == 0) {
                num /= j;
                pow++;
            }

            divisors *= pow + 1;
        }

        if (num > 1) {
            divisors *= 2;
        }

        cout << divisors << "\n";
    }
}
