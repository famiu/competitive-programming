#include <bits/stdc++.h>

using namespace std;

int main()
{
    int n, num;
    unordered_set<int> nums;

    cin >> n;

    for (int i = 0; i < n - 1; i++)
    {
        cin >> num;
        nums.insert(num);
    }

    for (int i = 1; i <= n; i++)
    {
        if (nums.find(i) == nums.end())
        {
            cout << i;
            break;
        }
    }
}
