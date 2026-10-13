import axios from 'axios';

const api = axios.create({ baseURL: '/api' });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (r) => r,
  (err) => {
    const status = err.response?.status;
    const url = err.config?.url || '';

    // Only force sign-out on protected endpoints, and only if already logged in
    const isAuthAttempt = url.includes('/auth/login') || url.includes('/entities/');
    const hasToken = !!localStorage.getItem('token');

    if (status === 401 && !isAuthAttempt && hasToken) {
      console.warn('[api] 401 on', url, '→ signing out');
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.hash = '#/login';
    }

    return Promise.reject(err);
  }
);

export default api;
