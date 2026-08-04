const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');

async function fix() {
  try {
    const conn = await mysql.createConnection({host:'localhost', user:'root', database:'edara_delivery'});
    
    // Check what is currently in the DB
    const [rows] = await conn.query('SELECT email, password_hash FROM users');
    console.log('Current DB state:', rows);
    
    // Hash correctly
    const hash = await bcrypt.hash('password123', 10);
    console.log('New correct hash:', hash);
    
    // Update DB
    await conn.query('UPDATE users SET password_hash = ?', [hash]);
    console.log('Database updated successfully with correct hash.');
    
    // Verify
    const [rowsAfter] = await conn.query('SELECT email, password_hash FROM users');
    console.log('After DB state:', rowsAfter);
    
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}
fix();
