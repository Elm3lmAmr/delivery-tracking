import { useEffect, useState } from 'react';
import api from '../api/client.js';
import { useSocket } from '../hooks/useSocket.js';
import LiveMap from './LiveMap.jsx';
import { toast } from 'react-toastify';

export default function LiveView({ search }) {
  const [kpis, setKpis] = useState({ activeDeliveries: 0, avgDwellSeconds: 0, zoneIncursions: 0, overstayAlerts: 0 });
  const [deliveries, setDeliveries] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [selectedDeliveryId, setSelectedDeliveryId] = useState(null);

  const loadData = async () => {
    const [k, d, a] = await Promise.all([
      api.get('/admin/kpis'),
      api.get('/admin/live-deliveries', { params: { search: search || undefined } }),
      api.get('/admin/alerts')
    ]);
    setKpis(k.data);
    setDeliveries(d.data.deliveries);
    setAlerts(a.data.alerts);
  };

  useEffect(() => { loadData(); }, [search]);

  useSocket({
    'delivery:created': (data) => {
      toast.info(`A new delivery has been registered (ID: ${data.deliveryId})`);
      loadData();
    },
    'delivery:started': (data) => {
      toast.success(`Delivery #${data.deliveryId} entered via Gate ${data.gateId}`);
      loadData();
    },
    'delivery:completed': (data) => {
      toast.info(`Delivery #${data.deliveryId} exited.`);
      loadData();
    },
    'delivery:alert': (a) => {
      toast.warn(`Alert: ${a.message}`);
      setAlerts((prev) => [a, ...prev].slice(0, 50));
    },
    'delivery:ping': (data) => {
      setDeliveries(prev => prev.map(d => 
        d.id === data.deliveryId ? { ...d, lat: data.lat, lng: data.lng } : d
      ));
    }
  });

  const fmtDwell = (s) => `${Math.floor(s / 60)}m ${String(s % 60).padStart(2, '0')}s`;

  return (
    <>
      <div className="kpi-row">
        <div className="kpi"><div className="kpi-label">Active deliveries</div><div className="kpi-value">{kpis.activeDeliveries}</div></div>
        <div className="kpi"><div className="kpi-label">Avg dwell time</div><div className="kpi-value">{fmtDwell(kpis.avgDwellSeconds)}</div></div>
        <div className="kpi"><div className="kpi-label">Zone incursions</div><div className="kpi-value" style={{ color: 'var(--warn)' }}>{kpis.zoneIncursions}</div></div>
        <div className="kpi"><div className="kpi-label">Overstay alerts</div><div className="kpi-value" style={{ color: 'var(--crit)' }}>{kpis.overstayAlerts}</div></div>
      </div>
      <div style={{ height: '400px', marginBottom: '1px', background: 'var(--border)' }}>
        <LiveMap deliveries={deliveries} selectedDeliveryId={selectedDeliveryId} />
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: 1, background: 'var(--border)' }}>
        <div style={{ background: 'var(--surface)', padding: 20 }}>
          <h4 style={{ marginBottom: 12, fontSize: 12, color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.14em' }}>Active deliveries</h4>
          <div style={{ maxHeight: 480, overflowY: 'auto' }}>
            {deliveries.length === 0 && <div style={{ padding: 20, color: 'var(--muted)', textAlign: 'center' }}>No active deliveries.</div>}
            {deliveries.map((d) => (
              <div 
                key={d.id} 
                onClick={() => setSelectedDeliveryId(d.id)}
                style={{ 
                  padding: '12px 16px', 
                  borderBottom: '1px solid var(--border)', 
                  cursor: 'pointer',
                  background: selectedDeliveryId === d.id ? 'var(--bg)' : 'transparent',
                  borderLeft: selectedDeliveryId === d.id ? '3px solid var(--accent)' : '3px solid transparent'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ fontWeight: 600 }}>{d.driver}</span>
                  <span style={{ fontFamily: 'JetBrains Mono', fontSize: 11, color: 'var(--muted)' }}>{Math.round(d.elapsed_seconds / 60)}m</span>
                </div>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>
                  {d.project} · {d.unit} · {d.gate} · <span className="mono">{d.plate_number}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
        <div style={{ background: 'var(--surface)', padding: 20 }}>
          <h4 style={{ marginBottom: 12, fontSize: 12, color: 'var(--muted)', textTransform: 'uppercase', letterSpacing: '0.14em' }}>Alerts feed</h4>
          <div style={{ maxHeight: 480, overflowY: 'auto' }}>
            {alerts.map((a) => (
              <div key={a.id} style={{ padding: '12px 0', borderBottom: '1px solid var(--border)', borderLeft: `3px solid var(--${a.severity === 'critical' ? 'crit' : 'warn'})`, paddingLeft: 12 }}>
                <div style={{ fontSize: 12, fontWeight: 600 }}>{a.alert_type}</div>
                <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 2 }}>{a.message} · {a.driver}</div>
              </div>
            ))}
            {alerts.length === 0 && <div style={{ padding: 20, color: 'var(--muted)', textAlign: 'center' }}>No alerts.</div>}
          </div>
        </div>
      </div>
    </>
  );
}
