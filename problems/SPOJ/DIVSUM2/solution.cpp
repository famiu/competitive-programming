#include <bits/stdc++.h>
using namespace std;

#ifndef NDEBUG
#define dbg(...)                                        \
    do {                                                \
        string _h = __FILE__ ":" + to_string(__LINE__); \
        _dbg_impl(_h, __VA_ARGS__);                     \
    } while (0)

void _dbg_impl(const string& header) { println(cerr, "{}", header); }

template <typename T>
void _dbg_impl(const string& header, T&& first)
{
    println(cerr, "{} {}", header, first);
}

template <typename T, typename... Args>
void _dbg_impl(const string& header, T&& first, Args&&... rest)
{
    print(cerr, "{} {}, ", header, first);
    _dbg_impl("", forward<Args>(rest)...);
}
#else
#define dbg(...)
#endif

// ── Type aliases ──────────────────────────────────────────────────────────────
using i32 = int32_t;
using u32 = uint32_t;
using i64 = int64_t;
using u64 = uint64_t;
using ll = long long;
using ull = unsigned long long;

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    bitset<100000000> sieve;
    for (u32 i = 0; i < sieve.size(); i++) {
        sieve[i] = true;
    }
    sieve[0] = sieve[1] = false;

    for (u64 i = 2; i * i <= sieve.size(); i++) {
        if (!sieve[i]) {
            continue;
        }

        for (u64 j = i * i; j < sieve.size(); j += i)
            sieve[j] = false;
    }

    vector<u32> primes;
    primes.reserve(static_cast<size_t>(ceil(1.26 * sieve.size() / log(sieve.size()))));

    for (u32 i = 2; i < sieve.size(); i++) {
        if (sieve[i])
            primes.push_back(i);
    }

    u32 n;
    cin >> n;
    for (u32 i = 0; i < n; i++) {
        u64 num;
        cin >> num;
        u64 num_save = num;

        if (num == 1) {
            cout << "0\n";
            continue;
        }

        u64 divisor_sum = 1;

        for (u32 j = 0; j < primes.size() && static_cast<u64>(primes[j]) * primes[j] <= num; j++) {
            u64 div = primes[j];

            u64 series_sum = 1;
            u64 div_power = 1;

            while (num % div == 0) {
                num /= div;
                div_power *= div;
                series_sum += div_power;
            }

            divisor_sum *= series_sum;
        }

        if (num == num_save) {
            cout << "1\n";
            continue;
        }
        if (num > 1) {
            divisor_sum *= (1 + num);
        }

        divisor_sum -= num_save;
        cout << divisor_sum << "\n";
    }

    return 0;
}
