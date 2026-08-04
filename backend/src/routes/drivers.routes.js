'use strict';

const express = require('express');
const router = express.Router();
const controller = require('../controllers/drivers.controller');
const { verifyToken, requireDriver } = require('../middleware/auth');
const { upload, setSubfolder } = require('../middleware/upload');

router.get('/me', verifyToken, requireDriver, controller.getMe);

router.post(
  '/me/documents',
  verifyToken,
  requireDriver,
  setSubfolder('drivers'),
  upload.fields([
    { name: 'id_doc', maxCount: 1 },
    { name: 'license_doc', maxCount: 1 },
    { name: 'selfie', maxCount: 1 }
  ]),
  controller.submitDocuments
);

router.patch('/me/plate', verifyToken, requireDriver, controller.updatePlate);
router.get('/me/deliveries', verifyToken, requireDriver, controller.myDeliveries);

module.exports = router;
