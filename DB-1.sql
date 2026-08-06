-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: edara_delivery
-- ------------------------------------------------------
-- Server version	5.5.5-10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `alerts`
--

DROP TABLE IF EXISTS `alerts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alerts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `delivery_id` int(11) NOT NULL,
  `alert_type` enum('restricted_zone','overstay','no_gps','qr_expired','entry_rejected','idle') NOT NULL,
  `severity` enum('info','warning','critical') DEFAULT 'warning',
  `message` varchar(500) DEFAULT NULL,
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `resolved_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `delivery_id` (`delivery_id`),
  KEY `resolved_by` (`resolved_by`),
  KEY `idx_created` (`created_at`),
  KEY `idx_severity` (`severity`,`resolved_at`),
  CONSTRAINT `alerts_ibfk_1` FOREIGN KEY (`delivery_id`) REFERENCES `deliveries` (`id`) ON DELETE CASCADE,
  CONSTRAINT `alerts_ibfk_2` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alerts`
--

LOCK TABLES `alerts` WRITE;
/*!40000 ALTER TABLE `alerts` DISABLE KEYS */;
/*!40000 ALTER TABLE `alerts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `actor_type` enum('user','driver','system') NOT NULL,
  `actor_id` int(11) DEFAULT NULL,
  `action` varchar(80) NOT NULL,
  `target_type` varchar(40) DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details`)),
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_actor` (`actor_type`,`actor_id`),
  KEY `idx_target` (`target_type`,`target_id`),
  KEY `idx_action_time` (`action`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_log`
--

LOCK TABLES `audit_log` WRITE;
/*!40000 ALTER TABLE `audit_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deliveries`
--

DROP TABLE IF EXISTS `deliveries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deliveries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `qr_token` varchar(64) NOT NULL,
  `driver_id` int(11) NOT NULL,
  `project_id` int(11) NOT NULL,
  `unit_id` int(11) DEFAULT NULL,
  `unit_number_raw` varchar(40) DEFAULT NULL,
  `gate_id` int(11) DEFAULT NULL,
  `exit_gate_id` int(11) DEFAULT NULL,
  `exit_scanned_by` int(11) DEFAULT NULL,
  `is_offline` tinyint(1) DEFAULT 0,
  `idle_since` timestamp NULL DEFAULT NULL,
  `idle_stage` tinyint(1) DEFAULT 0,
  `status` enum('pending','active','completed','expired','rejected') DEFAULT 'pending',
  `qr_expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `entered_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `duration_seconds` int(11) DEFAULT NULL,
  `scanned_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `qr_token` (`qr_token`),
  KEY `unit_id` (`unit_id`),
  KEY `gate_id` (`gate_id`),
  KEY `scanned_by` (`scanned_by`),
  KEY `idx_status` (`status`),
  KEY `idx_driver` (`driver_id`),
  KEY `idx_project_entered` (`project_id`,`entered_at`),
  KEY `idx_qr_token` (`qr_token`),
  CONSTRAINT `deliveries_ibfk_1` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `deliveries_ibfk_2` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE,
  CONSTRAINT `deliveries_ibfk_3` FOREIGN KEY (`unit_id`) REFERENCES `units` (`id`) ON DELETE SET NULL,
  CONSTRAINT `deliveries_ibfk_4` FOREIGN KEY (`gate_id`) REFERENCES `gates` (`id`) ON DELETE SET NULL,
  CONSTRAINT `deliveries_ibfk_5` FOREIGN KEY (`scanned_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deliveries`
--

LOCK TABLES `deliveries` WRITE;
/*!40000 ALTER TABLE `deliveries` DISABLE KEYS */;
/*!40000 ALTER TABLE `deliveries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `drivers`
--

DROP TABLE IF EXISTS `drivers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `drivers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone` varchar(20) NOT NULL,
  `full_name` varchar(160) DEFAULT NULL,
  `plate_number` varchar(20) NOT NULL,
  `id_doc_path` varchar(500) DEFAULT NULL,
  `license_doc_path` varchar(500) DEFAULT NULL,
  `selfie_path` varchar(500) DEFAULT NULL,
  `face_match_score` decimal(5,2) DEFAULT NULL,
  `status` enum('pending','verified','revoked') DEFAULT 'pending',
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `total_deliveries` int(11) DEFAULT 0,
  `last_active_at` timestamp NULL DEFAULT NULL,
  `fcm_token` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone` (`phone`),
  KEY `approved_by` (`approved_by`),
  KEY `idx_phone` (`phone`),
  KEY `idx_plate` (`plate_number`),
  KEY `idx_status` (`status`),
  CONSTRAINT `drivers_ibfk_1` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `drivers`
--

LOCK TABLES `drivers` WRITE;
/*!40000 ALTER TABLE `drivers` DISABLE KEYS */;
INSERT INTO `drivers` VALUES (1,'+201092346789','Mahmoud Sayed Ibrahim','MSR 4429',NULL,NULL,NULL,NULL,'verified',NULL,'2026-06-14 19:31:53',47,NULL,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(2,'+201145552820','Karim Nabil Hussein','MSR 8812',NULL,NULL,NULL,NULL,'verified',NULL,'2026-06-19 19:31:53',33,NULL,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(3,'+201287339112','Youssef Adel Mansour','MSR 2205',NULL,NULL,NULL,NULL,'verified',NULL,'2026-06-24 19:31:53',28,NULL,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(4,'+201092664712','Ali Sherif Fahmy','MSR 6104',NULL,NULL,NULL,NULL,'verified',NULL,'2026-06-04 19:31:53',55,NULL,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(5,'+201054882345','Ahmed Zaki Farouk','MSR 1177',NULL,NULL,NULL,NULL,'pending',NULL,NULL,0,NULL,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(6,'+201122447134','Hossam Farid Salem','MSR 3390',NULL,NULL,NULL,NULL,'revoked',NULL,'2026-05-15 19:31:53',12,NULL,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(7,'+2001118196999',NULL,'',NULL,NULL,NULL,NULL,'pending',NULL,NULL,0,NULL,'2026-07-15 10:31:24','2026-07-15 10:31:24'),(8,'+201000000000',NULL,'',NULL,NULL,NULL,NULL,'pending',NULL,NULL,0,NULL,'2026-07-16 08:00:45','2026-07-16 08:00:45'),(9,'+20 1118196999',NULL,'',NULL,NULL,NULL,NULL,'pending',NULL,NULL,0,NULL,'2026-07-16 09:39:25','2026-07-16 09:39:25');
/*!40000 ALTER TABLE `drivers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gates`
--

DROP TABLE IF EXISTS `gates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `gates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `project_id` int(11) NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(80) NOT NULL,
  `type` enum('main','service','delivery','emergency') DEFAULT 'main',
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_project_gate` (`project_id`,`code`),
  CONSTRAINT `gates_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gates`
--

LOCK TABLES `gates` WRITE;
/*!40000 ALTER TABLE `gates` DISABLE KEYS */;
INSERT INTO `gates` VALUES (1,1,'A','Gate A - Main','main',30.0459000,30.9701000,1),(2,1,'B','Gate B - Service','service',30.0460000,30.9710000,1),(3,1,'C','Gate C - Delivery','delivery',30.0455000,30.9695000,1),(4,2,'A','Gate A - Main','main',30.0089000,31.4959000,1),(5,2,'B','Gate B - Service','service',30.0092000,31.4970000,1),(6,2,'C','Gate C - Delivery','delivery',30.0085000,31.4950000,1),(7,3,'A','Gate A - Main','main',30.0110000,31.5008000,1),(8,3,'B','Gate B - Service','service',30.0115000,31.5015000,1),(9,4,'A','Gate A - Main','main',30.0470000,30.9720000,1),(10,5,'A','Gate A - Main','main',30.0450000,30.9680000,1),(11,6,'A','Gate A - Main','main',30.0480000,30.9750000,1),(12,7,'A','Gate A - Main','main',30.9450000,28.9500000,1),(13,8,'A','Gate A - Main','main',30.9420000,28.9480000,1);
/*!40000 ALTER TABLE `gates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `location_pings`
--

DROP TABLE IF EXISTS `location_pings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `location_pings` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `delivery_id` int(11) NOT NULL,
  `lat` decimal(10,7) NOT NULL,
  `lng` decimal(10,7) NOT NULL,
  `accuracy_m` decimal(6,2) DEFAULT NULL,
  `speed_kmh` decimal(5,2) DEFAULT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_delivery_time` (`delivery_id`,`recorded_at`),
  CONSTRAINT `location_pings_ibfk_1` FOREIGN KEY (`delivery_id`) REFERENCES `deliveries` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location_pings`
--

LOCK TABLES `location_pings` WRITE;
/*!40000 ALTER TABLE `location_pings` DISABLE KEYS */;
/*!40000 ALTER TABLE `location_pings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_codes`
--

DROP TABLE IF EXISTS `otp_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `otp_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `phone` varchar(20) NOT NULL,
  `code` varchar(6) NOT NULL,
  `attempts` tinyint(4) DEFAULT 0,
  `used` tinyint(1) DEFAULT 0,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_phone_active` (`phone`,`used`,`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_codes`
--

LOCK TABLES `otp_codes` WRITE;
/*!40000 ALTER TABLE `otp_codes` DISABLE KEYS */;
INSERT INTO `otp_codes` VALUES (1,'+201118196999','9596',0,0,'2026-07-15 10:36:30','2026-07-15 10:26:30'),(2,'+2001118196999','7683',0,0,'2026-07-15 10:36:56','2026-07-15 10:26:56'),(3,'+2001118196999','1791',0,1,'2026-07-15 10:31:24','2026-07-15 10:31:11'),(5,'+20 1144677042','1548',0,0,'2026-07-16 09:59:16','2026-07-16 09:59:16'),(6,'+20 1144677042','3625',0,0,'2026-07-16 09:59:24','2026-07-16 09:59:24'),(7,'+20 1144677042','7127',0,0,'2026-07-16 10:00:02','2026-07-16 10:00:02'),(8,'+20 1144677042','9946',0,0,'2026-07-16 10:00:15','2026-07-16 10:00:15'),(9,'+20 1144677042','1911',0,0,'2026-07-16 10:00:52','2026-07-16 10:00:52'),(10,'+20 1144677042','6120',0,0,'2026-07-16 10:06:41','2026-07-16 10:06:41'),(11,'+20 1118196999','3856',0,0,'2026-07-16 10:30:19','2026-07-16 10:30:19'),(12,'+20 1118196999','1118',0,0,'2026-07-16 10:30:26','2026-07-16 10:30:26'),(13,'+20 1118196999','7515',0,0,'2026-07-16 10:31:47','2026-07-16 10:31:47');
/*!40000 ALTER TABLE `otp_codes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects`
--

DROP TABLE IF EXISTS `projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `projects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(20) NOT NULL,
  `name_en` varchar(120) NOT NULL,
  `name_ar` varchar(120) DEFAULT NULL,
  `center_lat` decimal(10,7) DEFAULT NULL,
  `center_lng` decimal(10,7) DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects`
--

LOCK TABLES `projects` WRITE;
/*!40000 ALTER TABLE `projects` DISABLE KEYS */;
INSERT INTO `projects` VALUES (1,'ALG','Allegria','أليجريا',30.0459000,30.9701000,1,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(2,'EST','Eastown','إيستاون',30.0089000,31.4959000,1,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(3,'VIL','Villette','فيليت',30.0110000,31.5008000,1,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(4,'KRM','Karmell','كارميل',30.0470000,30.9720000,1,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(5,'ESS','The Estates','ذا استيتس',30.0450000,30.9680000,1,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(6,'SKY','Sky Condos','سكاي كوندوز',30.0480000,30.9750000,1,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(7,'JUN','June','يونيو',30.9450000,28.9500000,1,'2026-07-14 19:31:53','2026-07-14 19:31:53'),(8,'OGM','Ogami','أوجامي',30.9420000,28.9480000,1,'2026-07-14 19:31:53','2026-07-14 19:31:53');
/*!40000 ALTER TABLE `projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `restricted_zones`
--

DROP TABLE IF EXISTS `restricted_zones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `restricted_zones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `project_id` int(11) NOT NULL,
  `name` varchar(120) NOT NULL,
  `zone_type` enum('service','maintenance','private','staff_only') DEFAULT 'service',
  `polygon` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`polygon`)),
  `active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `project_id` (`project_id`),
  CONSTRAINT `restricted_zones_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `restricted_zones`
--

LOCK TABLES `restricted_zones` WRITE;
/*!40000 ALTER TABLE `restricted_zones` DISABLE KEYS */;
INSERT INTO `restricted_zones` VALUES (1,2,'Service Area - Back of house','service','{\"type\":\"Polygon\",\"coordinates\":[[[31.4940,30.0080],[31.4945,30.0080],[31.4945,30.0075],[31.4940,30.0075],[31.4940,30.0080]]]}',1);
/*!40000 ALTER TABLE `restricted_zones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `units`
--

DROP TABLE IF EXISTS `units`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `project_id` int(11) NOT NULL,
  `cluster` varchar(60) DEFAULT NULL,
  `unit_number` varchar(40) NOT NULL,
  `unit_type` enum('villa','townhouse','apartment','commercial') DEFAULT 'villa',
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_project_unit` (`project_id`,`unit_number`),
  KEY `idx_project_cluster` (`project_id`,`cluster`),
  CONSTRAINT `units_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `units`
--

LOCK TABLES `units` WRITE;
/*!40000 ALTER TABLE `units` DISABLE KEYS */;
INSERT INTO `units` VALUES (1,2,'Cluster B - Villas','B-101','villa',30.0090000,31.4960000,1),(2,2,'Cluster B - Villas','B-102','villa',30.0091000,31.4961000,1),(3,2,'Cluster B - Villas','B-1247','villa',30.0100000,31.4970000,1),(4,2,'Cluster C - Townhouses','C-201','townhouse',30.0088000,31.4955000,1),(5,2,'Cluster D - Apartments','D-301','apartment',30.0087000,31.4950000,1);
/*!40000 ALTER TABLE `units` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(160) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(160) NOT NULL,
  `role` enum('admin','officer','guard') NOT NULL,
  `assigned_gate_id` int(11) DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `fcm_token` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `assigned_gate_id` (`assigned_gate_id`),
  KEY `idx_role` (`role`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`assigned_gate_id`) REFERENCES `gates` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'admin@edara.com','$2b$10$yoZZTyl3N0AAhFB6Y4R35OGxr0ORQsqIuIC.GfG79KF8P0JmCwud2','System Admin','admin',NULL,1,'2026-07-15 07:56:32','2026-07-14 19:31:53'),(2,'officer@edara.com','$2b$10$yoZZTyl3N0AAhFB6Y4R35OGxr0ORQsqIuIC.GfG79KF8P0JmCwud2','Security Officer','officer',NULL,1,'2026-07-14 19:43:55','2026-07-14 19:31:53'),(3,'ahmed.fathy@edara.com','$2b$10$yoZZTyl3N0AAhFB6Y4R35OGxr0ORQsqIuIC.GfG79KF8P0JmCwud2','Ahmed Fathy','guard',4,1,'2026-07-16 11:23:08','2026-07-14 19:31:53'),(4,'mohamed.saad@edara.com','$2b$10$yoZZTyl3N0AAhFB6Y4R35OGxr0ORQsqIuIC.GfG79KF8P0JmCwud2','Mohamed Saad','guard',5,1,NULL,'2026-07-14 19:31:53');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-17 23:57:18
