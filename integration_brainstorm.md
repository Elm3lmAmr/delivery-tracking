# Edara Delivery Tracking: System Integration Brainstorm

## 1. Web Dashboard Readiness
**Status: Mostly Ready**

The web dashboard is already configured to receive tracking and assignment updates in real time. 
- When the security guard scans the QR code, the backend triggers `confirmEntry`, updates the delivery to `active`, and fires a socket event (`io.to('admin').emit('delivery:started')`).
- The `LiveView` React component listens to this socket event and immediately refreshes the active deliveries list.
- **Missing Feature:** While the backend emits a `delivery:ping` event with the driver's live GPS coordinates, the actual map UI component (e.g., Google Maps / Leaflet) is not yet built to render the live moving dots on the dashboard.

## 2. Missing Database Schema Requirements (`DB-1.sql`)

Looking at the end-to-end flow from mobile registration to gate tracking, the following gaps need to be addressed in the database schema:

### Exit Gate & Exit Guard Tracking
Currently, the `deliveries` table only tracks the entry point (`gate_id` and `scanned_by`).
- **Gap:** There is no tracking for when and where the driver leaves. 
- **Solution:** Add `exit_gate_id` and `exit_scanned_by` to the `deliveries` table to accurately calculate `duration_seconds` and verify they have left the compound.

### Dynamic Guard Shift Assignments
In the `users` table, a guard has a statically assigned gate (`assigned_gate_id`).
- **Gap:** In reality, guards rotate gates or work in shifts. If a guard logs in on a shared gate mobile device, they should be able to select their gate. 
- **Solution:** Create a `guard_sessions` or `shifts` table (e.g., `guard_id`, `gate_id`, `login_time`, `logout_time`) rather than hardcoding the gate on the user profile.

### Push Notification Tokens (FCM)
The mobile apps (driver and guard) will need to receive silent push notifications or alerts (e.g., "Your entry was approved", or "Driver has overstayed").
- **Gap:** There is no column for Firebase Cloud Messaging (FCM) tokens.
- **Solution:** Add `fcm_token` or `device_id` columns to both the `drivers` and `users` tables.

### Vehicle Plate Overrides per Trip
The `drivers` table holds a single `plate_number`.
- **Gap:** If the driver uses a rental or a different truck for a specific trip, the system assumes they are using their default vehicle.
- **Solution:** Add a `trip_plate_number` column to the `deliveries` table. The QR generation flow should allow the driver to confirm or modify the plate number for that specific trip.

### More Granular Delivery Statuses
The current `status` enum in `deliveries` is `('pending','active','completed','expired','rejected')`.
- **Gap:** For precise live location tracking, it's helpful to know when the driver actually reaches the destination unit versus just driving around the compound.
- **Solution:** Add statuses like `arrived_at_destination` and `departed_destination`.
