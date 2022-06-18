#include <bits/stdc++.h>

using namespace std;

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(NULL);

    string str;
    cin >> str;

    int longest = 1;

    for (size_t i = 1; i < str.size(); i++)
    {
        int length = 1;

        while (i < str.size() && str[i - 1] == str[i])
        {
            i++;
            length++;
        }

        if (length > longest)
        {
            longest = length;
        }
    }

    cout << longest;
}
