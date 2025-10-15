# Makefile for C test project

CC = gcc
CFLAGS = -Wall -Wextra -g -std=c99

# Main target
TARGET = hello_world
TEST_TARGET = test_helloworld

# Source files
MAIN_SRC = hello_world.c
TEST_SRC = test_helloworld.c

# Default target
all: $(TARGET) $(TEST_TARGET)

# Build main program
$(TARGET): $(MAIN_SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(MAIN_SRC)

# Build test program (needs to link with main source)
$(TEST_TARGET): $(TEST_SRC) $(MAIN_SRC)
	$(CC) $(CFLAGS) -o $(TEST_TARGET) $(TEST_SRC) $(MAIN_SRC) -DTEST_BUILD

# Build main with test mode
test_main: $(MAIN_SRC)
	$(CC) $(CFLAGS) -DTESTING -o test_main $(MAIN_SRC)

# Run tests
test: $(TEST_TARGET) test_main
	./$(TEST_TARGET)
	./test_main

# Clean build artifacts
clean:
	rm -f $(TARGET) $(TEST_TARGET) test_main

# Debug builds
debug: CFLAGS += -DDEBUG
debug: $(TARGET)

debug_test: CFLAGS += -DDEBUG  
debug_test: $(TEST_TARGET)

.PHONY: all test clean debug debug_test