import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': { target: 'http://localhost:4000', changeOrigin: true },
      '/socket.io': { 
        target: 'http://localhost:4000', 
        changeOrigin: true, 
        ws: true,
        configure: (proxy, options) => {
          proxy.on('error', () => { /* ignore */ });
          proxy.on('proxyReqWs', (proxyReq, req, socket, options, head) => {
            socket.on('error', () => { /* ignore */ });
          });
        }
      },
      '/uploads': { target: 'http://localhost:4000', changeOrigin: true }
    }
  }
});
