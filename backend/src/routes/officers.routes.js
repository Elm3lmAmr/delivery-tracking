'use strict';

const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const { query } = require('../config/database');
const { AppError } = require('../middleware/error');

// List drivers pending review (auto-approved + flagged)
router.get('/queue', verifyToken, requireRole('officer', 'admin'), async (req, res, next) => {
  try {
    const bucket = req.query.bucket || 'auto';
    const threshold = parseInt(process.env.FACE_MATCH_THRESHOLD, 10) || 90;
    let sql;
    if (bucket === 'auto') {
      sql = `SELECT id, full_name, phone, plate_number, face_match_score, created_at, updated_at
             FROM drivers WHERE status = 'verified' AND face_match_score >= ?
             ORDER BY updated_at DESC LIMIT 100`;
    } else {
      sql = `SELECT id, full_name, phone, plate_number, face_match_score, created_at, updated_at
             FROM drivers WHERE status = 'pending' AND (face_match_score < ? OR face_match_score IS NULL)
             ORDER BY created_at DESC LIMIT 100`;
    }
    const rows = await query(sql, [threshold]);
    res.json({ drivers: rows });
  } catch (err) { next(err); }
});

// Get one driver's full submission
router.get('/drivers/:id', verifyToken, requireRole('officer', 'admin'), async (req, res, next) => {
  try {
    const rows = await query(
      `SELECT id, phone, full_name, plate_number, id_doc_path, license_doc_path, selfie_path,
              face_match_score, status, total_deliveries, created_at, approved_at
       FROM drivers WHERE id = ?`,
      [req.params.id]
    );
    if (rows.length === 0) throw new AppError('Driver not found', 404);
    res.json(rows[0]);
  } catch (err) { next(err); }
});

// Approve a driver permanently
router.post('/drivers/:id/approve', verifyToken, requireRole('officer', 'admin'), async (req, res, next) => {
  try {
    await query(
      `UPDATE drivers SET status = 'verified', approved_by = ?, approved_at = NOW() WHERE id = ?`,
      [req.auth.id, req.params.id]
    );
    res.json({ ok: true });
  } catch (err) { next(err); }
});

// Revoke a driver's access
router.post('/drivers/:id/revoke', verifyToken, requireRole('officer', 'admin'), async (req, res, next) => {
  try {
    await query(`UPDATE drivers SET status = 'revoked' WHERE id = ?`, [req.params.id]);
    res.json({ ok: true });
  } catch (err) { next(err); }
});

module.exports = router;
