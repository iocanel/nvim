#!/usr/bin/env node
/**
 * Simple JavaScript hello world program for testing LSP functionality.
 */

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

/**
 * Get some environment information.
 * @returns {object} Environment information object
 */
function getEnvironmentInfo() {
  return {
    nodeVersion: process.version,
    platform: process.platform,
    currentDirectory: process.cwd(),
  };
}

/**
 * Main function.
 */
function main() {
  console.log(greet());
  console.log(greet('JavaScript'));
  
  const envInfo = getEnvironmentInfo();
  console.log(`Running Node.js ${envInfo.nodeVersion} on ${envInfo.platform}`);
}

// Export for testing
module.exports = {
  greet,
  getEnvironmentInfo,
};

// Run main if this is the main module
if (require.main === module) {
  main();
}