import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig(({ mode }) => ({
  plugins: [react()],
  build: {
    // Capacitor expects the web build in 'dist' (matches capacitor.config.ts webDir)
    outDir: 'dist',
    // Generate sourcemaps for debugging in native WebView
    sourcemap: mode !== 'production',
  },
}))
