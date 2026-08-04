import { useState } from 'react';
import Topbar from '../components/Topbar.jsx';
import LiveView from '../components/LiveView.jsx';
import HistoryView from '../components/HistoryView.jsx';
import DriversView from '../components/DriversView.jsx';
import ReportsView from '../components/ReportsView.jsx';

export default function DashboardPage() {
  const [tab, setTab] = useState('live');
  const [search, setSearch] = useState('');

  return (
    <>
      <Topbar />
      <div className="dashboard-container">
        <div className="dashboard">
          <div className="dash-header">
            <div>
              <div className="dash-title-sub">Live operations</div>
              <div className="dash-title">Delivery control room</div>
            </div>
            <div className="dash-controls">
              <div className="search-box">
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search phone or plate..."
                />
              </div>
              <div className="dash-tabs">
                <button className={`dash-tab ${tab === 'live' ? 'active' : ''}`} onClick={() => setTab('live')}>Live</button>
                <button className={`dash-tab ${tab === 'history' ? 'active' : ''}`} onClick={() => setTab('history')}>History</button>
                <button className={`dash-tab ${tab === 'drivers' ? 'active' : ''}`} onClick={() => setTab('drivers')}>Drivers</button>
                <button className={`dash-tab ${tab === 'reports' ? 'active' : ''}`} onClick={() => setTab('reports')}>Reports</button>
              </div>
            </div>
          </div>

          {tab === 'live' && <LiveView search={search} />}
          {tab === 'history' && <HistoryView search={search} />}
          {tab === 'drivers' && <DriversView search={search} />}
          {tab === 'reports' && <ReportsView />}
        </div>
      </div>
    </>
  );
}
