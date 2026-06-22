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

static constexpr inline u32 sqrt_flr(u32 n)
{
    return static_cast<u32>(sqrt(n));
}

static constexpr u32 gcd(u32 a, u32 b) {
    while (b != 0) {
        u32 temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    constexpr u32 MAX_VAL = 1000000;
    bitset<MAX_VAL + 1> sieve;
    sieve.set();
    sieve[0] = sieve[1] = false;

    for (u32 i = 2; i <= sqrt_flr(sieve.size()); i++) {
        if (!sieve[i]) {
            continue;
        }

        for (u32 j = i * i; j < sieve.size(); j += i) {
            sieve[j] = false;
        }
    }

    u32 n;
    cin >> n;

    for (u32 i = 0; i < n; i++) {
        u32 a, b;
        cin >> a >> b;

        u32 g = a > b ? gcd(a, b) : gcd(b, a);

        if (g == 1) {
            cout << "1\n";
            continue;
        }
        if (sieve[g]) {
            cout << "2\n";
            continue;
        }

        u32 divisors = 1;
        for (u32 j = 2; j <= sqrt_flr(g); j++) {
            if (!sieve[j])
                continue;

            u32 exp = 0;
            while (g % j == 0) {
                g /= j;
                exp++;
            }
            divisors *= exp + 1;
        }
        if (g > 1) {
            divisors *= 2;
        }

        cout << divisors << "\n";
    }

    return 0;
}
