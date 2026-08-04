import React, { useEffect, useState } from 'react';
import api from '../api/client.js';

export default function DriversView({ search }) {
  const [rows, setRows] = useState([]);
  const [filters, setFilters] = useState({ status: '', plate: '', phone: '' });
  const [expandedId, setExpandedId] = useState(null);

  const load = async () => {
    const params = { ...filters, search: search || undefined };
    Object.keys(params).forEach((k) => (!params[k] || params[k] === '') && delete params[k]);
    const { data } = await api.get('/admin/drivers', { params });
    setRows(data.drivers);
  };

  useEffect(() => { load(); }, [filters, search]);

  const handleExport = () => {
    const params = new URLSearchParams();
    Object.entries(filters).forEach(([k, v]) => { if (v) params.set(k, v); });
    if (search) params.set('search', search);
    const token = localStorage.getItem('edara_token');
    fetch(`/api/v1/admin/export/drivers.csv?${params.toString()}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
      .then((r) => r.blob())
      .then((blob) => {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `edara-drivers-${Date.now()}.csv`;
        a.click();
        URL.revokeObjectURL(url);
      });
  };

  const badgeCls = (s) => s === 'verified' ? 'badge-ok' : s === 'pending' ? 'badge-warn' : 'badge-crit';

  return (
    <>
      <div className="filters-bar">
        <label>Status</label>
        <select value={filters.status} onChange={(e) => setFilters({ ...filters, status: e.target.value })}>
          <option value="">All</option>
          <option value="verified">Verified</option>
          <option value="pending">Pending</option>
          <option value="revoked">Revoked</option>
        </select>
        <label>Plate</label>
        <input type="text" value={filters.plate} placeholder="MSR 4429" onChange={(e) => setFilters({ ...filters, plate: e.target.value })} />
        <label>Phone</label>
        <input type="text" value={filters.phone} placeholder="+20..." onChange={(e) => setFilters({ ...filters, phone: e.target.value })} />
        <button className="btn-export" onClick={handleExport}>Export CSV</button>
      </div>
      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>
              <th>Name</th><th>Phone</th><th>Plate</th><th>Status</th><th>Deliveries</th><th>Registered</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <React.Fragment key={r.id}>
                <tr onClick={() => setExpandedId(expandedId === r.id ? null : r.id)} style={{ cursor: 'pointer' }}>
                  <td>{r.full_name}</td>
                  <td className="mono">{r.phone}</td>
                  <td className="mono">{r.plate_number}</td>
                  <td><span className={`badge ${badgeCls(r.status)}`}>{r.status}</span></td>
                  <td>{r.total_deliveries}</td>
                  <td>{new Date(r.created_at).toLocaleDateString()}</td>
                </tr>
                {expandedId === r.id && (
                  <tr>
                    <td colSpan="6" style={{ background: 'var(--surface2)', padding: 20 }}>
                      <h4 style={{ marginBottom: 12, fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Driver Documents</h4>
                      {r.id_doc_path ? (
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 20 }}>
                          <div>
                            <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 4 }}>Selfie</div>
                            <img src={`http://localhost:4000${r.selfie_path}`} alt="Selfie" style={{ width: '100%', height: 160, objectFit: 'cover', borderRadius: 8 }} />
                            <div style={{ fontSize: 11, marginTop: 4, color: r.face_match_score >= 90 ? 'var(--ok)' : 'var(--warn)' }}>
                              Face Match Score: {r.face_match_score}%
                            </div>
                          </div>
                          <div>
                            <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 4 }}>ID Document</div>
                            <img src={`http://localhost:4000${r.id_doc_path}`} alt="ID Document" style={{ width: '100%', height: 160, objectFit: 'cover', borderRadius: 8 }} />
                          </div>
                          <div>
                            <div style={{ fontSize: 12, color: 'var(--muted)', marginBottom: 4 }}>License Document</div>
                            <img src={`http://localhost:4000${r.license_doc_path}`} alt="License Document" style={{ width: '100%', height: 160, objectFit: 'cover', borderRadius: 8 }} />
                          </div>
                        </div>
                      ) : (
                        <div style={{ color: 'var(--muted)', fontStyle: 'italic' }}>No documents uploaded yet.</div>
                      )}
                    </td>
                  </tr>
                )}
              </React.Fragment>
            ))}
            {rows.length === 0 && <tr><td colSpan="6" style={{ textAlign: 'center', padding: 40, color: 'var(--muted)' }}>No results.</td></tr>}
          </tbody>
        </table>
      </div>
    </>
  );
}
