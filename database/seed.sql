-- =====================================================================
-- Edara Delivery Tracking - Seed Data
-- Run after schema.sql
-- =====================================================================

USE edara_delivery;

-- Projects (SODIC / Edara compounds)
INSERT INTO projects (code, name_en, name_ar, center_lat, center_lng) VALUES
  ('ALG', 'Allegria', 'أليجريا', 30.0459, 30.9701),
  ('EST', 'Eastown', 'إيستاون', 30.0089, 31.4959),
  ('VIL', 'Villette', 'فيليت', 30.0110, 31.5008),
  ('KRM', 'Karmell', 'كارميل', 30.0470, 30.9720),
  ('ESS', 'The Estates', 'ذا استيتس', 30.0450, 30.9680),
  ('SKY', 'Sky Condos', 'سكاي كوندوز', 30.0480, 30.9750),
  ('JUN', 'June', 'يونيو', 30.9450, 28.9500),
  ('OGM', 'Ogami', 'أوجامي', 30.9420, 28.9480);

-- Gates (3 per project - main, service, delivery)
INSERT INTO gates (project_id, code, name, type, lat, lng) VALUES
  (1, 'A', 'Gate A - Main', 'main', 30.0459, 30.9701),
  (1, 'B', 'Gate B - Service', 'service', 30.0460, 30.9710),
  (1, 'C', 'Gate C - Delivery', 'delivery', 30.0455, 30.9695),
  (2, 'A', 'Gate A - Main', 'main', 30.0089, 31.4959),
  (2, 'B', 'Gate B - Service', 'service', 30.0092, 31.4970),
  (2, 'C', 'Gate C - Delivery', 'delivery', 30.0085, 31.4950),
  (3, 'A', 'Gate A - Main', 'main', 30.0110, 31.5008),
  (3, 'B', 'Gate B - Service', 'service', 30.0115, 31.5015),
  (4, 'A', 'Gate A - Main', 'main', 30.0470, 30.9720),
  (5, 'A', 'Gate A - Main', 'main', 30.0450, 30.9680),
  (6, 'A', 'Gate A - Main', 'main', 30.0480, 30.9750),
  (7, 'A', 'Gate A - Main', 'main', 30.9450, 28.9500),
  (8, 'A', 'Gate A - Main', 'main', 30.9420, 28.9480);

-- Sample units in Eastown (project_id=2)
INSERT INTO units (project_id, cluster, unit_number, unit_type, lat, lng) VALUES
  (2, 'Cluster B - Villas', 'B-101', 'villa', 30.0090, 31.4960),
  (2, 'Cluster B - Villas', 'B-102', 'villa', 30.0091, 31.4961),
  (2, 'Cluster B - Villas', 'B-1247', 'villa', 30.0100, 31.4970),
  (2, 'Cluster C - Townhouses', 'C-201', 'townhouse', 30.0088, 31.4955),
  (2, 'Cluster D - Apartments', 'D-301', 'apartment', 30.0087, 31.4950);

-- Restricted zone (example: service area in Eastown)
INSERT INTO restricted_zones (project_id, name, zone_type, polygon) VALUES
  (2, 'Service Area - Back of house', 'service',
   '{"type":"Polygon","coordinates":[[[31.4940,30.0080],[31.4945,30.0080],[31.4945,30.0075],[31.4940,30.0075],[31.4940,30.0080]]]}');

-- Backend users
-- Password for all seed users: "password123" (bcrypt hash)
INSERT INTO users (email, password_hash, full_name, role, assigned_gate_id) VALUES
  ('admin@edara.com', '$2b$10$rGZzFxKZKV.KZLzKzKZZKuGZzFxKZKVKZLzKzKZZKuGZzFxKZKVKZ', 'System Admin', 'admin', NULL),
  ('officer@edara.com', '$2b$10$rGZzFxKZKV.KZLzKzKZZKuGZzFxKZKVKZLzKzKZZKuGZzFxKZKVKZ', 'Security Officer', 'officer', NULL),
  ('ahmed.fathy@edara.com', '$2b$10$rGZzFxKZKV.KZLzKzKZZKuGZzFxKZKVKZLzKzKZZKuGZzFxKZKVKZ', 'Ahmed Fathy', 'guard', 4),
  ('mohamed.saad@edara.com', '$2b$10$rGZzFxKZKV.KZLzKzKZZKuGZzFxKZKVKZLzKzKZZKuGZzFxKZKVKZ', 'Mohamed Saad', 'guard', 5);

-- Sample verified drivers
INSERT INTO drivers (phone, full_name, plate_number, status, total_deliveries, approved_at) VALUES
  ('+201092346789', 'Mahmoud Sayed Ibrahim', 'MSR 4429', 'verified', 47, NOW() - INTERVAL 30 DAY),
  ('+201145552820', 'Karim Nabil Hussein', 'MSR 8812', 'verified', 33, NOW() - INTERVAL 25 DAY),
  ('+201287339112', 'Youssef Adel Mansour', 'MSR 2205', 'verified', 28, NOW() - INTERVAL 20 DAY),
  ('+201092664712', 'Ali Sherif Fahmy', 'MSR 6104', 'verified', 55, NOW() - INTERVAL 40 DAY),
  ('+201054882345', 'Ahmed Zaki Farouk', 'MSR 1177', 'pending', 0, NULL),
  ('+201122447134', 'Hossam Farid Salem', 'MSR 3390', 'revoked', 12, NOW() - INTERVAL 60 DAY);
