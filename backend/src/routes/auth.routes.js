'use strict';

const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const controller = require('../controllers/auth.controller');

const { verifyToken } = require('../middleware/auth');
const fcmController = require('../controllers/fcm.controller');

// Rate limiter: max 5 OTP send attempts per IP per 10 minutes
const otpRequestLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many OTP requests from this IP. Please try again in 10 minutes.' },
});

// Rate limiter: max 10 verify attempts per IP per 10 minutes
const otpVerifyLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many verification attempts from this IP. Please try again in 10 minutes.' },
});

// Backend users (admin/officer/guard) login
router.post('/login', controller.userLogin);

// Driver mobile auth (phone/OTP flow)
router.post('/driver/otp/request', otpRequestLimiter, controller.requestOtp);
router.post('/driver/otp/verify', otpVerifyLimiter, controller.verifyOtp);

// FCM Token registration (works for both users and drivers)
router.put('/fcm-token', verifyToken, fcmController.updateFcmToken);

module.exports = router;
