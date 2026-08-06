'use strict';

const { query } = require('../config/database');
const exportService = require('../services/export.service');

// ---------- KPIs ----------
async function getKpis(req, res, next) {
  try {
    const active = await query(`SELECT COUNT(*) AS n FROM deliveries WHERE status = 'active'`);
    const avgDwell = await query(
      `SELECT COALESCE(AVG(duration_seconds), 0) AS avg_sec FROM deliveries
       WHERE status = 'completed' AND completed_at > NOW() - INTERVAL 24 HOUR`
    );
    const zoneAlerts = await query(
      `SELECT COUNT(*) AS n FROM alerts
       WHERE alert_type = 'restricted_zone' AND resolved_at IS NULL
       AND created_at > NOW() - INTERVAL 24 HOUR`
    );
    const overstay = await query(
      `SELECT COUNT(*) AS n FROM alerts
       WHERE alert_type = 'overstay' AND resolved_at IS NULL
       AND created_at > NOW() - INTERVAL 24 HOUR`
    );
    res.json({
      activeDeliveries: active[0].n,
      avgDwellSeconds: Math.round(avgDwell[0].avg_sec),
      zoneIncursions: zoneAlerts[0].n,
      overstayAlerts: overstay[0].n
    });
  } catch (err) { next(err); }
}

// ---------- Live deliveries ----------
async function getLiveDeliveries(req, res, next) {
  try {
    const { search } = req.query;
    const params = [];
    let where = `WHERE d.status = 'active'`;
    if (search) {
      where += ` AND (dr.phone LIKE ? OR dr.plate_number LIKE ? OR dr.full_name LIKE ?)`;
      const s = `%${search}%`;
      params.push(s, s, s);
    }
    const rows = await query(
      `SELECT d.id, d.entered_at, d.is_offline, d.idle_stage, d.idle_since,
              dr.full_name AS driver, dr.phone, dr.plate_number,
              p.name_en AS project, COALESCE(u.unit_number, d.unit_number_raw) AS unit,
              g.name AS gate,
              TIMESTAMPDIFF(SECOND, d.entered_at, NOW()) AS elapsed_seconds,
              (SELECT lat FROM location_pings lp WHERE lp.delivery_id = d.id ORDER BY lp.recorded_at DESC LIMIT 1) AS lat,
              (SELECT lng FROM location_pings lp WHERE lp.delivery_id = d.id ORDER BY lp.recorded_at DESC LIMIT 1) AS lng
       FROM deliveries d
       JOIN drivers dr ON dr.id = d.driver_id
       JOIN projects p ON p.id = d.project_id
       LEFT JOIN units u ON u.id = d.unit_id
       LEFT JOIN gates g ON g.id = d.gate_id
       ${where}
       ORDER BY d.entered_at DESC LIMIT 100`,
      params
    );
    res.json({ deliveries: rows });
  } catch (err) { next(err); }
}

// ---------- Alerts ----------
async function getAlerts(req, res, next) {
  try {
    const rows = await query(
      `SELECT a.id, a.alert_type, a.severity, a.message, a.created_at, a.resolved_at,
              dr.full_name AS driver
       FROM alerts a
       JOIN deliveries d ON d.id = a.delivery_id
       JOIN drivers dr ON dr.id = d.driver_id
       WHERE a.created_at > NOW() - INTERVAL 24 HOUR
       ORDER BY a.created_at DESC LIMIT 50`
    );
    res.json({ alerts: rows });
  } catch (err) { next(err); }
}

