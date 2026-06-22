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

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    constexpr u32 MAX_VAL = 500000;
    array<u32, MAX_VAL + 1> spf;
    for (u32 i = 0; i < spf.size(); i++) {
        spf[i] = i;
    }
    spf[0] = 0;
    spf[1] = 1;

    for (u32 i = 2; i <= sqrt_flr(spf.size()); i++) {
        if (spf[i] != i) {
            continue;
        }

        for (u32 j = i * i; j < spf.size(); j += i) {
            if (spf[j] == j)
                spf[j] = i;
        }
    }

    u32 n;
    cin >> n;
    for (u32 i = 0; i < n; i++) {
        u32 num;
        cin >> num;
        u32 num_save = num;

        if (num == 1) {
            cout << "0\n";
            continue;
        }
        if (spf[num] == num) {
            cout << "1\n";
            continue;
        }

        u64 divisor_sum = 1;

        while (num > 1) {
            u32 div = spf[num];

            u32 series_sum = 1;
            u32 div_power = 1;

            while (num % div == 0) {
                num /= div;
                div_power *= div;
                series_sum += div_power;
            }

            divisor_sum *= series_sum;
        }

        divisor_sum -= num_save;
        cout << divisor_sum << "\n";
    }

    return 0;
}
