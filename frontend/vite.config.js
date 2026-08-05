import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'icons.svg', 'intro.mp4'],
      manifest: {
        name: 'CareConnect — Emergency Response & Resident Safety System',
        short_name: 'CareConnect',
        description: 'Community emergency response and safety system for seniors and residents.',
        theme_color: '#0f172a',
        background_color: '#0f172a',
        display: 'standalone',
        orientation: 'portrait',
        start_url: '/',
        icons: [
          {
            src: 'favicon.svg',
            sizes: '192x192 512x512',
            type: 'image/svg+xml',
            purpose: 'any'
          },
          {
            src: 'favicon.svg',
            sizes: '192x192',
            type: 'image/svg+xml',
            purpose: 'maskable'
          }
        ]
      }
    })
  ],
  server: {
    host: true,
    port: 5173,
    allowedHosts: true,
    proxy: {
      '/api/ai': {
        target: process.env.VITE_AI_URL || process.env.VITE_API_URL || 'https://care-connect-qtsk.vercel.app',
        changeOrigin: true
      },
      '/api': {
        target: process.env.VITE_API_URL || 'https://care-connect-qtsk.vercel.app',
        changeOrigin: true
      }
    }
  }
})
