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
template <typename To, typename From>
constexpr To sc(From&& from) {
    return static_cast<To>(std::forward<From>(from));
}

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    return 0;
}
