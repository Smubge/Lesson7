// benchmark/arithmetic.c
int test_arithmetic() {
    int x = 10 + 20;
    int y = x * 3;
    int z = y - 15;
    int w = z / 5;
    return w;  // Should fold to: return 9
}