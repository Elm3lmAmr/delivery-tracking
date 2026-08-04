-- =====================================================================
-- Edara Delivery Tracking - MySQL Schema
-- MySQL 8.0+ required (for JSON columns and spatial functions)
-- =====================================================================

DROP DATABASE IF EXISTS edara_delivery;
CREATE DATABASE edara_delivery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE edara_delivery;

-- ---------------------------------------------------------------------
-- Projects (Allegria, Eastown, Villette, etc.)
-- ---------------------------------------------------------------------
CREATE TABLE projects (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(20) UNIQUE NOT NULL,
  name_en VARCHAR(120) NOT NULL,
  name_ar VARCHAR(120),
  center_lat DECIMAL(10, 7),
  center_lng DECIMAL(10, 7),
  active TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- Gates per project
-- ---------------------------------------------------------------------
CREATE TABLE gates (
  id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT NOT NULL,
  code VARCHAR(20) NOT NULL,
  name VARCHAR(80) NOT NULL,
  type ENUM('main', 'service', 'delivery', 'emergency') DEFAULT 'main',
  lat DECIMAL(10, 7),
  lng DECIMAL(10, 7),
  active TINYINT(1) DEFAULT 1,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  UNIQUE KEY unique_project_gate (project_id, code)
);

-- ---------------------------------------------------------------------
-- Units within projects (villas, apartments, etc.)
-- ---------------------------------------------------------------------
CREATE TABLE units (
  id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT NOT NULL,
  cluster VARCHAR(60),
  unit_number VARCHAR(40) NOT NULL,
  unit_type ENUM('villa', 'townhouse', 'apartment', 'commercial') DEFAULT 'villa',
  lat DECIMAL(10, 7),
  lng DECIMAL(10, 7),
  active TINYINT(1) DEFAULT 1,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  UNIQUE KEY unique_project_unit (project_id, unit_number),
  INDEX idx_project_cluster (project_id, cluster)
);

-- ---------------------------------------------------------------------
-- Restricted zones (polygons for geofence exclusion areas)
-- ---------------------------------------------------------------------
CREATE TABLE restricted_zones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT NOT NULL,
  name VARCHAR(120) NOT NULL,
  zone_type ENUM('service', 'maintenance', 'private', 'staff_only') DEFAULT 'service',
  polygon JSON NOT NULL,
  active TINYINT(1) DEFAULT 1,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- Users (admin, officer, guard)
-- ---------------------------------------------------------------------
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(160) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(160) NOT NULL,
  role ENUM('admin', 'officer', 'guard') NOT NULL,
  assigned_gate_id INT NULL,
  active TINYINT(1) DEFAULT 1,
  last_login_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (assigned_gate_id) REFERENCES gates(id) ON DELETE SET NULL,
  INDEX idx_role (role)
);

-- ---------------------------------------------------------------------
-- Drivers (self-onboarded via mobile app)
-- ---------------------------------------------------------------------
CREATE TABLE drivers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  phone VARCHAR(20) UNIQUE NOT NULL,
  full_name VARCHAR(160),
  plate_number VARCHAR(20) NOT NULL,
  id_doc_path VARCHAR(500),
  license_doc_path VARCHAR(500),
  selfie_path VARCHAR(500),
  face_match_score DECIMAL(5, 2),
  status ENUM('pending', 'verified', 'revoked') DEFAULT 'pending',
  approved_by INT NULL,
  approved_at TIMESTAMP NULL,
  total_deliveries INT DEFAULT 0,
  last_active_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_phone (phone),
  INDEX idx_plate (plate_number),
  INDEX idx_status (status)
);

-- ---------------------------------------------------------------------
-- OTP codes (temporary, for phone signup)
-- ---------------------------------------------------------------------
CREATE TABLE otp_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  phone VARCHAR(20) NOT NULL,
  code VARCHAR(6) NOT NULL,
  attempts TINYINT DEFAULT 0,
  used TINYINT(1) DEFAULT 0,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_phone_active (phone, used, expires_at)
);

-- ---------------------------------------------------------------------
-- Deliveries (the core session concept)
-- ---------------------------------------------------------------------
CREATE TABLE deliveries (
  id INT AUTO_INCREMENT PRIMARY KEY,
  qr_token VARCHAR(64) UNIQUE NOT NULL,
  driver_id INT NOT NULL,
  project_id INT NOT NULL,
  unit_id INT NULL,
  unit_number_raw VARCHAR(40),
  gate_id INT NULL,
  status ENUM('pending', 'active', 'completed', 'expired', 'rejected') DEFAULT 'pending',
  qr_expires_at TIMESTAMP NOT NULL,
  entered_at TIMESTAMP NULL,
  completed_at TIMESTAMP NULL,
  duration_seconds INT NULL,
  scanned_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (unit_id) REFERENCES units(id) ON DELETE SET NULL,
  FOREIGN KEY (gate_id) REFERENCES gates(id) ON DELETE SET NULL,
  FOREIGN KEY (scanned_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_status (status),
  INDEX idx_driver (driver_id),
  INDEX idx_project_entered (project_id, entered_at),
  INDEX idx_qr_token (qr_token)
);

-- ---------------------------------------------------------------------
-- Location pings (streamed from driver phone)
-- ---------------------------------------------------------------------
CREATE TABLE location_pings (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  delivery_id INT NOT NULL,
  lat DECIMAL(10, 7) NOT NULL,
  lng DECIMAL(10, 7) NOT NULL,
  accuracy_m DECIMAL(6, 2),
  speed_kmh DECIMAL(5, 2),
  recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (delivery_id) REFERENCES deliveries(id) ON DELETE CASCADE,
  INDEX idx_delivery_time (delivery_id, recorded_at)
);

-- ---------------------------------------------------------------------
-- Alerts (raised when driver misbehaves)
-- ---------------------------------------------------------------------
CREATE TABLE alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  delivery_id INT NOT NULL,
  alert_type ENUM('restricted_zone', 'overstay', 'no_gps', 'qr_expired', 'entry_rejected') NOT NULL,
  severity ENUM('info', 'warning', 'critical') DEFAULT 'warning',
  message VARCHAR(500),
  lat DECIMAL(10, 7),
  lng DECIMAL(10, 7),
  resolved_at TIMESTAMP NULL,
  resolved_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (delivery_id) REFERENCES deliveries(id) ON DELETE CASCADE,
  FOREIGN KEY (resolved_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_created (created_at),
  INDEX idx_severity (severity, resolved_at)
);

-- ---------------------------------------------------------------------
-- Audit log (who did what)
-- ---------------------------------------------------------------------
CREATE TABLE audit_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  actor_type ENUM('user', 'driver', 'system') NOT NULL,
  actor_id INT,
  action VARCHAR(80) NOT NULL,
  target_type VARCHAR(40),
  target_id INT,
  details JSON,
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_actor (actor_type, actor_id),
  INDEX idx_target (target_type, target_id),
  INDEX idx_action_time (action, created_at)
);
