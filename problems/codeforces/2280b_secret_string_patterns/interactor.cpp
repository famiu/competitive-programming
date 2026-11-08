#include <bits/stdc++.h>
#include "interactor.hpp"
using namespace std;

void interact()
{
	int n;
	string marker, s;
	in >> n >> marker >> s;
	if (ssize(s) != n || s.find_first_not_of("01") != string::npos)
		fail("the string must be {} characters of 0 and 1", n);
	vector<int> ones(n + 1);
	for (int i = 0; i < n; i++) ones[i + 1] = ones[i] + (s[i] == '1');

	send(n);
	for (int queries = 0;; queries++) {
		string type;
		sol >> type;
		if (type == "!") {
			bool expected = s.find("01") != string::npos;
			if (sol.yes() != expected) wrong("{}: expected {}", s, expected ? "YES" : "NO");
			return;
		}
		if (type != "?") wrong("expected \"?\" or \"!\", got \"{}\"", type);
		if (queries == 5) {
			send(-1);
			wrong("more than 5 queries");
		}
		int l, r;
		sol >> l >> r;
		if (l < 1 || l > r || r > n) {
			send(-1);
			wrong("invalid query ? {} {} for n = {}", l, r, n);
		}
		send(ones[r] - ones[l - 1]);
	}
}

int main(int argc, char** argv)
{
	init(argc, argv);
	int t = 1;
	in >> t;
	send(t);
	while (t--)
		interact();
}
