# D. Portal

**Time limit:** 2 s | **Memory limit:** 256 MB | **Platform:** Codeforces

---

You are given a permutation$$$^{\text{∗}}$$$ $$$p$$$ of length $$$n$$$. There are also two portals located at positions $$$x$$$ and $$$y$$$ ($$$x \lt y$$$).

A portal at position $$$i$$$ is initially located between the $$$i$$$-th and $$$(i+1)$$$-th elements of the array. Specifically, if $$$i=0$$$, then the portal is located before the first element of the array, and if $$$i=n$$$, then the portal is located after the last element.

You may perform either of the following two operations as many times as you like:

1. Remove the element to the immediate left of one portal and insert it to the immediate right of the other portal.
2. Remove the element to the immediate right of one portal and insert it to the immediate left of the other portal.

Let $$$\mathbf{\color{red}{\mathcal{O}}}$$$ denote a portal. For example, if $$$p$$$ is $$$[3,\mathbf{\color{red}{\mathcal{O}}},2,4,\mathbf{\color{red}{\mathcal{O}}},1]$$$:

* Using operation $$$1$$$ on the left and right portals respectively results in the arrays $$$[\mathbf{\color{red}{\mathcal{O}}},2,4,\mathbf{\color{red}{\mathcal{O}}},3,1]$$$ and $$$[3,\mathbf{\color{red}{\mathcal{O}}},4,2,\mathbf{\color{red}{\mathcal{O}}},1]$$$.
* Using operation $$$2$$$ on the left and right portals respectively results in the arrays $$$[3,\mathbf{\color{red}{\mathcal{O}}},4,2,\mathbf{\color{red}{\mathcal{O}}},1]$$$ and $$$[3,1,\mathbf{\color{red}{\mathcal{O}}},2,4,\mathbf{\color{red}{\mathcal{O}}}]$$$.

Find the lexicographically$$$^{\text{†}}$$$ smallest permutation you can obtain using these operations. Note that portals do not affect the lexicographical comparison of permutations.

$$$^{\text{∗}}$$$A permutation of length $$$n$$$ is an array of length $$$n$$$ containing each integer from $$$1$$$ to $$$n$$$ exactly once.

$$$^{\text{†}}$$$A permutation $$$a$$$ is lexicographically smaller than permutation $$$b$$$ if there exists an index $$$i$$$ such that $$$a_j = b_j$$$ for all indices $$$1 \leq j  \lt  i$$$ and $$$a_i  \lt  b_i$$$.

## Input

The first line contains an integer $$$t$$$ ($$$1 \leq t \leq 2\cdot 10^4$$$) — the number of test cases.

For each test case, the first line contains three integers $$$n$$$, $$$x$$$, and $$$y$$$ ($$$1 \leq n \leq 2 \cdot 10^5$$$, $$$0 \leq x  \lt  y \leq n$$$).

The second line of each test case contains $$$n$$$ integers $$$p_1, p_2, \dots, p_n$$$ — a permutation of length $$$n$$$.

The sum of $$$n$$$ over all test cases does not exceed $$$2 \cdot 10^5$$$.

## Output

For each test case, output a line with $$$n$$$ integers — the lexicographically smallest permutation you can obtain.

## Note

Let $$$\mathbf{\color{red}{\mathcal{O}}}$$$ denote a portal.

In the first test case, the array is $$$[\mathbf{\color{red}{\mathcal{O}}},3,1,4,2,\mathbf{\color{red}{\mathcal{O}}}]$$$. Using operation $$$2$$$ on the left portal results in $$$[\mathbf{\color{red}{\mathcal{O}}},1,4,2,3,\mathbf{\color{red}{\mathcal{O}}}]$$$, which is the lexicographically smallest possible permutation that can be obtained.

 ![](https://espresso.codeforces.com/4fbd30acf0c22c9754f099bbb7b68469b802097a.gif) The operation described above. 

In the second test case, the array is $$$[3,\mathbf{\color{red}{\mathcal{O}}},2,\mathbf{\color{red}{\mathcal{O}}},1]$$$. Using operation $$$1$$$ on the left portal results in $$$[\mathbf{\color{red}{\mathcal{O}}},2,\mathbf{\color{red}{\mathcal{O}}},3,1]$$$, which is the lexicographically smallest possible permutation that can be obtained.

In the fourth test case, it is optimal not to do any operations.

## Examples

### Example 1

**Input:**

```
4
4 0 4
3 1 4 2
3 1 2
3 2 1
5 1 3
1 3 5 2 4
2 0 1
1 2
```

**Output:**

```
1 4 2 3
2 3 1
1 2 3 5 4
1 2
```

---

*Source: [Codeforces](https://codeforces.com/problemset/problem/2200/D)*