// ---------- History (with filters) ----------
async function fetchHistory(filters) {
  const { search, project_id, status, gate_id, from, to, plate, phone } = filters;
  const params = [];
  let where = `WHERE d.status IN ('completed', 'expired', 'rejected')`;
  if (project_id) { where += ` AND d.project_id = ?`; params.push(project_id); }
  if (status) { where += ` AND d.status = ?`; params.push(status); }
  if (gate_id) { where += ` AND d.gate_id = ?`; params.push(gate_id); }
  if (from) { where += ` AND d.completed_at >= ?`; params.push(from); }
  if (to) { where += ` AND d.completed_at <= ?`; params.push(to); }
  if (plate) { where += ` AND dr.plate_number LIKE ?`; params.push(`%${plate}%`); }
  if (phone) { where += ` AND dr.phone LIKE ?`; params.push(`%${phone}%`); }
  if (search) {
    where += ` AND (dr.phone LIKE ? OR dr.plate_number LIKE ? OR dr.full_name LIKE ?)`;
    const s = `%${search}%`; params.push(s, s, s);
  }
  return query(
    `SELECT d.id, d.status, d.entered_at, d.completed_at, d.duration_seconds,
            dr.full_name AS driver, dr.phone, dr.plate_number,
            p.name_en AS project, COALESCE(u.unit_number, d.unit_number_raw) AS unit,
            g.name AS gate
     FROM deliveries d
     JOIN drivers dr ON dr.id = d.driver_id
     JOIN projects p ON p.id = d.project_id
     LEFT JOIN units u ON u.id = d.unit_id
     LEFT JOIN gates g ON g.id = d.gate_id
     ${where}
     ORDER BY d.completed_at DESC LIMIT 500`,
    params
  );
}

async function getHistory(req, res, next) {
  try { res.json({ deliveries: await fetchHistory(req.query) }); }
  catch (err) { next(err); }
}

// ---------- Drivers (with filters) ----------
async function fetchDrivers(filters) {
  const { search, status, plate, phone } = filters;
  const params = [];
  const wheres = [];
  if (status) { wheres.push(`status = ?`); params.push(status); }
  if (plate) { wheres.push(`plate_number LIKE ?`); params.push(`%${plate}%`); }
  if (phone) { wheres.push(`phone LIKE ?`); params.push(`%${phone}%`); }
  if (search) {
    wheres.push(`(phone LIKE ? OR plate_number LIKE ? OR full_name LIKE ?)`);
    const s = `%${search}%`; params.push(s, s, s);
  }
  const where = wheres.length > 0 ? `WHERE ${wheres.join(' AND ')}` : '';
  return query(
    `SELECT id, full_name, phone, plate_number, status, total_deliveries, last_active_at, created_at,
            id_doc_path, license_doc_path, selfie_path, face_match_score
     FROM drivers ${where} ORDER BY created_at DESC LIMIT 500`,
    params
  );
}

async function getDrivers(req, res, next) {
  try { res.json({ drivers: await fetchDrivers(req.query) }); }
  catch (err) { next(err); }
}

// ---------- Reports ----------
async function getReportsSummary(req, res, next) {
  try {
    const { from, to } = req.query;
    const fromDate = from || `${new Date(Date.now() - 7*24*60*60*1000).toISOString().slice(0,10)}`;
    const toDate = to || `${new Date().toISOString().slice(0,10)}`;
    const [totalRow] = await query(
      `SELECT COUNT(*) AS total FROM deliveries WHERE DATE(created_at) BETWEEN ? AND ?`,
      [fromDate, toDate]
    );
    const [avgRow] = await query(
      `SELECT COALESCE(AVG(duration_seconds), 0) AS avg_sec FROM deliveries
       WHERE status = 'completed' AND DATE(completed_at) BETWEEN ? AND ?`,
      [fromDate, toDate]
    );
    const [alertRow] = await query(
      `SELECT COUNT(*) AS n FROM alerts WHERE DATE(created_at) BETWEEN ? AND ?`,
      [fromDate, toDate]
    );
    const [driverRow] = await query(
      `SELECT COUNT(*) AS n FROM drivers WHERE status = 'verified'`
    );
    res.json({
      period: { from: fromDate, to: toDate },
      totalDeliveries: totalRow.total,
      avgDwellSeconds: Math.round(avgRow.avg_sec),
      totalAlerts: alertRow.n,
      activeDrivers: driverRow.n
    });
  } catch (err) { next(err); }
}

