#include <bits/stdc++.h>
using namespace std;

// ── Type aliases ──────────────────────────────────────────────────────────────
using i32 = int32_t;
using u32 = uint32_t;
using i64 = int64_t;
using u64 = uint64_t;
using ll = long long;
using ull = unsigned long long;
template <typename To, typename From>
constexpr To sc(From&& from) {
    return static_cast<To>(std::forward<From>(from));
}

int main()
{
    constexpr ll MODULO = 1'000'000'007LL;
    constexpr ll inv2 = (MODULO + 1) / 2;
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    ll n;
    cin >> n;

    ll sum = 0;

    for (ll k = 1; k <= n;) {
        ll q = n / k;
        ll k_max = n / q;
        ll count = (k_max - k + 1) % MODULO;

        ll seq_sum = (((k + k_max) % MODULO) * count) % MODULO;
        seq_sum = (seq_sum * inv2) % MODULO;

        ll block_sum = ((q % MODULO) * seq_sum) % MODULO;
        sum = (sum + block_sum) % MODULO;

        k = k_max + 1;
    }

    cout << sum;

    return 0;
}
