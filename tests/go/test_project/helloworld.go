package main

import (
	"fmt"
	"os"
)

func main() {
	message := "Hello, World!"
	fmt.Println(message) // Breakpoint line for debugging
	
	if len(os.Args) > 1 {
		fmt.Printf("Arguments: %v\n", os.Args[1:])
	}
	
	result := add(5, 3)
	fmt.Printf("5 + 3 = %d\n", result)
}

// add returns the sum of two integers
func add(a, b int) int {
	return a + b // Breakpoint line for function debugging
}