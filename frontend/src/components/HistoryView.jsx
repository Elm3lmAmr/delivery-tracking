import { useEffect, useState } from 'react';
import api from '../api/client.js';

const STATUS_OPTIONS = ['', 'completed', 'expired', 'rejected'];

export default function HistoryView({ search }) {
  const [rows, setRows] = useState([]);
  const [projects, setProjects] = useState([]);
  const [filters, setFilters] = useState({
    project_id: '', status: '', from: '', to: '', plate: '', phone: ''
  });

  const load = async () => {
    const params = { ...filters, search: search || undefined };
    Object.keys(params).forEach((k) => (!params[k] || params[k] === '') && delete params[k]);
    const { data } = await api.get('/admin/history', { params });
    setRows(data.deliveries);
  };

  useEffect(() => { load(); }, [filters, search]);

  const handleExport = () => {
    const params = new URLSearchParams();
    Object.entries(filters).forEach(([k, v]) => { if (v) params.set(k, v); });
    if (search) params.set('search', search);
    const token = localStorage.getItem('edara_token');
    // Direct download with auth via query - simplest cross-browser approach for demo:
    // For production, use a signed one-time export token endpoint instead
    fetch(`/api/v1/admin/export/history.csv?${params.toString()}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
      .then((r) => r.blob())
      .then((blob) => {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `edara-history-${Date.now()}.csv`;
        a.click();
        URL.revokeObjectURL(url);
      });
  };

  return (
    <>
      <div className="filters-bar">
        <label>Project</label>
        <select value={filters.project_id} onChange={(e) => setFilters({ ...filters, project_id: e.target.value })}>
          <option value="">All</option>
          {projects.map((p) => <option key={p.id} value={p.id}>{p.name_en}</option>)}
        </select>
        <label>Status</label>
        <select value={filters.status} onChange={(e) => setFilters({ ...filters, status: e.target.value })}>
          {STATUS_OPTIONS.map((s) => <option key={s} value={s}>{s || 'All'}</option>)}
        </select>
        <label>Plate</label>
        <input type="text" value={filters.plate} placeholder="MSR 4429" onChange={(e) => setFilters({ ...filters, plate: e.target.value })} />
        <label>Phone</label>
        <input type="text" value={filters.phone} placeholder="+20..." onChange={(e) => setFilters({ ...filters, phone: e.target.value })} />
        <label>From</label>
        <input type="date" value={filters.from} onChange={(e) => setFilters({ ...filters, from: e.target.value })} />
        <label>To</label>
        <input type="date" value={filters.to} onChange={(e) => setFilters({ ...filters, to: e.target.value })} />
        <button className="btn-export" onClick={handleExport}>Export CSV</button>
      </div>
      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>When</th><th>Driver</th><th>Phone</th><th>Plate</th>
              <th>Destination</th><th>Gate</th><th>Duration</th><th>Status</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id}>
                <td>{new Date(r.entered_at || r.created_at).toLocaleString()}</td>
                <td>{r.driver}</td>
                <td className="mono">{r.phone}</td>
                <td className="mono">{r.plate_number}</td>
                <td>{r.project} · {r.unit}</td>
                <td>{r.gate}</td>
                <td className="mono">{r.duration_seconds ? `${Math.floor(r.duration_seconds / 60)}m ${r.duration_seconds % 60}s` : '-'}</td>
                <td><span className={`badge badge-${r.status === 'completed' ? 'ok' : 'warn'}`}>{r.status}</span></td>
              </tr>
            ))}
            {rows.length === 0 && <tr><td colSpan="8" style={{ textAlign: 'center', padding: 40, color: 'var(--muted)' }}>No results.</td></tr>}
          </tbody>
        </table>
      </div>
    </>
  );
}