async function getReportsByProject(req, res, next) {
  try {
    const rows = await query(
      `SELECT p.name_en AS project, COUNT(d.id) AS count
       FROM projects p
       LEFT JOIN deliveries d ON d.project_id = p.id AND d.created_at > NOW() - INTERVAL 7 DAY
       GROUP BY p.id, p.name_en ORDER BY count DESC`
    );
    res.json({ rows });
  } catch (err) { next(err); }
}

async function getReportsPeakHours(req, res, next) {
  try {
    const rows = await query(
      `SELECT HOUR(entered_at) AS hour, COUNT(*) AS count
       FROM deliveries WHERE entered_at > NOW() - INTERVAL 24 HOUR
       GROUP BY HOUR(entered_at) ORDER BY hour`
    );
    // Pad to 24 hours
    const counts = new Array(24).fill(0);
    rows.forEach((r) => { counts[r.hour] = r.count; });
    res.json({ hours: counts.map((c, i) => ({ hour: i, count: c })) });
  } catch (err) { next(err); }
}

async function getReportsTopDrivers(req, res, next) {
  try {
    const rows = await query(
      `SELECT full_name, phone, plate_number, total_deliveries
       FROM drivers WHERE status = 'verified'
       ORDER BY total_deliveries DESC LIMIT 10`
    );
    res.json({ drivers: rows });
  } catch (err) { next(err); }
}

// ---------- Exports (CSV) ----------
async function exportHistory(req, res, next) {
  try {
    const rows = await fetchHistory(req.query);
    const csv = exportService.toCsv(rows, [
      { key: 'entered_at', label: 'Entered' },
      { key: 'completed_at', label: 'Completed' },
      { key: 'driver', label: 'Driver' },
      { key: 'phone', label: 'Phone' },
      { key: 'plate_number', label: 'Plate' },
      { key: 'project', label: 'Project' },
      { key: 'unit', label: 'Unit' },
      { key: 'gate', label: 'Gate' },
      { key: 'duration_seconds', label: 'Duration (sec)' },
      { key: 'status', label: 'Status' }
    ]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="edara-history-${Date.now()}.csv"`);
    res.send('\uFEFF' + csv);
  } catch (err) { next(err); }
}

async function exportDrivers(req, res, next) {
  try {
    const rows = await fetchDrivers(req.query);
    const csv = exportService.toCsv(rows, [
      { key: 'full_name', label: 'Name' },
      { key: 'phone', label: 'Phone' },
      { key: 'plate_number', label: 'Plate' },
      { key: 'status', label: 'Status' },
      { key: 'total_deliveries', label: 'Deliveries' },
      { key: 'last_active_at', label: 'Last active' },
      { key: 'created_at', label: 'Registered' }
    ]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="edara-drivers-${Date.now()}.csv"`);
    res.send('\uFEFF' + csv);
  } catch (err) { next(err); }
}

async function exportReports(req, res, next) {
  try {
    const rows = await query(
      `SELECT DATE(d.created_at) AS date, p.name_en AS project,
              COUNT(*) AS deliveries, COALESCE(AVG(d.duration_seconds), 0) AS avg_duration
       FROM deliveries d JOIN projects p ON p.id = d.project_id
       WHERE d.created_at > NOW() - INTERVAL 30 DAY
       GROUP BY DATE(d.created_at), p.id, p.name_en
       ORDER BY date DESC, project`
    );
    const csv = exportService.toCsv(rows, [
      { key: 'date', label: 'Date' },
      { key: 'project', label: 'Project' },
      { key: 'deliveries', label: 'Deliveries' },
      { key: 'avg_duration', label: 'Avg duration (sec)' }
    ]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="edara-reports-${Date.now()}.csv"`);
    res.send('\uFEFF' + csv);
  } catch (err) { next(err); }
}

module.exports = {
  getKpis, getLiveDeliveries, getAlerts,
  getHistory, getDrivers,
  getReportsSummary, getReportsByProject, getReportsPeakHours, getReportsTopDrivers,
  exportHistory, exportDrivers, exportReports
};
