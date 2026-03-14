/**
 * NativeService
 *
 * Abstracts native device capabilities via Capacitor plugins.
 * Falls back to no-ops on web so the app works in both contexts.
 *
 * Usage:
 *   import { initNative, haptic, hideSpinner } from '../services/NativeService';
 *   await initNative(); // call once on app mount
 */

import { Capacitor } from '@capacitor/core';

// ─── Platform Detection ──────────────────────────────────────────────────────

/** True when running inside a native Capacitor shell (iOS/Android) */
export const isNative = Capacitor.isNativePlatform();

/** True specifically on iOS */
export const isIOS = Capacitor.getPlatform() === 'ios';

// ─── Init ────────────────────────────────────────────────────────────────────

/**
 * One-time native initialization. Call in App mount.
 * Sets up status bar, hides splash screen, registers keyboard listeners.
 */
export async function initNative() {
  if (!isNative) return;

  // Add marker class for CSS safe-area targeting
  document.documentElement.classList.add('capacitor-app');

  try {
    // Status bar: light content on dark background
    const { StatusBar, Style } = await import('@capacitor/status-bar');
    await StatusBar.setStyle({ style: Style.Dark });
    await StatusBar.setBackgroundColor({ color: '#0a0a0a' });
  } catch {
    // Plugin not available — no-op
  }

  try {
    // Hide splash screen after a short delay to let React render
    const { SplashScreen } = await import('@capacitor/splash-screen');
    setTimeout(() => SplashScreen.hide({ fadeOutDuration: 300 }), 400);
  } catch {
    // Plugin not available — no-op
  }

  try {
    // iOS keyboard handling: add body class when keyboard is open
    const { Keyboard } = await import('@capacitor/keyboard');
    Keyboard.addListener('keyboardWillShow', () => {
      document.body.classList.add('keyboard-open');
    });
    Keyboard.addListener('keyboardWillHide', () => {
      document.body.classList.remove('keyboard-open');
    });
  } catch {
    // Plugin not available — no-op
  }

  try {
    // Handle hardware back button / app URL events
    const { App } = await import('@capacitor/app');
    App.addListener('backButton', ({ canGoBack }) => {
      if (canGoBack) {
        window.history.back();
      }
    });
  } catch {
    // Plugin not available — no-op
  }
}

// ─── Haptics ─────────────────────────────────────────────────────────────────

/**
 * Triggers a light haptic tap. Use on button presses for native feel.
 * No-op on web.
 */
export async function hapticLight() {
  if (!isNative) return;
  try {
    const { Haptics, ImpactStyle } = await import('@capacitor/haptics');
    await Haptics.impact({ style: ImpactStyle.Light });
  } catch {
    // no-op
  }
}

/**
 * Triggers a medium haptic impact. Use on significant actions (save, delete).
 */
export async function hapticMedium() {
  if (!isNative) return;
  try {
    const { Haptics, ImpactStyle } = await import('@capacitor/haptics');
    await Haptics.impact({ style: ImpactStyle.Medium });
  } catch {
    // no-op
  }
}

/**
 * Triggers a success notification haptic. Use on completions.
 */
export async function hapticSuccess() {
  if (!isNative) return;
  try {
    const { Haptics, NotificationType } = await import('@capacitor/haptics');
    await Haptics.notification({ type: NotificationType.Success });
  } catch {
    // no-op
  }
}

// ─── Status Bar ──────────────────────────────────────────────────────────────

/**
 * Hides the status bar for immersive screens (onboarding, splash).
 */
export async function hideStatusBar() {
  if (!isNative) return;
  try {
    const { StatusBar } = await import('@capacitor/status-bar');
    await StatusBar.hide();
  } catch {
    // no-op
  }
}

/**
 * Shows the status bar.
 */
export async function showStatusBar() {
  if (!isNative) return;
  try {
    const { StatusBar } = await import('@capacitor/status-bar');
    await StatusBar.show();
  } catch {
    // no-op
  }
}
