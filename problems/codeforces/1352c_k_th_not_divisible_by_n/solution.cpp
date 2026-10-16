#include <bits/stdc++.h>
using namespace std;

using ll = long long;
using u32 = uint32_t;
using u64 = uint64_t;

int main()
{
	cin.tie(nullptr)->sync_with_stdio(false);

	int t;
	cin >> t;
	for (int i = 0; i < t; ++i) {
		ll n, k;
		cin >> n >> k;

		// Split the integers into blocks of n; each block holds n-1 non-multiples.
		// k-1 non-multiples come before the target. Split them into:
		//   q = full blocks before the target
		//   r = non-multiples before the target inside its own block
		// Therefore, (n-1) * q + r = k-1, giving q = (k-1) / (n-1) and r = (k-1) % (n-1).
		// Each block corresponds to n integers, so target = q * n + r + 1.
		auto [q, r] = div(k - 1, n - 1);
		cout << q * n + r + 1 << "\n";
	}
}
