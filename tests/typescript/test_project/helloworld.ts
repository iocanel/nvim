/**
 * Greet someone with an optional name.
 * @param name - Optional name to greet
 * @returns Greeting message
 */
function greet(name?: string): string {
 if (name) {
    return `Hello, ${name}!`;
  }
  return 'Hello, World!';
}

// Export for testing
export { greet };

console.log(greet());
console.log(greet("World"));
