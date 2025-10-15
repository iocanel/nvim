#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "hello_world.h"

// Test function
int test_get_hello_message() {
   printf("Testing get_hello_message function...\n");

    const char* result = get_hello_message();
    assert(strcmp(result, "Hello, World!") == 0);

    printf("test_get_hello_message: PASS\n");
    return 1;
}

int main() {
    printf("Running hello world tests...\n");

    int passed = 0;
    passed += test_get_hello_message();

    printf("Tests passed: %d/1\n", passed);
    return passed == 1 ? 0 : 1;
}
