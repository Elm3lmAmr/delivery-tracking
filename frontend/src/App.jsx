import { Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage.jsx';
import DashboardPage from './pages/DashboardPage.jsx';
import { useAuth } from './hooks/useAuth.js';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import 'leaflet/dist/leaflet.css';

function ProtectedRoute({ children }) {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  return children;
}

export default function App() {
  return (
    <>
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/" element={
        <ProtectedRoute><DashboardPage /></ProtectedRoute>
      } />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
    <ToastContainer position="top-right" autoClose={5000} theme="dark" />
    </>
  );
}
