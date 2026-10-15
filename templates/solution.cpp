#include <bits/stdc++.h>
using namespace std;

// dbg(a, b, ...) prints "file:line [a = 1, b = 2]" to stderr in builds that define LOCAL
// (`just run`, `just test-debug`, `just stress`). It compiles to nothing on the judge.
#ifdef LOCAL
#define dbg(...) dbg_print(__FILE__, __LINE__, #__VA_ARGS__ __VA_OPT__(, ) __VA_ARGS__)

template <typename... Args>
void dbg_print(string_view file, int line, string_view names, const Args&... args)
{
    file = file.substr(file.find_last_of('/') + 1);
    print(cerr, "{}:{} [", file, line);
    [[maybe_unused]] auto next_name = [&]() {
        int depth = 0;
        char quote = 0;
        size_t i = 0;
        for (; i < names.size(); i++) {
            char c = names[i];
            if (quote) {
                if (c == '\\')
                    i++;
                else if (c == quote)
                    quote = 0;
                continue;
            }
            if (c == '"' || c == '\'') quote = c;
            if (c == '(' || c == '[' || c == '{') depth++;
            if (c == ')' || c == ']' || c == '}') depth--;
            if (c == ',' && depth == 0) break;
        }
        string_view name = names.substr(0, i);
        names.remove_prefix(min(i + 1, names.size()));
        while (!names.empty() && names.front() == ' ') names.remove_prefix(1);
        return name;
    };
    [[maybe_unused]] const char* sep = "";
    ((print(cerr, "{}{} = {}", sep, next_name(), args), sep = ", "), ...);
    println(cerr, "]");
}
#else
// Unevaluated, so the arguments still count as used but cost nothing.
#define dbg(...) ((void)sizeof((__VA_OPT__(__VA_ARGS__, ) 0)))
#endif

// ── Type aliases ──────────────────────────────────────────────────────────────
using i32 = int32_t;
using u32 = uint32_t;
using i64 = int64_t;
using u64 = uint64_t;
using ll = long long;
using ull = unsigned long long;

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    return 0;
}
