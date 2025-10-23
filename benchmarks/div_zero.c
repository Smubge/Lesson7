// benchmark_divzero.c
int test_division() {
    int a = 10 / 2;   // Safe, should fold to 5
    int b = 5 / 0;    // No folding!
    return a;
}