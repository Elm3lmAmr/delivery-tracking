import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth.js';

export default function LoginPage() {
  const [email, setEmail] = useState('admin@edara.com');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const login = useAuth((s) => s.login);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      await login(email, password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-card">
      <h2>Edara Delivery Tracking</h2>
      <p>Sign in to access the operations dashboard</p>
      {error && <div className="error-msg">{error}</div>}
      <form onSubmit={handleSubmit}>
        <label>Email</label>
        <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        <label>Password</label>
        <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        <button type="submit" disabled={loading}>{loading ? 'Signing in...' : 'Sign in'}</button>
      </form>
    </div>
  );
}
