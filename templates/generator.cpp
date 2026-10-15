#include <bits/stdc++.h>
using namespace std;

// ── Type aliases ──────────────────────────────────────────────────────────────
using i32 = int32_t;
using u32 = uint32_t;
using i64 = int64_t;
using u64 = uint64_t;
using ll = long long;
using ull = unsigned long long;

// ── Random helpers ────────────────────────────────────────────────────────────
mt19937_64 rng;

// Uniform integer in [lo, hi].
i64 rnd(i64 lo, i64 hi) { return uniform_int_distribution<i64>(lo, hi)(rng); }

// n uniform integers in [lo, hi].
vector<i64> rnd_vec(int n, i64 lo, i64 hi)
{
    vector<i64> v(n);
    for (auto& x : v) x = rnd(lo, hi);
    return v;
}

// Random permutation of first, first + 1, ..., first + n - 1.
vector<int> rnd_perm(int n, int first = 1)
{
    vector<int> p(n);
    iota(p.begin(), p.end(), first);
    shuffle(p.begin(), p.end(), rng);
    return p;
}

// n - 1 edges of a random tree on vertices 1..n, with random labels and edge order.
vector<pair<int, int>> rnd_tree(int n)
{
    vector<int> label = rnd_perm(n);
    vector<pair<int, int>> edges;
    for (int i = 1; i < n; i++) {
        int parent = static_cast<int>(rnd(0, i - 1));
        edges.emplace_back(label[parent], label[i]);
    }
    shuffle(edges.begin(), edges.end(), rng);
    return edges;
}

// String of n characters drawn uniformly from [lo, hi].
string rnd_str(int n, char lo = 'a', char hi = 'z')
{
    string s(n, lo);
    for (auto& c : s) c = static_cast<char>(rnd(lo, hi));
    return s;
}

// `just stress` passes the iteration number as the seed, so every input is reproducible.
int main(int argc, char** argv)
{
    rng.seed(argc >= 2 ? stoull(argv[1]) : 1);

    return 0;
}
