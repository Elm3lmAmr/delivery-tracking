'use strict';

function errorHandler(err, req, res, next) {
  // eslint-disable-line no-unused-vars
  console.error('[edara] error', err);
  const status = err.status || 500;
  const message = err.expose ? err.message : (status === 500 ? 'Internal server error' : err.message);
  const body = { error: message };
  if (process.env.NODE_ENV !== 'production' && err.stack) body.stack = err.stack;
  res.status(status).json(body);
}

class AppError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status || 400;
    this.expose = true;
  }
}

module.exports = errorHandler;
module.exports.AppError = AppError;
