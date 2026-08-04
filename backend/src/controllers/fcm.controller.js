'use strict';

const { query } = require('../config/database');
const { AppError } = require('../middleware/error');

// ---------- Save FCM Token ----------
async function updateFcmToken(req, res, next) {
  try {
    const { token } = req.body;
    if (!token) throw new AppError('FCM token is required', 400);

    const userId = req.auth.id;
    const userType = req.auth.type; // 'user' or 'driver' (set by auth middleware)

    if (userType === 'driver') {
      await query('UPDATE drivers SET fcm_token = ? WHERE id = ?', [token, userId]);
    } else if (userType === 'user') {
      await query('UPDATE users SET fcm_token = ? WHERE id = ?', [token, userId]);
    } else {
      throw new AppError('Invalid user type for FCM token registration', 400);
    }

    res.json({ success: true, message: 'FCM token updated successfully' });
  } catch (err) {
    next(err);
  }
}

module.exports = { updateFcmToken };
