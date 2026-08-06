const { query, transaction } = require('../config/database');
const { sendPushNotification } = require('./notificationService');

let intervalId = null;

function startIdleMonitor(io) {
  if (intervalId) return;

  // Run every 1 minute
  intervalId = setInterval(async () => {
    try {
      // Find active deliveries that are NOT marked offline by the connection monitor
      // We don't want to double penalize someone who lost connection.
      const rows = await query(`
        SELECT d.id, d.idle_since, d.idle_stage, d.is_offline, dr.fcm_token, dr.full_name, dr.id as driver_id
        FROM deliveries d
        JOIN drivers dr ON dr.id = d.driver_id
        WHERE d.status = 'active' AND d.is_offline = 0
      `);

      for (const d of rows) {
        // Fetch pings in the last 2 minutes
        const pings = await query(`
          SELECT lat, lng 
          FROM location_pings 
          WHERE delivery_id = ? AND recorded_at >= NOW() - INTERVAL 2 MINUTE
        `, [d.id]);

        // Need at least 2 pings in the last 2 minutes to determine if they moved
        if (pings.length >= 2) {
          const lats = pings.map(p => p.lat);
          const lngs = pings.map(p => p.lng);
          const latDiff = Math.max(...lats) - Math.min(...lats);
          const lngDiff = Math.max(...lngs) - Math.min(...lngs);

          // Threshold for 15 meters is ~0.00015 degrees
          const isStationary = (latDiff < 0.00015 && lngDiff < 0.00015);

          if (isStationary) {
            let idleSince = d.idle_since;
            if (!idleSince) {
              // Just detected they are stationary for the whole 2 min window, so they've been idle for 2 mins now.
              // We set idle_since to 2 minutes ago.
              idleSince = new Date(Date.now() - 2 * 60000);
              await query(`UPDATE deliveries SET idle_since = ? WHERE id = ?`, [idleSince, d.id]);
            }

            const idleMinutes = Math.floor((Date.now() - idleSince.getTime()) / 60000);

            // STAGE 1: 2 minutes
            if (idleMinutes >= 2 && d.idle_stage < 1) {
              await triggerIdleStage(d, 1, idleMinutes, io);
            } 
            // STAGE 2: 7 minutes
            else if (idleMinutes >= 7 && d.idle_stage < 2) {
              await triggerIdleStage(d, 2, idleMinutes, io);
            }
            // STAGE 3: 10 minutes
            else if (idleMinutes >= 10 && d.idle_stage < 3) {
              await triggerIdleStage(d, 3, idleMinutes, io);
            }

          } else {
            // Driver is moving
            if (d.idle_since !== null) {
              await resetIdleStatus(d.id, io);
            }
          }
        }
      }
    } catch (e) {
      console.error('[edara] Idle monitor error:', e.message);
    }
  }, 60 * 1000);

  console.log('[edara] Idle monitor started (2m/7m/10m stages)');
}

async function triggerIdleStage(delivery, stage, idleMinutes, io) {
  let severity = 'info';
  let message = '';
  let pushTitle = '';
  let pushBody = '';

  if (stage === 1) {
    severity = 'medium';
    message = `Driver ${delivery.full_name} has been stationary for ${idleMinutes} minutes.`;
    pushTitle = 'Warning';
    pushBody = 'You have been stationary for 2 minutes. Please move.';
  } else if (stage === 2) {
    severity = 'high';
    message = `Driver ${delivery.full_name} has been stationary for ${idleMinutes} minutes.`;
    pushTitle = 'URGENT: MUST MOVE';
    pushBody = 'You MUST move immediately! You have been stationary for 7 minutes.';
  } else if (stage === 3) {
    severity = 'critical';
    message = `CRITICAL: Driver ${delivery.full_name} has been stationary for ${idleMinutes} minutes! Send security to check immediately.`;
  }

  await transaction(async (conn) => {
    // Update stage
    await conn.execute("UPDATE deliveries SET idle_stage = ? WHERE id = ?", [stage, delivery.id]);

    // Insert alert
    await conn.execute(
      "INSERT INTO alerts (delivery_id, alert_type, severity, message) VALUES (?, 'idle', ?, ?)",
      [delivery.id, severity, message]
    );
  });

  // Emit event to dashboard
  if (io) {
    io.to('admin').emit('delivery:idle', {
      deliveryId: delivery.id,
      idleStage: stage,
      idleMinutes
    });
    io.to('admin').emit('delivery:alert', {
      id: Date.now() + Math.random(),
      deliveryId: delivery.id,
      type: 'idle',
      severity,
      message,
      time: new Date().toISOString()
    });
  }

  // Send push notification to driver (except for stage 3 which is mainly for security)
  if ((stage === 1 || stage === 2) && delivery.fcm_token) {
    await sendPushNotification(delivery.fcm_token, pushTitle, pushBody, { type: 'idle_warning' });
  }
}

async function resetIdleStatus(deliveryId, io) {
  await transaction(async (conn) => {
    await conn.execute("UPDATE deliveries SET idle_since = NULL, idle_stage = 0 WHERE id = ?", [deliveryId]);
    await conn.execute("UPDATE alerts SET resolved_at = NOW() WHERE delivery_id = ? AND alert_type = 'idle' AND resolved_at IS NULL", [deliveryId]);
  });

  if (io) {
    io.to('admin').emit('delivery:idle', {
      deliveryId,
      idleStage: 0,
      idleMinutes: 0
    });
  }
}

function stopIdleMonitor() {
  if (intervalId) {
    clearInterval(intervalId);
    intervalId = null;
  }
}

module.exports = {
  startIdleMonitor,
  stopIdleMonitor,
  resetIdleStatus // exported for reuse in other places if needed
};
