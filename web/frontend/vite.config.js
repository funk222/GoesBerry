import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: {
      '/api':      'http://localhost:8080',
      '/products': 'http://localhost:8080',
      '/cache':    'http://localhost:8080',
    },
  },
  build: {
    outDir:        'dist',
    emptyOutDir:   true,
    sourcemap:     false,
  },
});
