'use strict';

const { query } = require('../config/database');

// Ray-casting point-in-polygon algorithm
function pointInPolygon(point, polygon) {
  const [x, y] = point;
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const [xi, yi] = polygon[i];
    const [xj, yj] = polygon[j];
    const intersect = ((yi > y) !== (yj > y)) &&
      (x < (xj - xi) * (y - yi) / (yj - yi + 0.0000001) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

// Haversine distance in meters
function distanceMeters(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const toRad = (d) => d * Math.PI / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat/2)**2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng/2)**2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

// Check a ping against restricted zones and overstay rules
async function checkPing({ deliveryId, projectId, lat, lng }) {
  const alerts = [];

  // Load restricted zones for this project
  const zones = await query(
    `SELECT id, name, polygon FROM restricted_zones WHERE project_id = ? AND active = 1`,
    [projectId]
  );

  for (const zone of zones) {
    let polygonRaw = zone.polygon;
    if (typeof polygonRaw === 'string') polygonRaw = JSON.parse(polygonRaw);
    if (!polygonRaw || !polygonRaw.coordinates) continue;

    // GeoJSON polygons: coordinates[0] is the outer ring, points are [lng, lat]
    const ring = polygonRaw.coordinates[0].map(([lng2, lat2]) => [lng2, lat2]);
    if (pointInPolygon([lng, lat], ring)) {
      // Check we didn't already alert on this in the last 5 minutes
      const recent = await query(
        `SELECT id FROM alerts WHERE delivery_id = ? AND alert_type = 'restricted_zone'
         AND created_at > NOW() - INTERVAL 5 MINUTE LIMIT 1`,
        [deliveryId]
      );
      if (recent.length === 0) {
        const result = await query(
          `INSERT INTO alerts (delivery_id, alert_type, severity, message, lat, lng)
           VALUES (?, 'restricted_zone', 'warning', ?, ?, ?)`,
          [deliveryId, `Entered restricted zone: ${zone.name}`, lat, lng]
        );
        alerts.push({
          id: result.insertId, deliveryId, type: 'restricted_zone',
          severity: 'warning', message: `Entered ${zone.name}`
        });
      }
    }
  }

  // Overstay check (delivery active for more than SLA)
  const [row] = await query(
    `SELECT TIMESTAMPDIFF(SECOND, entered_at, NOW()) AS elapsed FROM deliveries WHERE id = ?`,
    [deliveryId]
  );
  const slaSec = (parseInt(process.env.DEFAULT_SLA_MINUTES, 10) || 20) * 60;
  const warningSec = slaSec - (5 * 60);

  if (row) {
    if (row.elapsed > slaSec) {
      const recent = await query(
        `SELECT id FROM alerts WHERE delivery_id = ? AND alert_type = 'overstay' LIMIT 1`,
        [deliveryId]
      );
      if (recent.length === 0) {
        const result = await query(
          `INSERT INTO alerts (delivery_id, alert_type, severity, message)
           VALUES (?, 'overstay', 'critical', ?)`,
          [deliveryId, `Delivery over SLA (${Math.round(row.elapsed / 60)}m)`]
        );
        alerts.push({
          id: result.insertId, deliveryId, type: 'overstay',
          severity: 'critical', message: 'Overstay > SLA'
        });

        // Push notification for overstay
        const drvRows = await query(
          'SELECT fcm_token FROM drivers dr JOIN deliveries d ON d.driver_id = dr.id WHERE d.id = ?',
          [deliveryId]
        );
        if (drvRows.length > 0 && drvRows[0].fcm_token) {
          const notificationService = require('./notificationService');
          notificationService.sendPushNotification(
            drvRows[0].fcm_token,
            'Time Limit Exceeded',
            `You have exceeded the allowed delivery time. Please exit the premises immediately.`
          ).catch(console.error);
        }
      }
    } else if (row.elapsed >= warningSec) {
      const recentWarning = await query(
        `SELECT id FROM alerts WHERE delivery_id = ? AND alert_type = 'overstay_warning' LIMIT 1`,
        [deliveryId]
      );
      if (recentWarning.length === 0) {
        await query(
          `INSERT INTO alerts (delivery_id, alert_type, severity, message)
           VALUES (?, 'overstay_warning', 'warning', ?)`,
          [deliveryId, `5 minutes left until SLA limit.`]
        );
        
        // Push notification for warning
        const drvRows = await query(
          'SELECT fcm_token FROM drivers dr JOIN deliveries d ON d.driver_id = dr.id WHERE d.id = ?',
          [deliveryId]
        );
        if (drvRows.length > 0 && drvRows[0].fcm_token) {
          const notificationService = require('./notificationService');
          notificationService.sendPushNotification(
            drvRows[0].fcm_token,
            'Time Limit Approaching',
            'You have 5 minutes left to complete your delivery and exit the premises.'
          ).catch(console.error);
        }
      }
    }
  }

  return alerts;
}

module.exports = { pointInPolygon, distanceMeters, checkPing };
