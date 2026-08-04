'use strict';

require('dotenv').config();

const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const rateLimit = require('express-rate-limit');
const { Server: SocketIOServer } = require('socket.io');

const { testConnection } = require('./config/database');
const routes = require('./routes');
const errorHandler = require('./middleware/error');
const setupSockets = require('./sockets');

const app = express();
const server = http.createServer(app);

// ---------- Security & parsing middleware ----------
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true, limit: '2mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ---------- Rate limiting ----------
const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, slow down.' }
});
app.use(globalLimiter);

// ---------- Static file serving for uploaded docs ----------
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// ---------- Health check ----------
app.get('/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString(), version: '1.0.0' });
});

// ---------- API routes ----------
app.use('/api/v1', routes);

// ---------- Error handler (last) ----------
app.use((req, res) => res.status(404).json({ error: 'Not found' }));
app.use(errorHandler);

// ---------- Socket.IO for live tracking ----------
const io = new SocketIOServer(server, {
  cors: { origin: process.env.CORS_ORIGIN || '*', credentials: true }
});
setupSockets(io);
app.set('io', io);

// ---------- Boot ----------
const PORT = parseInt(process.env.PORT, 10) || 4000;

async function boot() {
  try {
    await testConnection();
    console.log('[edara] database connected');
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`[edara] api listening on http://0.0.0.0:${PORT}`);
      console.log(`[edara] health: http://localhost:${PORT}/health`);
    });
  } catch (err) {
    console.error('[edara] boot failed', err);
    process.exit(1);
  }
}

process.on('unhandledRejection', (reason) => console.error('[edara] unhandled rejection', reason));
process.on('uncaughtException', (err) => { console.error('[edara] uncaught exception', err); process.exit(1); });

boot();
