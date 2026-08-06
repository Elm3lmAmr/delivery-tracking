'use strict';

const { query, transaction } = require('../config/database');
const { AppError } = require('../middleware/error');
const qrService = require('../services/qr.service');
const geofenceService = require('../services/geofence.service');
const notificationService = require('../services/notificationService');

// ---------- Driver creates delivery + gets QR ----------
async function createDelivery(req, res, next) {
  try {
    const { project_id, unit_number } = req.body;
    if (!project_id || !unit_number) throw new AppError('project_id and unit_number required');

    // Verify driver is verified
    const drv = await query('SELECT id, status, fcm_token FROM drivers WHERE id = ?', [req.auth.id]);
    if (drv.length === 0) throw new AppError('Driver not found', 404);
    if (drv[0].status !== 'verified') throw new AppError('Driver not verified yet', 403);

    // Verify driver does not already have an active or pending delivery
    const existing = await query(
      `SELECT id FROM deliveries WHERE driver_id = ? AND status IN ('pending', 'active')`,
      [req.auth.id]
    );
    if (existing.length > 0) {
      throw new AppError('You cannot create a new delivery while you are already in a trip or have a pending QR.', 403);
    }

    // Verify project exists
    const proj = await query('SELECT id FROM projects WHERE id = ? AND active = 1', [project_id]);
    if (proj.length === 0) throw new AppError('Project not found', 404);

    // Look up unit (nullable - accept raw string if not in catalog)
    const unitRows = await query(
      'SELECT id FROM units WHERE project_id = ? AND unit_number = ? AND active = 1',
      [project_id, unit_number]
    );
    const unitId = unitRows.length > 0 ? unitRows[0].id : null;

    const qrToken = qrService.generateToken();
    const expiryMin = parseInt(process.env.QR_EXPIRY_MINUTES, 10) || 30;

    const result = await query(
      `INSERT INTO deliveries (qr_token, driver_id, project_id, unit_id, unit_number_raw, status, qr_expires_at)
       VALUES (?, ?, ?, ?, ?, 'pending', NOW() + INTERVAL ? MINUTE)`,
      [qrToken, req.auth.id, project_id, unitId, unit_number, expiryMin]
    );

    const io = req.app.get('io');
    if (io) {
      io.to('admin').emit('delivery:created', { deliveryId: result.insertId });
    }

    if (drv[0].fcm_token) {
      notificationService.sendPushNotification(
        drv[0].fcm_token,
        'Delivery Registered',
        'Your QR code has been generated. Please present it at the gate.'
      ).catch(console.error);
    }

    res.json({
      id: result.insertId,
      qrToken,
      qrPayload: qrService.buildPayload(qrToken),
      expiresInMinutes: expiryMin
    });
  } catch (err) { next(err); }
}

// ---------- Guard scans QR -> lookup ----------
async function lookupByToken(req, res, next) {
  try {
    let { qrToken } = req.params;
    if (qrToken && (qrToken.includes('|') || qrToken.includes('%7C'))) {
      const decodedToken = decodeURIComponent(qrToken);
      const parsed = qrService.parsePayload(decodedToken);
      if (parsed) qrToken = parsed;
    }

    const rows = await query(
      `SELECT d.id, d.status, d.qr_expires_at, d.unit_number_raw,
              dr.id AS driver_id, dr.full_name, dr.phone, dr.plate_number, dr.selfie_path, dr.status AS driver_status,
              p.id AS project_id, p.name_en AS project_name, u.unit_number
       FROM deliveries d
       JOIN drivers dr ON dr.id = d.driver_id
       JOIN projects p ON p.id = d.project_id
       LEFT JOIN units u ON u.id = d.unit_id
       WHERE d.qr_token = ?`,
      [qrToken]
    );
    if (rows.length === 0) throw new AppError('QR not found', 404);
    const d = rows[0];
    if (d.status !== 'pending' && d.status !== 'active') throw new AppError('QR already used or expired', 400);
    const mode = d.status === 'pending' ? 'entry' : 'exit';
    if (new Date(d.qr_expires_at) < new Date()) {
      await query('UPDATE deliveries SET status = "expired" WHERE id = ?', [d.id]);
      throw new AppError('QR expired', 400);
    }
    if (d.driver_status !== 'verified') throw new AppError('Driver not verified', 403);
    res.json({
      deliveryId: d.id,
      mode,
      driver: {
        id: d.driver_id, fullName: d.full_name, phone: d.phone,
        plateNumber: d.plate_number, selfiePath: d.selfie_path
      },
      destination: {
        projectId: d.project_id, projectName: d.project_name,
        unitNumber: d.unit_number || d.unit_number_raw
      }
    });
  } catch (err) { next(err); }
}

