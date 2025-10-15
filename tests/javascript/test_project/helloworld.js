/**
 * Greet someone with an optional name.
 * @param {string} [name] - Optional name to greet
 * @returns {string} Greeting message
 */
function greet(name) {
  if (name) {
    return `Hello, ${name}!`;
  }
  return 'Hello, World!';
}

// Export for testing
module.exports = { greet };

console.log(greet());
console.log(greet("World"));
