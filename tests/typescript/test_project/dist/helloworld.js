"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.greet = greet;
/**
 * Greet someone with an optional name.
 * @param name - Optional name to greet
 * @returns Greeting message
 */
function greet(name) {
    if (name) {
        return `Hello, ${name}!`;
    }
    return 'Hello, World!';
}
console.log(greet());
