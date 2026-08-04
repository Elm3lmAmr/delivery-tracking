'use strict';

const crypto = require('crypto');

// Generate a signed, one-time QR token
function generateToken() {
  return crypto.randomBytes(24).toString('hex');
}

// Build the payload string encoded into the QR
// Format: EDARA|v1|<token>
function buildPayload(token) {
  return `EDARA|v1|${token}`;
}

// Parse a scanned QR payload
function parsePayload(payload) {
  if (!payload || typeof payload !== 'string') return null;
  const parts = payload.split('|');
  if (parts.length !== 3) return null;
  if (parts[0] !== 'EDARA' || parts[1] !== 'v1') return null;
  return parts[2];
}

module.exports = { generateToken, buildPayload, parsePayload };
