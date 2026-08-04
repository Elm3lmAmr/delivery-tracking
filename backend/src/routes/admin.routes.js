'use strict';

const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const controller = require('../controllers/admin.controller');

router.use(verifyToken, requireRole('admin', 'officer'));

// Dashboard KPIs and live snapshot
router.get('/kpis', controller.getKpis);
router.get('/live-deliveries', controller.getLiveDeliveries);
router.get('/alerts', controller.getAlerts);

// History with filters (project, status, from, to, plate, phone)
router.get('/history', controller.getHistory);

// Drivers list with filters (status, plate, phone)
router.get('/drivers', controller.getDrivers);

// Reports (aggregate data)
router.get('/reports/summary', controller.getReportsSummary);
router.get('/reports/by-project', controller.getReportsByProject);
router.get('/reports/peak-hours', controller.getReportsPeakHours);
router.get('/reports/top-drivers', controller.getReportsTopDrivers);

// Export endpoints (CSV)
router.get('/export/history.csv', controller.exportHistory);
router.get('/export/drivers.csv', controller.exportDrivers);
router.get('/export/reports.csv', controller.exportReports);

module.exports = router;
