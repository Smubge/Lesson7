// benchmark/dce.c
int test_deadcode() {
    int unused1 = 100 + 200;  // Dead code
    int unused2 = 50 * 2;     // Dead code
    int result = 42;
    return result;             // Should eliminate unused variables
}