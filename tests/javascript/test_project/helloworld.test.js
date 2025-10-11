/**
 * Tests for the helloworld module.
 */

const { greet, getEnvironmentInfo } = require('./helloworld');

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

  test('should handle null and undefined', () => {
    expect(greet(null)).toBe('Hello, World!');
    expect(greet(undefined)).toBe('Hello, World!');
  });
});

describe('getEnvironmentInfo function', () => {
  test('should return an object with expected properties', () => {
    const info = getEnvironmentInfo();
    
    expect(info).toHaveProperty('nodeVersion');
    expect(info).toHaveProperty('platform');
    expect(info).toHaveProperty('currentDirectory');
    
    expect(typeof info.nodeVersion).toBe('string');
    expect(typeof info.platform).toBe('string');
    expect(typeof info.currentDirectory).toBe('string');
  });

  test('should return valid node version', () => {
    const info = getEnvironmentInfo();
    expect(info.nodeVersion).toMatch(/^v\d+\.\d+\.\d+/);
  });

  test('should return valid platform', () => {
    const info = getEnvironmentInfo();
    expect(['win32', 'darwin', 'linux', 'freebsd', 'openbsd']).toContain(info.platform);
  });
});