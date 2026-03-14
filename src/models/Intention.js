/**
 * Intention model
 * A daily intention record — saved when a user completes the pre-play flow.
 * Separate from Session so intentions can exist even without a logged match.
 */

import { generateId } from '../utils/generateId';

/**
 * Creates a complete Intention object.
 *
 * @param {Partial<Intention>} data
 * @returns {Intention}
 */
export function createIntention(data = {}) {
  const today = new Date().toISOString().split('T')[0];

  return {
    id: data.id ?? generateId(),

    // The calendar date this intention is for (YYYY-MM-DD)
    date: data.date ?? today,

    // From the rotating daily intention template
    theme: data.theme ?? '',
    performance: data.performance ?? '',
    mental: data.mental ?? '',
    joy: data.joy ?? '',
    quote: data.quote ?? '',
    cue: data.cue ?? '',

    // User-authored additions from the pre-play flow
    technicalFocus: data.technicalFocus ?? '',
    mentalFocus: data.mentalFocus ?? '',
    gameType: data.gameType ?? '',
    prePlayMood: data.prePlayMood ?? '',
    energyLevel: data.energyLevel ?? 5,

    // Metadata
    createdAt: data.createdAt ?? new Date().toISOString(),
  };
}

/**
 * Returns today's date key (YYYY-MM-DD).
 *
 * @returns {string}
 */
export function getTodayDateKey() {
  return new Date().toISOString().split('T')[0];
}

/**
 * Returns true if the intention is for today.
 *
 * @param {Intention} intention
 * @returns {boolean}
 */
export function isIntentionToday(intention) {
  return intention.date === getTodayDateKey();
}

/**
 * Returns true if the intention has meaningful user content beyond the template.
 *
 * @param {Intention} intention
 * @returns {boolean}
 */
export function hasUserContent(intention) {
  return !!(intention.technicalFocus || intention.mentalFocus);
}
