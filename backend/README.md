# Edara Delivery Tracking - Backend

Node.js + Express + MySQL + Socket.IO backend.

## Setup

```bash
cd backend
cp .env.example .env
# edit .env with your DB credentials and JWT secret
npm install

# Create database and load schema
mysql -u root -p < ../database/schema.sql
mysql -u root -p edara_delivery < ../database/seed.sql

# Run in dev mode
npm run dev

# Run in production
npm start
```

Server runs on `http://localhost:4000` by default.
Health check: `GET /health`

## API Overview

Base URL: `/api/v1`

### Auth
- `POST /auth/login` — user login (admin/officer/guard), returns JWT
- `POST /auth/driver/otp/request` — send OTP to phone
- `POST /auth/driver/otp/verify` — verify OTP, returns driver JWT

### Drivers (mobile)
- `GET /drivers/me` — current driver profile
- `POST /drivers/me/documents` — upload 3 photos + plate (multipart form-data)
- `PATCH /drivers/me/plate` — update plate
- `GET /drivers/me/deliveries` — my recent deliveries

### Deliveries
- `POST /deliveries` — driver creates delivery, returns QR token
- `POST /deliveries/:id/pings` — driver posts GPS ping
- `GET /deliveries/by-token/:qrToken` — guard looks up scanned QR
- `POST /deliveries/:id/confirm-entry` — guard confirms entry
- `POST /deliveries/:id/reject` — guard rejects entry

### Officers
- `GET /officers/queue?bucket=auto|flagged` — driver review queue
- `GET /officers/drivers/:id` — full driver submission details
- `POST /officers/drivers/:id/approve` — approve driver permanently
- `POST /officers/drivers/:id/revoke` — revoke driver access

### Admin (dashboard)
- `GET /admin/kpis` — live counters
- `GET /admin/live-deliveries?search=...` — active deliveries
- `GET /admin/alerts` — recent alerts
- `GET /admin/history?project_id=&status=&from=&to=&plate=&phone=&search=` — filtered history
- `GET /admin/drivers?status=&plate=&phone=&search=` — filtered drivers
- `GET /admin/reports/summary?from=&to=` — dashboard summary
- `GET /admin/reports/by-project` — deliveries per project
- `GET /admin/reports/peak-hours` — hourly distribution
- `GET /admin/reports/top-drivers` — top 10 drivers by volume
- `GET /admin/export/history.csv?...` — export filtered history as CSV
- `GET /admin/export/drivers.csv?...` — export filtered drivers as CSV
- `GET /admin/export/reports.csv` — export monthly aggregated data

## Real-time events (Socket.IO)

Connect with `auth.token = <jwt>`.

Server emits (admin/officer room):
- `delivery:started` — new entry through gate
- `delivery:ping` — live GPS ping `{deliveryId, lat, lng}`
- `delivery:alert` — new alert raised

## Third-party integrations

Currently stubbed:
- **SMS OTP** — edit `src/services/sms.service.js` for Vonage / Twilio / Msegat
- **Face matching** — edit `src/services/face-match.service.js` for AWS Rekognition / Azure Face
- **File storage** — currently local disk (`./uploads`), swap to S3/R2 by editing `src/middleware/upload.js`

## Environment variables

See `.env.example` for the full list. Critical ones:
- `JWT_SECRET` — must be long random string (32+ chars)
- `DB_*` — MySQL connection
- `FACE_MATCH_THRESHOLD` — auto-approval threshold (default 90)
- `QR_EXPIRY_MINUTES` — how long QR is valid (default 30)
- `DEFAULT_SLA_MINUTES` — overstay threshold (default 20)
