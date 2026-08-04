import { create } from 'zustand';
import api from '../api/client.js';

export const useAuth = create((set) => ({
  user: JSON.parse(localStorage.getItem('edara_user') || 'null'),
  token: localStorage.getItem('edara_token'),

  login: async (email, password) => {
    const { data } = await api.post('/auth/login', { email, password });
    localStorage.setItem('edara_token', data.token);
    localStorage.setItem('edara_user', JSON.stringify(data.user));
    set({ user: data.user, token: data.token });
    return data.user;
  },

  logout: () => {
    localStorage.removeItem('edara_token');
    localStorage.removeItem('edara_user');
    set({ user: null, token: null });
    window.location.href = '/login';
  }
}));
