import axios from 'axios';

const api = axios.create({
  baseURL: '/api/v1',
  timeout: 15000
});

// Attach token to every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('edara_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Handle 401 -> redirect to login
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response && err.response.status === 401) {
      localStorage.removeItem('edara_token');
      localStorage.removeItem('edara_user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(err);
  }
);

export default api;
