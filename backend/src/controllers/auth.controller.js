'use strict';

const bcrypt = require('bcrypt');
const { randomInt } = require('crypto'); // cryptographically secure
const { query } = require('../config/database');
const { issueToken } = require('../middleware/auth');
const { AppError } = require('../middleware/error');

// ---------- Helpers ----------

/**
 * Normalise a phone string: remove all whitespace so that
 * "+20 1118196999" and "+201118196999" map to the same record.
 */
function normalizePhone(phone) {
  return phone.replace(/\s+/g, '');
}

// ---------- Get all gates ----------
async function getGates(req, res, next) {
  try {
    const rows = await query('SELECT id, name FROM gates ORDER BY id');
    res.json(rows);
  } catch (err) { next(err); }
}

// ---------- Backend user login ----------
async function userLogin(req, res, next) {
  try {
    const { email, password, gateId } = req.body;
    if (!email || !password) throw new AppError('Email and password required');
    const rows = await query(
      'SELECT id, email, password_hash, full_name, role, assigned_gate_id, active FROM users WHERE email = ?',
      [email]
    );
    if (rows.length === 0) throw new AppError('Invalid credentials', 401);
    const user = rows[0];
    if (!user.active) throw new AppError('Account disabled', 403);
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) throw new AppError('Invalid credentials', 401);
    await query('UPDATE users SET last_login_at = NOW() WHERE id = ?', [user.id]);
    
    const finalGateId = gateId ? parseInt(gateId, 10) : user.assigned_gate_id;
    
    const token = issueToken({
      id: user.id,
      email: user.email,
      role: user.role,
      gateId: finalGateId,
      type: 'user'
    });
    res.json({
      token,
      user: {
        id: user.id, email: user.email, fullName: user.full_name,
        role: user.role, gateId: finalGateId
      }
    });
  } catch (err) { next(err); }
}

// ---------- Driver OTP request ----------
async function requestOtp(req, res, next) {
  try {
    const rawPhone = req.body.phone;
    if (!rawPhone) throw new AppError('Phone number required', 400);

    const phone = normalizePhone(rawPhone);

    // --- 60-second resend cooldown ---
    const recent = await query(
      'SELECT id FROM otp_codes WHERE phone = ? AND created_at > NOW() - INTERVAL 60 SECOND ORDER BY created_at DESC LIMIT 1',
      [phone]
    );
    if (recent.length > 0) {
      throw new AppError('Please wait 60 seconds before requesting a new code.', 429);
    }

    // Delete any old (expired or unused) codes for this phone
    await query('DELETE FROM otp_codes WHERE phone = ?', [phone]);

    // Generate a cryptographically secure 6-digit code
    const otp = randomInt(100000, 999999).toString();

    // Insert with 5-minute expiry
    await query(
      'INSERT INTO otp_codes (phone, code, attempts, used, expires_at) VALUES (?, ?, 0, 0, NOW() + INTERVAL 5 MINUTE)',
      [phone, otp]
    );

    // --- SMS PROVIDER PLACEHOLDER ---
    // Twilio removed. Replace this block with your telecom bulk-SMS integration
    // when credentials are available.
    console.log('');
    console.log('╔══════════════════════════════════════════════╗');
    console.log('║           📱  OTP CODE  (DEV MODE)           ║');
    console.log(`║   Phone : ${phone.padEnd(33)}║`);
    console.log(`║   Code  : ${otp.padEnd(33)}║`);
    console.log('║   Expires in 5 minutes                       ║');
    console.log('╚══════════════════════════════════════════════╝');
    console.log('');

    res.json({ sent: true, provider: 'log' });
  } catch (err) { next(err); }
}

// ---------- Driver OTP verify ----------
async function verifyOtp(req, res, next) {
  try {
    const rawPhone = req.body.phone;
    const { code } = req.body;
    if (!rawPhone || !code) throw new AppError('Phone number and code required', 400);

    const phone = normalizePhone(rawPhone);

    // Fetch the active (non-expired, non-used) record
    const rows = await query(
      'SELECT * FROM otp_codes WHERE phone = ? AND used = 0 AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
      [phone]
    );

    if (rows.length === 0) {
      throw new AppError('Verification code expired or not found. Please request a new one.', 401);
    }

    const record = rows[0];

    // --- Brute-force protection: max 5 attempts ---
    if (record.attempts >= 5) {
      await query('DELETE FROM otp_codes WHERE id = ?', [record.id]);
      throw new AppError('Too many incorrect attempts. Please request a new code.', 401);
    }

    if (record.code !== code) {
      // Increment attempt counter
      await query('UPDATE otp_codes SET attempts = attempts + 1 WHERE id = ?', [record.id]);
      const remaining = 4 - record.attempts; // record.attempts is before this increment
      throw new AppError(
        `Incorrect code. ${remaining} attempt${remaining !== 1 ? 's' : ''} remaining.`,
        401
      );
    }

    // Mark as used (prevents replay even before cleanup)
    await query('UPDATE otp_codes SET used = 1 WHERE id = ?', [record.id]);
    // Clean up
    await query('DELETE FROM otp_codes WHERE phone = ?', [phone]);

    // Find or create driver record
    const existing = await query('SELECT id, status, full_name FROM drivers WHERE phone = ?', [phone]);
    let driverId;
    let status;
    let fullName;
    if (existing.length > 0) {
      driverId = existing[0].id;
      status = existing[0].status;
      fullName = existing[0].full_name;
    } else {
      const result = await query(
        'INSERT INTO drivers (phone, plate_number, status) VALUES (?, ?, ?)',
        [phone, '', 'verified']
      );
      driverId = result.insertId;
      status = 'verified';
    }

    const token = issueToken(
      { id: driverId, phone, type: 'driver' },
      process.env.DRIVER_JWT_EXPIRES_IN || '30d'
    );
    res.json({ token, driverId, status, fullName });
  } catch (err) { next(err); }
}

module.exports = { userLogin, requestOtp,  verifyOtp,
  getGates
};
