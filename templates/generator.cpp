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

int main(int argc, char** argv)
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    u64 seed = 1;
    if (argc >= 2) {
        seed = stoull(argv[1]);
    }

    mt19937_64 rng(seed);

    return 0;
}
