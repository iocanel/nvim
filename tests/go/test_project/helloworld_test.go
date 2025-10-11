package main

import (
	"testing"
)

func TestAdd(t *testing.T) {
	tests := []struct {
		name     string
		a, b     int
		expected int
	}{
		{"positive numbers", 5, 3, 8},
		{"with zero", 0, 5, 5},
		{"negative numbers", -2, -3, -5},
		{"mixed signs", -5, 10, 5},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := add(tt.a, tt.b) // Breakpoint line for test debugging
			if result != tt.expected {
				t.Errorf("add(%d, %d) = %d; want %d", tt.a, tt.b, result, tt.expected)
			}
		})
	}
}

func TestMain_Integration(t *testing.T) {
	// This is a simple integration test
	// In a real scenario, you might capture stdout or test main logic
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("main() panicked: %v", r)
		}
	}()
	
	// Test that main doesn't panic
	// Note: This will print to stdout during testing
	main() // Breakpoint line for main integration test
}