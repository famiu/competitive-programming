#include <bits/stdc++.h>
using namespace std;

using ll = long long;
using u32 = uint32_t;
using u64 = uint64_t;

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int n, k;
	cin >> n >> k;
	vector<int> a(n);
	for (auto& x : a)
		cin >> x;
	int cnt[(int)1e5 + 1]{};
	int l = 0, r = 0, unique = 0;
	ll segments = 0;
	while (r < n) {
		if (cnt[a[r++]]++ == 0)
			unique++;
		while (unique > k)
			if (--cnt[a[l++]] == 0)
				unique--;
		segments += r - l;
	}

	cout << segments << "\n";
}
