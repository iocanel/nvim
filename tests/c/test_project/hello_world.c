#include <stdio.h>
#include <string.h>
#include "hello_world.h"

// Function to return hello world message
const char* get_hello_message() {
    return "Hello, World!";
}

#ifndef TEST_BUILD
int main() {
    printf("%s\n", get_hello_message());
    return 0;
}
#endif
