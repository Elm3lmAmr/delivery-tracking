import { useEffect, useState } from 'react';
import api from '../api/client.js';

export default function ReportsView() {
  const [summary, setSummary] = useState({});
  const [byProject, setByProject] = useState([]);
  const [topDrivers, setTopDrivers] = useState([]);
  const [peakHours, setPeakHours] = useState([]);

  useEffect(() => {
    Promise.all([
      api.get('/admin/reports/summary'),
      api.get('/admin/reports/by-project'),
      api.get('/admin/reports/top-drivers'),
      api.get('/admin/reports/peak-hours')
    ]).then(([s, p, t, h]) => {
      setSummary(s.data);
      setByProject(p.data.rows);
      setTopDrivers(t.data.drivers);
      setPeakHours(h.data.hours);
    });
  }, []);

  const handleExport = () => {
    const token = localStorage.getItem('edara_token');
    fetch('/api/v1/admin/export/reports.csv', {
      headers: { Authorization: `Bearer ${token}` }
    })
      .then((r) => r.blob())
      .then((blob) => {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `edara-reports-${Date.now()}.csv`;
        a.click();
        URL.revokeObjectURL(url);
      });
  };

  const maxProj = Math.max(...byProject.map((p) => p.count), 1);
  const maxDrv = Math.max(...topDrivers.map((d) => d.total_deliveries), 1);
  const maxHr = Math.max(...peakHours.map((h) => h.count), 1);

  return (
    <div style={{ padding: 24 }}>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 16 }}>
        <button className="btn-export" onClick={handleExport}>Export CSV</button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14, marginBottom: 24 }}>
        <ReportCard label="Deliveries this week" value={summary.totalDeliveries || 0} />
        <ReportCard label="Avg dwell time" value={`${Math.floor((summary.avgDwellSeconds || 0) / 60)}m`} />
        <ReportCard label="Total alerts" value={summary.totalAlerts || 0} color="var(--warn)" />
        <ReportCard label="Active drivers" value={summary.activeDrivers || 0} />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 20 }}>
        <Panel title="Deliveries by project (7d)">
          {byProject.map((p) => (
            <BarRow key={p.project} label={p.project} value={p.count} pct={p.count / maxProj * 100} />
          ))}
        </Panel>
        <Panel title="Top drivers this week">
          {topDrivers.map((d) => (
            <BarRow key={d.phone} label={d.full_name} value={d.total_deliveries} pct={d.total_deliveries / maxDrv * 100} color="var(--ok)" />
          ))}
        </Panel>
      </div>
      <Panel title="Peak hours today" style={{ marginTop: 20 }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(24, 1fr)', gap: 2, height: 80, alignItems: 'end' }}>
          {peakHours.map((h) => (
            <div key={h.hour} style={{ background: 'var(--accent)', height: `${h.count / maxHr * 100}%`, borderRadius: '2px 2px 0 0', minHeight: 3 }} />
          ))}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(24, 1fr)', fontSize: 9, color: 'var(--muted)', fontFamily: 'JetBrains Mono', textAlign: 'center', marginTop: 4 }}>
          {peakHours.map((h, i) => <span key={h.hour}>{i % 2 === 0 ? String(h.hour).padStart(2, '0') : ''}</span>)}
        </div>
      </Panel>
    </div>
  );
}

function ReportCard({ label, value, color }) {
  return (
    <div style={{ background: 'var(--bg)', border: '1px solid var(--border)', borderRadius: 12, padding: 18 }}>
      <div style={{ fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase', color: 'var(--muted)', fontWeight: 600, marginBottom: 8 }}>{label}</div>
      <div style={{ fontFamily: 'IBM Plex Sans', fontSize: 26, fontWeight: 700, color: color || 'var(--text)' }}>{value}</div>
    </div>
  );
}

function Panel({ title, children, style }) {
  return (
    <div style={{ background: 'var(--bg)', border: '1px solid var(--border)', borderRadius: 12, padding: 20, ...style }}>
      <h4 style={{ fontSize: 13, marginBottom: 16 }}>{title}</h4>
      {children}
    </div>
  );
}

function BarRow({ label, value, pct, color }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '120px 1fr 40px', gap: 12, alignItems: 'center', marginBottom: 10, fontSize: 12 }}>
      <div style={{ color: 'var(--muted)' }}>{label}</div>
      <div style={{ background: 'var(--surface-2)', borderRadius: 6, height: 8, overflow: 'hidden' }}>
        <div style={{ background: color || 'var(--accent)', height: '100%', width: `${pct}%`, borderRadius: 6 }} />
      </div>
      <div style={{ fontFamily: 'JetBrains Mono', fontSize: 11, textAlign: 'end' }}>{value}</div>
    </div>
  );
}
