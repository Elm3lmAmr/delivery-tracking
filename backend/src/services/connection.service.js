const { query, transaction } = require('../config/database');

let intervalId = null;

function startConnectionMonitor(io) {
  if (intervalId) return;
  
  // Run every 30 seconds
  intervalId = setInterval(async () => {
    try {
      // Find active deliveries that haven't pinged in 90 seconds (and aren't already marked offline)
      const rows = await query(`
        SELECT d.id, COALESCE(dr.full_name, dr.phone, 'Unknown Driver') as driver_name
        FROM deliveries d
        JOIN drivers dr ON d.driver_id = dr.id
        WHERE d.status = 'active' AND d.is_offline = 0
        AND TIMESTAMPDIFF(SECOND, COALESCE((SELECT MAX(recorded_at) FROM location_pings WHERE delivery_id = d.id), d.entered_at), NOW()) >= 90
      `);

      for (const delivery of rows) {
        await transaction(async (conn) => {
          // Double check to avoid race conditions
          const [check] = await conn.execute("SELECT is_offline FROM deliveries WHERE id = ? FOR UPDATE", [delivery.id]);
          if (check.length > 0 && check[0].is_offline === 0) {
            // 1. Mark as offline
            await conn.execute("UPDATE deliveries SET is_offline = 1 WHERE id = ?", [delivery.id]);
            
            // 2. Generate alert
            const msg = `Driver ${delivery.driver_name} has lost internet connection (no GPS signal).`;
            await conn.execute(
              "INSERT INTO alerts (delivery_id, alert_type, severity, message) VALUES (?, 'no_gps', 'high', ?)",
              [delivery.id, msg]
            );

            // 3. Emit event
            if (io) {
              io.to('admin').emit('delivery:offline', {
                deliveryId: delivery.id,
                isOffline: true
              });
              
              io.to('admin').emit('delivery:alert', {
                id: Date.now() + Math.random(), 
                deliveryId: delivery.id,
                type: 'no_gps',
                severity: 'high',
                message: msg,
                time: new Date().toISOString()
              });
            }
          }
        });
      }
    } catch (e) {
      console.error('[edara] Connection monitor error:', e.message);
    }
  }, 30 * 1000);
  
  console.log('[edara] Connection monitor started (90s limit)');
}

function stopConnectionMonitor() {
  if (intervalId) {
    clearInterval(intervalId);
    intervalId = null;
  }
}

module.exports = {
  startConnectionMonitor,
  stopConnectionMonitor
};
