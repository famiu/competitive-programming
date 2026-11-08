#include <bits/stdc++.h>
#include "interactor.hpp"
using namespace std;

void interact()
{
	int n;
	in >> n;
	send(n);
	for (int queries = 0;; queries++) {
		string type;
		sol >> type;
		if (type == "!") {
			// check the answer
			return;
		}
		if (queries == 30) {
			send(-1);
			wrong("too many queries");
		}
		// answer the query
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
