/**
 * AuthService
 *
 * Authentication abstraction layer.
 * Currently uses local-only anonymous auth (no backend required).
 * Set SUPABASE_ENABLED = true in SupabaseClient.js to activate Supabase Auth.
 *
 * ─── SETUP WHEN READY ─────────────────────────────────────────────────────────
 *
 * 1. Activate Supabase in SupabaseClient.js
 * 2. Enable your preferred auth providers in the Supabase dashboard:
 *    - Email/Password (default)
 *    - Apple Sign-In (required for iOS App Store if any social login is offered)
 *    - Google Sign-In (optional)
 * 3. For Apple Sign-In:
 *    - Register a Services ID at developer.apple.com
 *    - Add the callback URL from Supabase Auth settings
 *    - Install: npm install @capacitor-community/apple-sign-in
 *
 * ────────────────────────────────────────────────────────────────────────────────
 */

import { SUPABASE_ENABLED, supabase } from './SupabaseClient';
import { storageGet, storageSet, STORAGE_KEYS } from './StorageService';
import { generateId } from '../utils/generateId';

// ─── Public API ──────────────────────────────────────────────────────────────

/**
 * Returns the current authenticated user, or null.
 * In local mode, returns the anonymous user from storage.
 *
 * @returns {Promise<AuthUser|null>}
 */
export async function getCurrentUser() {
  if (SUPABASE_ENABLED) {
    const { data } = await supabase.auth.getUser();
    return data.user ? _mapSupabaseUser(data.user) : null;
  }
  return _getLocalUser();
}

/**
 * Signs in with email and password.
 * In local mode, creates/returns an anonymous user.
 *
 * @param {string} email
 * @param {string} password
 * @returns {Promise<AuthUser>}
 */
export async function signInWithEmail(email, password) {
  if (SUPABASE_ENABLED) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw new Error(error.message);
    return _mapSupabaseUser(data.user);
  }
  return _getOrCreateLocalUser(email);
}

/**
 * Creates a new account with email and password.
 *
 * @param {string} email
 * @param {string} password
 * @returns {Promise<AuthUser>}
 */
export async function signUpWithEmail(email, password) {
  if (SUPABASE_ENABLED) {
    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) throw new Error(error.message);
    return _mapSupabaseUser(data.user);
  }
  return _getOrCreateLocalUser(email);
}

/**
 * Signs in with Apple (required for App Store if any social auth is offered).
 * Requires: npm install @capacitor-community/apple-sign-in
 *
 * @returns {Promise<AuthUser>}
 */
export async function signInWithApple() {
  if (!SUPABASE_ENABLED) {
    return _getOrCreateLocalUser('apple-user@local');
  }

  // Dynamic import — only loaded when actually called
  const { SignInWithApple } = await import('@capacitor-community/apple-sign-in');
  const result = await SignInWithApple.authorize({
    clientId: 'com.picklepro.app',
    redirectURI: '', // Set from Supabase dashboard
    scopes: 'email name',
  });

  const { data, error } = await supabase.auth.signInWithIdToken({
    provider: 'apple',
    token: result.response.identityToken,
  });

  if (error) throw new Error(error.message);
  return _mapSupabaseUser(data.user);
}

/**
 * Signs out the current user.
 */
export async function signOut() {
  if (SUPABASE_ENABLED) {
    await supabase.auth.signOut();
    return;
  }
  storageSet(STORAGE_KEYS.APP_META, { ...storageGet(STORAGE_KEYS.APP_META, {}), authUser: null });
}

/**
 * Registers a callback for auth state changes.
 *
 * @param {(user: AuthUser|null) => void} callback
 * @returns {() => void} unsubscribe function
 */
export function onAuthStateChange(callback) {
  if (SUPABASE_ENABLED) {
    const { data } = supabase.auth.onAuthStateChange((_event, session) => {
      callback(session?.user ? _mapSupabaseUser(session.user) : null);
    });
    return () => data.subscription.unsubscribe();
  }
  // Local mode: no real-time auth changes
  return () => {};
}

// ─── Internal Helpers ────────────────────────────────────────────────────────

function _getLocalUser() {
  const meta = storageGet(STORAGE_KEYS.APP_META, {});
  return meta.authUser || null;
}

function _getOrCreateLocalUser(email) {
  const existing = _getLocalUser();
  if (existing) return existing;

  const user = {
    id: generateId(),
    email: email || 'local@picklepro.app',
    provider: 'local',
    createdAt: new Date().toISOString(),
  };

  storageSet(STORAGE_KEYS.APP_META, {
    ...storageGet(STORAGE_KEYS.APP_META, {}),
    authUser: user,
  });

  return user;
}

function _mapSupabaseUser(supaUser) {
  return {
    id: supaUser.id,
    email: supaUser.email,
    provider: supaUser.app_metadata?.provider || 'email',
    createdAt: supaUser.created_at,
  };
}
