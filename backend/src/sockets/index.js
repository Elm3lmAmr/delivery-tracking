'use strict';

const jwt = require('jsonwebtoken');

function setupSockets(io) {
  // Authenticate every socket connection
  io.use((socket, next) => {
    const token = socket.handshake.auth && socket.handshake.auth.token;
    if (!token) return next(new Error('Auth token required'));
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      socket.auth = payload;
      return next();
    } catch (err) {
      return next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const { role, id, type } = socket.auth;

    // Admin/officer subscribe to live dashboard events
    if (type === 'user' && (role === 'admin' || role === 'officer')) {
      socket.join('admin');
      socket.emit('connected', { as: role });
    }

    // Guard subscribes to their gate's channel
    if (type === 'user' && role === 'guard') {
      socket.join(`guard:${id}`);
      socket.emit('connected', { as: 'guard' });
    }

    // Driver subscribes to their own delivery updates
    if (type === 'driver') {
      socket.join(`driver:${id}`);
      socket.emit('connected', { as: 'driver' });
    }

    socket.on('disconnect', () => {
      // no-op; joined rooms auto-clear
    });
  });
}

module.exports = setupSockets;
