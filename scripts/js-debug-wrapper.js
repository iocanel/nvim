#!/usr/bin/env node
// Wrapper for dapDebugServer.js that outputs just the port number
// Required because nvim-dap-vscode-js expects only the port on stdout,
// but the new dapDebugServer.js outputs "Debug server listening at ::1:<port>"

const { spawn } = require('child_process');
const path = require('path');

const dataDir = process.env.XDG_DATA_HOME || path.join(process.env.HOME, '.local/share');
const dapServer = path.join(dataDir, 'nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js');

// Pass port 0 and host 127.0.0.1 to force IPv4
const child = spawn('node', [dapServer, '0', '127.0.0.1'], {
  stdio: ['inherit', 'pipe', 'pipe']
});

let portSent = false;

child.stdout.on('data', (data) => {
  const output = data.toString();
  if (!portSent) {
    // Extract port from "Debug server listening at ::1:PORT" or "Debug server listening at 127.0.0.1:PORT"
    const match = output.match(/:(\d+)\s*$/);
    if (match) {
      process.stdout.write(match[1] + '\n');
      portSent = true;
    }
  }
});

child.stderr.on('data', (data) => {
  process.stderr.write(data);
});

child.on('close', (code) => {
  process.exit(code);
});

process.on('SIGTERM', () => child.kill('SIGTERM'));
process.on('SIGINT', () => child.kill('SIGINT'));
