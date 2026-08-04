'use strict';

const express = require('express');
const router = express.Router();

router.use('/auth', require('./auth.routes'));
router.use('/drivers', require('./drivers.routes'));
router.use('/deliveries', require('./deliveries.routes'));
router.use('/guards', require('./guards.routes'));
router.use('/officers', require('./officers.routes'));
router.use('/admin', require('./admin.routes'));

module.exports = router;
