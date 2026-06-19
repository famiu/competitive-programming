#include <bits/stdc++.h>
using namespace std;

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    string input;
    if (cin >> input) {
        for (char c : input) {
            if (isdigit(c)) {
                cout << c;
            }
        }
        cout << "\n";
    }

    return 0;
}
