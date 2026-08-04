# Edara Delivery Tracking - Web Dashboard

React + Vite frontend for admins, officers, and guards.

## Setup

```bash
cd frontend
npm install
npm run dev
```

Dashboard runs on `http://localhost:5173`.
Vite proxies `/api` and `/socket.io` to the backend at `http://localhost:4000`.

## Build for production

```bash
npm run build
# Output goes to dist/ - deploy to any static host (Vercel, Netlify, nginx, S3+CloudFront)
```

## Structure

- `src/api/client.js` - Axios instance with auth interceptors
- `src/hooks/useAuth.js` - Zustand store for session
- `src/hooks/useSocket.js` - Socket.IO connection
- `src/pages/LoginPage.jsx` - Email/password login
- `src/pages/DashboardPage.jsx` - Main dashboard with tabs
- `src/components/LiveView.jsx` - Real-time deliveries + KPIs + alerts
- `src/components/HistoryView.jsx` - Past deliveries with filters + CSV export
- `src/components/DriversView.jsx` - Driver database with filters + CSV export
- `src/components/ReportsView.jsx` - Aggregate charts + CSV export
- `src/styles/tokens.css` - Design tokens (dark + light palettes)

## What's implemented

Full admin dashboard with 4 tabs (Live, History, Drivers, Reports), search box, structured filters per tab, CSV export per tab, light/dark theme toggle, real-time updates via Socket.IO.

## What's not

- Officer console (approve/revoke drivers) - endpoints wired, UI ready to add
- Guard scanner web view - primary flow is the mobile app
- EN/AR toggle - the demo v4 HTML has full translations; port strings to `src/utils/i18n.js` when needed
- Map component - use Google Maps JS API or Leaflet; wire to Socket.IO ping events

## Demo credentials (from seed.sql)

Email: `admin@edara.com` · Password: `password123`
Email: `officer@edara.com` · Password: `password123`

**Change these before production.** Hash properly with `bcrypt.hashSync('yourpass', 10)`.