// ---------- Guard confirms entry ----------
async function confirmEntry(req, res, next) {
  try {
    const deliveryId = parseInt(req.params.id, 10);
    const gateId = req.auth.gateId;
    if (!gateId) throw new AppError('Your account is not assigned to a gate', 403);
    await transaction(async (conn) => {
      const [rows] = await conn.execute('SELECT status FROM deliveries WHERE id = ? FOR UPDATE', [deliveryId]);
      if (rows.length === 0) throw new AppError('Delivery not found', 404);
      if (rows[0].status !== 'pending') throw new AppError('Delivery not in pending state', 400);
      await conn.execute(
        `UPDATE deliveries SET status = 'active', gate_id = ?, scanned_by = ?, entered_at = NOW() WHERE id = ?`,
        [gateId, req.auth.id, deliveryId]
      );
    });

    // Broadcast to admin dashboards via socket
    const io = req.app.get('io');
    io.to('admin').emit('delivery:started', { deliveryId, gateId });

    // Send push notification to driver
    const drvRows = await query(
      'SELECT fcm_token FROM drivers dr JOIN deliveries d ON d.driver_id = dr.id WHERE d.id = ?',
      [deliveryId]
    );
    if (drvRows.length > 0 && drvRows[0].fcm_token) {
      notificationService.sendPushNotification(
        drvRows[0].fcm_token,
        'Access Granted',
        'You may proceed to your destination.'
      ).catch(console.error);
    }

    res.json({ ok: true });
  } catch (err) { next(err); }
}

// ---------- Guard rejects entry ----------
async function rejectEntry(req, res, next) {
  try {
    const deliveryId = parseInt(req.params.id, 10);
    const { reason } = req.body;
    await query(`UPDATE deliveries SET status = 'rejected', scanned_by = ? WHERE id = ? AND status = 'pending'`, [req.auth.id, deliveryId]);
    await query(
      `INSERT INTO alerts (delivery_id, alert_type, severity, message)
       VALUES (?, 'entry_rejected', 'warning', ?)`,
      [deliveryId, reason || 'Rejected by guard']
    );
    res.json({ ok: true });
  } catch (err) { next(err); }
}

// ---------- Guard confirms exit ----------
async function confirmExit(req, res, next) {
  try {
    const deliveryId = parseInt(req.params.id, 10);
    const gateId = req.auth.gateId;
    if (!gateId) throw new AppError('Your account is not assigned to a gate', 403);
    
    let duration = 0;
    
    await transaction(async (conn) => {
      const [rows] = await conn.execute('SELECT status, entered_at FROM deliveries WHERE id = ? FOR UPDATE', [deliveryId]);
      if (rows.length === 0) throw new AppError('Delivery not found', 404);
      if (rows[0].status !== 'active') throw new AppError('Delivery not in active state', 400);
      
      const [durRows] = await conn.execute('SELECT TIMESTAMPDIFF(SECOND, entered_at, NOW()) AS dur FROM deliveries WHERE id = ?', [deliveryId]);
      duration = durRows[0].dur || 0;
      
      await conn.execute(
        `UPDATE deliveries SET status = 'completed', completed_at = NOW(), duration_seconds = ?, exit_gate_id = ?, exit_scanned_by = ? WHERE id = ?`,
        [duration, gateId, req.auth.id, deliveryId]
      );
      
      await conn.execute(
        `INSERT INTO audit_log (actor_type, actor_id, action, target_type, target_id, details) VALUES (?, ?, ?, ?, ?, ?)`,
        ['user', req.auth.id, 'scanned_exit', 'delivery', deliveryId, JSON.stringify({ gateId, duration })]
      );
    });

    const io = req.app.get('io');
    if (io) io.to('admin').emit('delivery:completed', { deliveryId, gateId, duration });

    res.json({ ok: true, duration });
  } catch (err) { next(err); }
}

