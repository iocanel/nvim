#include <stdio.h>
#include <assert.h>

// Math functions to test
int multiply(int a, int b) {
    return a * b;
}

int divide(int a, int b) {
    if (b == 0) return 0; // Simple error handling
    return a / b;
}

int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

// Test functions
int test_multiply() {
    printf("Testing multiply function...\n");
    
    // Test cases
    assert(multiply(2, 3) == 6);
    assert(multiply(0, 5) == 0);
    assert(multiply(-2, 3) == -6);
    assert(multiply(4, -2) == -8);
    
    printf("test_multiply: PASS\n");
    return 1;
}

int test_divide() {
    printf("Testing divide function...\n");
    
    // Test cases
    assert(divide(6, 2) == 3);
    assert(divide(10, 5) == 2);
    assert(divide(7, 3) == 2); // Integer division
    assert(divide(5, 0) == 0); // Error case
    
    printf("test_divide: PASS\n");
    return 1;
}

int test_factorial() {
    printf("Testing factorial function...\n");
    
    // Test cases
    assert(factorial(0) == 1);
    assert(factorial(1) == 1);
    assert(factorial(3) == 6);
    assert(factorial(5) == 120);
    
    printf("test_factorial: PASS\n");
    return 1;
}

int main() {
    printf("Running math tests...\n");
    
    int passed = 0;
    passed += test_multiply();
    passed += test_divide();
    passed += test_factorial();
    
    printf("Tests passed: %d/3\n", passed);
    return passed == 3 ? 0 : 1;
}