/**
 * Tests for the helloworld module.
 */

import { greet } from './helloworld';

describe('greet function', () => {
  test('should return "Hello, World!" when no name is provided', () => {
    expect(greet()).toBe('Hello, World!');
  });

  test('should return "Hello, {name}!" when name is provided', () => {
    expect(greet('Alice')).toBe('Hello, Alice!');
    expect(greet('Bob')).toBe('Hello, Bob!');
  });

  test('should handle empty string', () => {
    expect(greet('')).toBe('Hello, World!');
  });

  test('should handle undefined explicitly', () => {
    expect(greet(undefined)).toBe('Hello, World!');
  });
});


