#include <stdio.h>
#include <string.h>

// Function to greet someone
char* greet(const char* name) {
    static char greeting[256];
    snprintf(greeting, sizeof(greeting), "Hello, %s!", name);
    return greeting;
}

// Function to add two numbers
int add(int a, int b) {
    return a + b;
}

// Function to check if a number is even
int is_even(int n) {
    return n % 2 == 0;
}

int main() {
    printf("Welcome to C Hello World!\n");
    
    char* message = greet("World");
    printf("%s\n", message);
    
    printf("Enter your name: ");
    char name[100];
    if (fgets(name, sizeof(name), stdin)) {
        // Remove newline if present
        name[strcspn(name, "\n")] = '\0';
        
        char* personal_greeting = greet(name);
        printf("%s\n", personal_greeting);
    }
    
    int result = add(5, 3);
    printf("5 + 3 = %d\n", result);
    
    printf("Is 4 even? %s\n", is_even(4) ? "Yes" : "No");
    printf("Is 7 even? %s\n", is_even(7) ? "Yes" : "No");
    
    return 0;
}

// Test functions (would normally be in a separate test file)
#ifdef TESTING
int test_greet() {
    char* result = greet("Alice");
    if (strcmp(result, "Hello, Alice!") == 0) {
        printf("test_greet: PASS\n");
        return 1;
    } else {
        printf("test_greet: FAIL\n");
        return 0;
    }
}

int test_add() {
    if (add(2, 3) == 5 && add(-1, 1) == 0 && add(0, 0) == 0) {
        printf("test_add: PASS\n");
        return 1;
    } else {
        printf("test_add: FAIL\n");
        return 0;
    }
}

int test_is_even() {
    if (is_even(2) && is_even(0) && !is_even(1) && !is_even(3)) {
        printf("test_is_even: PASS\n");
        return 1;
    } else {
        printf("test_is_even: FAIL\n");
        return 0;
    }
}

int main_test() {
    printf("Running tests...\n");
    int passed = 0;
    passed += test_greet();
    passed += test_add();
    passed += test_is_even();
    printf("Tests passed: %d/3\n", passed);
    return passed == 3 ? 0 : 1;
}
#endif