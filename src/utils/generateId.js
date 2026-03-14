/**
 * Generates a short, unique ID string.
 * Uses crypto.randomUUID when available, falls back to a timestamp+random combo.
 *
 * @returns {string}
 */
export function generateId() {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  // Fallback for environments without crypto.randomUUID
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 9)}`;
}
