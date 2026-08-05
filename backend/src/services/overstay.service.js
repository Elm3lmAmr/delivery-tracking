const { query } = require('../config/database');

let intervalId = null;

function startOverstayCron(io) {
  if (intervalId) return;
  
  // Run every 1 minute
  intervalId = setInterval(async () => {
    try {
      // Find active deliveries that entered more than 5 minutes ago
      const rows = await query(`
        SELECT d.id, d.entered_at, COALESCE(dr.full_name, dr.phone, 'Unknown Driver') as driver_name, u.unit_number 
        FROM deliveries d
        JOIN drivers dr ON d.driver_id = dr.id
        LEFT JOIN units u ON d.unit_id = u.id
        WHERE d.status = 'active'
        AND TIMESTAMPDIFF(MINUTE, d.entered_at, NOW()) >= 5
      `);

      for (const delivery of rows) {
        // Check if we already alerted for this delivery
        const [existing] = await query(
          "SELECT id FROM alerts WHERE delivery_id = ? AND alert_type = 'overstay'",
          [delivery.id]
        );

        if (!existing) {
          const msg = `Driver ${delivery.driver_name} has overstayed the 5-minute limit.`;
          await query(
            "INSERT INTO alerts (delivery_id, alert_type, severity, message) VALUES (?, 'overstay', 'critical', ?)",
            [delivery.id, msg]
          );

          if (io) {
            io.to('admin').emit('delivery:alert', {
              id: Date.now(), // dummy id for frontend list key
              deliveryId: delivery.id,
              type: 'overstay',
              severity: 'critical',
              message: msg,
              time: new Date().toISOString()
            });
          }
        }
      }
    } catch (e) {
      console.error('[edara] Overstay cron error:', e.message);
    }
  }, 60 * 1000);
  
  console.log('[edara] Overstay cron started (5 min limit)');
}

function stopOverstayCron() {
  if (intervalId) {
    clearInterval(intervalId);
    intervalId = null;
  }
}

module.exports = {
  startOverstayCron,
  stopOverstayCron
};
