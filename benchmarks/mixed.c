// benchmark/mixed.c
int test_mixed(int input) {
    int a = 5 + 3;        // Can fold
    int b = a * input;     // Cannot fold (input is variable)
    int c = 10 / 2;        // Can fold
    return b + c;          // Partially optimized
}