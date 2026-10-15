#include <bits/stdc++.h>
using namespace std;

// Usage: checker <input> <output> <answer>
// <output> is the solution's output and <answer> is the expected output (testlib order).
// Exit 0 to accept; any other exit code rejects, and anything printed is shown as the reason.

[[noreturn]] void reject(const string& reason)
{
    println(cerr, "{}", reason);
    exit(1);
}

int main(int argc, char** argv)
{
    if (argc != 4) reject("usage: checker <input> <output> <answer>");
    ifstream input(argv[1]), output(argv[2]), answer(argv[3]);

    return 0;
}