// ---------- Driver fetches history ----------
async function getDriverHistory(req, res, next) {
  try {
    const driverId = req.auth.id;
    const rows = await query(
      `SELECT d.id, d.status, d.created_at, d.duration_seconds, d.unit_number_raw,
              p.name_en AS project_name, u.unit_number
       FROM deliveries d
       JOIN projects p ON p.id = d.project_id
       LEFT JOIN units u ON u.id = d.unit_id
       WHERE d.driver_id = ? AND d.status IN ('completed', 'rejected', 'expired')
       ORDER BY d.created_at DESC
       LIMIT 50`,
      [driverId]
    );
    
    const history = rows.map(r => ({
      id: r.id,
      status: r.status,
      date: r.created_at,
      durationSeconds: r.duration_seconds,
      project: r.project_name,
      unit: r.unit_number || r.unit_number_raw
    }));

    res.json(history);
  } catch (err) { next(err); }
}

// ---------- Driver posts location ping ----------
async function postPing(req, res, next) {
  try {
    const deliveryId = parseInt(req.params.id, 10);
    const { lat, lng, accuracy_m, speed_kmh } = req.body;
    if (typeof lat !== 'number' || typeof lng !== 'number') {
      throw new AppError('lat and lng must be numbers');
    }
    // Verify delivery belongs to this driver and is active
    const rows = await query(
      'SELECT id, project_id, status, is_offline FROM deliveries WHERE id = ? AND driver_id = ?',
      [deliveryId, req.auth.id]
    );
    if (rows.length === 0) throw new AppError('Delivery not found', 404);
    if (rows[0].status !== 'active' && rows[0].status !== 'pending') {
      throw new AppError('Delivery not active or pending', 400);
    }

    await query(
      'INSERT INTO location_pings (delivery_id, lat, lng, accuracy_m, speed_kmh) VALUES (?, ?, ?, ?, ?)',
      [deliveryId, lat, lng, accuracy_m || null, speed_kmh || null]
    );

    // If driver was offline, they are back online
    if (rows[0].is_offline) {
      await query('UPDATE deliveries SET is_offline = 0 WHERE id = ?', [deliveryId]);
      await query('UPDATE alerts SET resolved_at = NOW() WHERE delivery_id = ? AND alert_type = "no_gps" AND resolved_at IS NULL', [deliveryId]);
      const io = req.app.get('io');
      if (io) {
        io.to('admin').emit('delivery:online', { deliveryId, isOffline: false });
      }
    }

    // Check geofence
    const alerts = await geofenceService.checkPing({
      deliveryId, projectId: rows[0].project_id, lat, lng
    });

    // Broadcast live location to admin
    const io = req.app.get('io');
    io.to('admin').emit('delivery:ping', { deliveryId, lat, lng });
    if (alerts.length > 0) {
      alerts.forEach((a) => io.to('admin').emit('delivery:alert', a));
    }

    res.json({ ok: true, alerts });
  } catch (err) { next(err); }
}

// ---------- Driver fetches active delivery ----------
async function getActiveDelivery(req, res, next) {
  try {
    const driverId = req.auth.id;
    const rows = await query(
      `SELECT d.id, d.status, d.qr_token, d.unit_number_raw,
              p.name_en AS project_name, u.unit_number
       FROM deliveries d
       JOIN projects p ON p.id = d.project_id
       LEFT JOIN units u ON u.id = d.unit_id
       WHERE d.driver_id = ? AND d.status IN ('pending', 'active')
       ORDER BY d.created_at DESC LIMIT 1`,
      [driverId]
    );

    if (rows.length === 0) {
      return res.json(null);
    }
    
    const r = rows[0];
    res.json({
      deliveryId: r.id,
      status: r.status,
      qrToken: r.qr_token,
      qrPayload: qrService.buildPayload(r.qr_token),
      project: r.project_name,
      unit: r.unit_number || r.unit_number_raw
    });
  } catch (err) { next(err); }
}

module.exports = { createDelivery, lookupByToken, confirmEntry, rejectEntry, postPing, confirmExit, getDriverHistory, getActiveDelivery };
