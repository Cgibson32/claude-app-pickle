/**
 * ProfileRepository
 *
 * Handles all read/write operations for the player's profile.
 * Currently backed by localStorage via StorageService.
 * Set SUPABASE_ENABLED = true (in SupabaseClient.js) to route through Supabase instead.
 */

import { storageGet, storageSet, storageRemove, STORAGE_KEYS } from '../services/StorageService';
import { createUserProfile, updateUserProfile } from '../models/UserProfile';
import { SUPABASE_ENABLED, supabase } from '../services/SupabaseClient';

// ─── Local Storage Implementation ────────────────────────────────────────────

/**
 * Returns the current profile, or null if none exists.
 *
 * @returns {UserProfile|null}
 */
export function getProfile() {
  if (SUPABASE_ENABLED) return _supabaseGet();

  const raw = storageGet(STORAGE_KEYS.PROFILE, null);
  if (!raw) return null;
  // Normalize through factory in case schema has evolved
  return createUserProfile(raw);
}

/**
 * Saves a profile (full replace).
 *
 * @param {UserProfile} profile
 * @returns {UserProfile}
 */
export function saveProfile(profile) {
  if (SUPABASE_ENABLED) return _supabaseSave(profile);

  const normalized = createUserProfile(profile);
  storageSet(STORAGE_KEYS.PROFILE, normalized);
  return normalized;
}

/**
 * Applies a partial update to the existing profile.
 * Creates a new profile if none exists.
 *
 * @param {Partial<UserProfile>} updates
 * @returns {UserProfile}
 */
export function patchProfile(updates) {
  const existing = getProfile();
  const base = existing ?? createUserProfile({});
  const updated = updateUserProfile(base, updates);
  return saveProfile(updated);
}

/**
 * Deletes the stored profile.
 */
export function clearProfile() {
  if (SUPABASE_ENABLED) {
    console.warn('[ProfileRepository] Supabase clear not implemented');
    return;
  }
  storageRemove(STORAGE_KEYS.PROFILE);
}

// ─── Supabase Implementation Stubs ───────────────────────────────────────────
// Implement these when SUPABASE_ENABLED is true.

async function _supabaseGet() {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .single();

  if (error || !data) return null;
  return _fromSupabaseRow(data);
}

async function _supabaseSave(profile) {
  const row = _toSupabaseRow(profile);
  const { data, error } = await supabase
    .from('profiles')
    .upsert(row)
    .select()
    .single();

  if (error) throw new Error(`[ProfileRepository] Supabase save failed: ${error.message}`);
  return _fromSupabaseRow(data);
}

function _toSupabaseRow(profile) {
  return {
    id: profile.id,
    name: profile.name,
    level: profile.level,
    frequency: profile.frequency,
    struggles: profile.struggles,
    technical_weaknesses: profile.technicalWeaknesses,
    mental_weaknesses: profile.mentalWeaknesses,
    goals: profile.goals,
    player_type: profile.playerType,
    format: profile.format,
    onboarding_completed_at: profile.onboardingCompletedAt,
    updated_at: new Date().toISOString(),
  };
}

function _fromSupabaseRow(row) {
  return createUserProfile({
    id: row.id,
    name: row.name,
    level: row.level,
    frequency: row.frequency,
    struggles: row.struggles,
    technicalWeaknesses: row.technical_weaknesses,
    mentalWeaknesses: row.mental_weaknesses,
    goals: row.goals,
    playerType: row.player_type,
    format: row.format,
    onboardingCompletedAt: row.onboarding_completed_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  });
}
