'use strict';

const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT, 10) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'edara_delivery',
  waitForConnections: true,
  connectionLimit: 20,
  queueLimit: 0,
  timezone: '+00:00',
  dateStrings: false,
  charset: 'utf8mb4_unicode_ci'
});

async function testConnection() {
  const conn = await pool.getConnection();
  try {
    await conn.ping();
  } finally {
    conn.release();
  }
}

async function query(sql, params) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

async function transaction(fn) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}

module.exports = { pool, query, transaction, testConnection };
