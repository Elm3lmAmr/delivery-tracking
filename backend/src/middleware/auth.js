'use strict';

const jwt = require('jsonwebtoken');

function verifyToken(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }
  const token = auth.slice(7);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.auth = payload;
    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.auth) return res.status(401).json({ error: 'Not authenticated' });
    if (!roles.includes(req.auth.role)) return res.status(403).json({ error: 'Forbidden' });
    return next();
  };
}

function requireDriver(req, res, next) {
  if (!req.auth || req.auth.type !== 'driver') {
    return res.status(403).json({ error: 'Driver token required' });
  }
  return next();
}

function issueToken(payload, expiresIn) {
  return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: expiresIn || process.env.JWT_EXPIRES_IN || '7d' });
}

module.exports = { verifyToken, requireRole, requireDriver, issueToken };
