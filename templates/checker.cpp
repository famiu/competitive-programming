#include <bits/stdc++.h>
#include "checker.hpp"
using namespace std;

int main(int argc, char** argv)
{
    auto [input, output, answer] = open_files(argc, argv);

    // Typically: read the input and the expected answer, then check that the output is valid
    // and as good as the expected answer.
    auto expected = answer.read<long long>("the answer");
    auto actual = output.read<long long>("the answer");
    ensure(actual == expected, "expected {}, got {}", expected, actual);
    output.expect_eof();
}
