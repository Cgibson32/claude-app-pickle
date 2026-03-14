/**
 * StorageService
 *
 * A thin, testable abstraction over localStorage.
 * All repositories use this — never call localStorage directly.
 * If you need a different storage backend (IndexedDB, Supabase cache, etc.)
 * swap the implementation here without touching repositories.
 */

/**
 * Namespaced storage keys.
 * Bump the version suffix when the data schema changes in a breaking way.
 */
export const STORAGE_KEYS = {
  PROFILE: 'pp_profile_v2',
  SESSIONS: 'pp_sessions_v2',
  INTENTIONS: 'pp_intentions_v1',
  AI_PLAN: 'pp_ai_plan_v1',
  SAVED_SKILLS: 'pp_saved_skills',
  APP_META: 'pp_app_meta_v1',
};

/**
 * Reads and JSON-parses a value from storage.
 * Returns `defaultValue` on any failure (missing key, parse error).
 *
 * @template T
 * @param {string} key
 * @param {T} defaultValue
 * @returns {T}
 */
export function storageGet(key, defaultValue = null) {
  try {
    const raw = localStorage.getItem(key);
    if (raw === null) return defaultValue;
    return JSON.parse(raw);
  } catch {
    return defaultValue;
  }
}

/**
 * JSON-serializes and writes a value to storage.
 * Returns true on success, false on failure.
 *
 * @param {string} key
 * @param {*} value
 * @returns {boolean}
 */
export function storageSet(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
    return true;
  } catch (err) {
    console.error(`[StorageService] Failed to write key "${key}":`, err);
    return false;
  }
}

/**
 * Removes a key from storage.
 *
 * @param {string} key
 */
export function storageRemove(key) {
  try {
    localStorage.removeItem(key);
  } catch (err) {
    console.error(`[StorageService] Failed to remove key "${key}":`, err);
  }
}

/**
 * Clears all PicklePro keys from storage.
 * Useful for full reset — does not clear unrelated keys.
 */
export function storageClearAll() {
  Object.values(STORAGE_KEYS).forEach(storageRemove);
}
