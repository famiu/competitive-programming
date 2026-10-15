#include <bits/stdc++.h>
using namespace std;

using ll = long long;
using u32 = uint32_t;
using u64 = uint64_t;

int main()
{
    cin.tie(nullptr)->sync_with_stdio(false);

    int n;
    ll s;
    cin >> n >> s;
    vector<int> a(n);
    for (auto& x : a)
        cin >> x;

    int l = 0, r = 0, shortest = -1;
    ll seg_sum = 0;
    while (true) {
        while (seg_sum < s && r < n)
            seg_sum += a[r++];
        if (seg_sum < s)
            break;
        shortest = shortest == -1 ? (r - l) : min(shortest, r - l);
        seg_sum -= a[l++];
    }

    cout << shortest << "\n";
}
