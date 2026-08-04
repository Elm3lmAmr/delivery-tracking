'use strict';

const { query } = require('../config/database');
const { AppError } = require('../middleware/error');
const faceMatchService = require('../services/face-match.service');

async function getMe(req, res, next) {
  try {
    const rows = await query(
      `SELECT id, phone, full_name, plate_number, id_doc_path, license_doc_path,
              selfie_path, face_match_score, status, total_deliveries, last_active_at, created_at
       FROM drivers WHERE id = ?`,
      [req.auth.id]
    );
    if (rows.length === 0) throw new AppError('Driver not found', 404);
    res.json(rows[0]);
  } catch (err) { next(err); }
}

async function submitDocuments(req, res, next) {
  try {
    const { plate_number, full_name } = req.body;
    if (!plate_number) throw new AppError('Plate number required');

    const files = req.files || {};
    const idDoc = files.id_doc ? files.id_doc[0] : null;
    const licenseDoc = files.license_doc ? files.license_doc[0] : null;
    const selfie = files.selfie ? files.selfie[0] : null;

    if (!idDoc || !licenseDoc || !selfie) {
      throw new AppError('All 3 photos required: id_doc, license_doc, selfie');
    }

    // Face match: compare selfie against ID document
    const faceMatch = await faceMatchService.compare(idDoc.path, selfie.path);

    // Auto-approve drivers on registration for instant testing & usage
    const autoApprove = true;
    const status = 'verified';
    const approvedAt = new Date();

    await query(
      `UPDATE drivers SET
        full_name = COALESCE(?, full_name),
        plate_number = ?,
        id_doc_path = ?,
        license_doc_path = ?,
        selfie_path = ?,
        face_match_score = ?,
        status = ?,
        approved_at = ?
       WHERE id = ?`,
      [
        full_name || null,
        plate_number.toUpperCase().trim(),
        `/uploads/drivers/${idDoc.filename}`,
        `/uploads/drivers/${licenseDoc.filename}`,
        `/uploads/drivers/${selfie.filename}`,
        faceMatch,
        status,
        approvedAt,
        req.auth.id
      ]
    );

    res.json({
      status,
      autoApproved: autoApprove,
      faceMatchScore: faceMatch,
      message: autoApprove ? 'Approved automatically' : 'Submitted for officer review'
    });
  } catch (err) { next(err); }
}

async function updatePlate(req, res, next) {
  try {
    const { plate_number } = req.body;
    if (!plate_number) throw new AppError('Plate number required');
    await query('UPDATE drivers SET plate_number = ? WHERE id = ?', [plate_number.toUpperCase().trim(), req.auth.id]);
    res.json({ plate_number: plate_number.toUpperCase().trim() });
  } catch (err) { next(err); }
}

async function myDeliveries(req, res, next) {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);
    const rows = await query(
      `SELECT d.id, d.qr_token, d.status, d.entered_at, d.completed_at, d.duration_seconds,
              p.name_en AS project, u.unit_number, g.name AS gate
       FROM deliveries d
       JOIN projects p ON p.id = d.project_id
       LEFT JOIN units u ON u.id = d.unit_id
       LEFT JOIN gates g ON g.id = d.gate_id
       WHERE d.driver_id = ?
       ORDER BY d.created_at DESC LIMIT ?`,
      [req.auth.id, limit]
    );
    res.json({ deliveries: rows });
  } catch (err) { next(err); }
}

module.exports = { getMe, submitDocuments, updatePlate, myDeliveries };
