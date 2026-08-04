import { useAuth } from '../hooks/useAuth.js';

export default function Topbar() {
  const { user, logout } = useAuth();

  const toggleTheme = () => {
    const cur = document.documentElement.getAttribute('data-theme');
    document.documentElement.setAttribute('data-theme', cur === 'dark' ? 'light' : 'dark');
  };

  return (
    <div className="topbar">
      <div className="brand-logo">
        <svg width="120" height="42" viewBox="0 0 200 60" xmlns="http://www.w3.org/2000/svg">
          <rect x="0" y="6" width="46" height="10" fill="currentColor"/>
          <rect x="0" y="22" width="34" height="10" fill="currentColor"/>
          <rect x="0" y="38" width="46" height="10" fill="currentColor"/>
          <text x="54" y="34" fontFamily="IBM Plex Sans, sans-serif" fontWeight="700" fontSize="22" fill="currentColor" letterSpacing="1">EDARA</text>
          <text x="54" y="48" fontFamily="Inter, sans-serif" fontWeight="500" fontSize="7" fill="currentColor" letterSpacing="1.5">A SODIC COMPANY</text>
        </svg>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, fontSize: 12, color: 'var(--muted)' }}>
        {user && <span>{user.fullName} · <b style={{ color: 'var(--accent)' }}>{user.role}</b></span>}
        <button
          onClick={toggleTheme}
          style={{ background: 'var(--surface-2)', border: '1px solid var(--border)', color: 'var(--text)', padding: '8px 12px', borderRadius: 8, fontSize: 12, fontWeight: 600 }}
        >Theme</button>
        <button
          onClick={logout}
          style={{ background: 'transparent', border: '1px solid var(--border)', color: 'var(--text)', padding: '8px 12px', borderRadius: 8, fontSize: 12, fontWeight: 600 }}
        >Sign out</button>
      </div>
    </div>
  );
}
