'use strict';

const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const { query } = require('../config/database');

// Get current guard's shift info
router.get('/me', verifyToken, requireRole('guard'), async (req, res, next) => {
  try {
    const rows = await query(
      `SELECT u.id, u.full_name, u.email, g.id AS gate_id, g.name AS gate_name, g.code AS gate_code,
              p.name_en AS project_name
       FROM users u
       LEFT JOIN gates g ON g.id = u.assigned_gate_id
       LEFT JOIN projects p ON p.id = g.project_id
       WHERE u.id = ?`,
      [req.auth.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Guard not found' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});

// Today's stats for the current guard
router.get('/me/stats', verifyToken, requireRole('guard'), async (req, res, next) => {
  try {
    const gateId = req.auth.gateId;
    if (!gateId) return res.json({ scanned: 0, rejected: 0 });
    const scanned = await query(
      `SELECT COUNT(*) AS n FROM deliveries WHERE scanned_by = ? AND DATE(entered_at) = CURDATE()`,
      [req.auth.id]
    );
    const rejected = await query(
      `SELECT COUNT(*) AS n FROM deliveries WHERE scanned_by = ? AND status = 'rejected' AND DATE(created_at) = CURDATE()`,
      [req.auth.id]
    );
    res.json({ scanned: scanned[0].n, rejected: rejected[0].n });
  } catch (err) { next(err); }
});

module.exports = router;
