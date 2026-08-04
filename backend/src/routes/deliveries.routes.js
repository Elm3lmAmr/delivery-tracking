'use strict';

const express = require('express');
const router = express.Router();
const controller = require('../controllers/deliveries.controller');
const { verifyToken, requireDriver, requireRole } = require('../middleware/auth');

// Driver creates a new delivery (generates QR)
router.post('/', verifyToken, requireDriver, controller.createDelivery);

// Driver posts location pings during active delivery
router.post('/:id/pings', verifyToken, requireDriver, controller.postPing);

// Guard scans QR to look up delivery
router.get('/by-token/:qrToken', verifyToken, requireRole('guard', 'admin', 'officer'), controller.lookupByToken);

// Guard confirms entry (starts tracking)
router.post('/:id/confirm-entry', verifyToken, requireRole('guard'), controller.confirmEntry);

// Guard rejects entry
router.post('/:id/reject', verifyToken, requireRole('guard'), controller.rejectEntry);

// Guard confirms exit
router.post('/:id/confirm-exit', verifyToken, requireRole('guard'), controller.confirmExit);

// Driver fetches history
router.get('/history', verifyToken, requireDriver, controller.getDriverHistory);

module.exports = router;
