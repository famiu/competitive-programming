// Helpers for stress-test generators. Call seed(argc, argv) first: `just stress` passes the
// iteration number as the seed, so every input is reproducible.
#pragma once

#include <bits/stdc++.h>
#include <cassert>

inline std::mt19937_64 rng(1);

inline void seed(int argc, char** argv) { rng.seed(argc >= 2 ? std::stoull(argv[1]) : 1); }

// Uniform value in [lo, hi], integer or floating-point depending on the arguments.
template <class A, class B>
std::common_type_t<A, B> rnd(A lo, B hi)
{
    using T = std::common_type_t<A, B>;
    assert(lo <= hi);
    if constexpr (std::is_floating_point_v<T>) {
        return std::uniform_real_distribution<T>(lo, hi)(rng);
    } else {
        // uniform_int_distribution does not accept char types.
        using D = std::conditional_t<(sizeof(T) < sizeof(int)), int, T>;
        return static_cast<T>(std::uniform_int_distribution<D>(lo, hi)(rng));
    }
}

// n uniform values in [lo, hi].
template <class A, class B>
std::vector<std::common_type_t<A, B>> rnd_vec(int n, A lo, B hi)
{
    std::vector<std::common_type_t<A, B>> v(n);
    for (auto& x : v) x = rnd(lo, hi);
    return v;
}

// n distinct integers in [lo, hi], in random order.
template <class A, class B>
std::vector<std::common_type_t<A, B>> rnd_distinct(int n, A lo, B hi)
{
    using T = std::common_type_t<A, B>;
    assert(n >= 0 && static_cast<long double>(hi) - lo + 1 >= n);
    std::vector<T> v;
    if (static_cast<long double>(hi) - lo + 1 <= 4.0L * n) {
        for (T x = lo;; x++) {
            v.push_back(x);
            if (x == hi) break;
        }
        std::shuffle(v.begin(), v.end(), rng);
        v.resize(n);
    } else {
        std::set<T> seen;
        while (static_cast<int>(v.size()) < n)
            if (T x = rnd(lo, hi); seen.insert(x).second) v.push_back(x);
    }
    return v;
}

// Random permutation of first, first + 1, ..., first + n - 1.
inline std::vector<int> rnd_perm(int n, int first = 1)
{
    std::vector<int> p(n);
    std::iota(p.begin(), p.end(), first);
    std::shuffle(p.begin(), p.end(), rng);
    return p;
}

// Uniformly chosen element of a non-empty container.
template <class C>
const auto& pick(const C& c)
{
    assert(!std::ranges::empty(c));
    return *std::ranges::next(std::ranges::begin(c), rnd(0, static_cast<int>(std::ranges::size(c)) - 1));
}

// String of n characters drawn from `alphabet`. Small alphabets such as "ab" find bugs faster.
inline std::string rnd_str(int n, std::string_view alphabet = "abcdefghijklmnopqrstuvwxyz")
{
    std::string s(n, ' ');
    for (auto& c : s) c = pick(alphabet);
    return s;
}

// n - 1 edges of a random tree on vertices 1..n, with random labels and edge order.
inline std::vector<std::pair<int, int>> rnd_tree(int n)
{
    std::vector<int> label = rnd_perm(n);
    std::vector<std::pair<int, int>> edges;
    for (int i = 1; i < n; i++) {
        int u = label[rnd(0, i - 1)], v = label[i];
        edges.emplace_back(rnd(0, 1) ? std::pair(u, v) : std::pair(v, u));
    }
    std::shuffle(edges.begin(), edges.end(), rng);
    return edges;
}

// m edges of a random simple undirected graph on vertices 1..n (no self-loops or repeated
// edges). With `connected`, the graph is connected, which needs m >= n - 1.
inline std::vector<std::pair<int, int>> rnd_graph(int n, int m, bool connected = false)
{
    assert(m <= static_cast<long long>(n) * (n - 1) / 2 && (!connected || m >= n - 1));
    std::vector<std::pair<int, int>> edges = connected ? rnd_tree(n) : std::vector<std::pair<int, int>>{};
    std::set<std::pair<int, int>> seen;
    for (auto [u, v] : edges) seen.emplace(std::min(u, v), std::max(u, v));
    while (static_cast<int>(edges.size()) < m) {
        int u = rnd(1, n), v = rnd(1, n);
        if (u != v && seen.emplace(std::min(u, v), std::max(u, v)).second) edges.emplace_back(u, v);
    }
    std::shuffle(edges.begin(), edges.end(), rng);
    return edges;
}

namespace gen_detail {

template <class T>
void put(std::string& line, const T& value)
{
    if constexpr (std::ranges::input_range<T> && !std::convertible_to<T, std::string_view>) {
        for (const auto& element : value) put(line, element);
    } else {
        if (!line.empty()) line += ' ';
        std::format_to(std::back_inserter(line), "{}", value);
    }
}

}  // namespace gen_detail

// Prints the arguments on one line, separated by spaces. Containers are flattened, so
// out(n, v) prints n followed by the elements of v.
template <class... Args>
void out(const Args&... args)
{
    std::string line;
    (gen_detail::put(line, args), ...);
    line += '\n';
    std::fputs(line.c_str(), stdout);
}

// Prints one "u v" line per edge.
inline void out_edges(const std::vector<std::pair<int, int>>& edges)
{
    for (auto [u, v] : edges) out(u, v);
}
