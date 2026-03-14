import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.picklepro.app',
  appName: 'PicklePro',
  webDir: 'dist',
  server: {
    // Enable for local dev with live reload (disable for production)
    // url: 'http://YOUR_LOCAL_IP:5173',
    // cleartext: true,
  },
  ios: {
    // Content inset behavior for keyboard
    contentInset: 'automatic',
    // Allow inline media playback
    allowsLinkPreview: false,
    // Background color matches our dark theme
    backgroundColor: '#0a0a0a',
    // Preferred status bar style
    preferredContentMode: 'mobile',
    scheme: 'PicklePro',
  },
  plugins: {
    SplashScreen: {
      launchAutoHide: false, // We control hide timing from JS
      backgroundColor: '#0a0a0a',
      showSpinner: false,
      androidScaleType: 'CENTER_CROP',
      splashFullScreen: true,
      splashImmersive: true,
      layoutName: 'launch_screen',
      useDialog: false,
    },
    StatusBar: {
      style: 'LIGHT', // Light text on dark background
      backgroundColor: '#0a0a0a',
    },
    Keyboard: {
      resize: 'body',
      resizeOnFullScreen: true,
    },
  },
};

export default config;
