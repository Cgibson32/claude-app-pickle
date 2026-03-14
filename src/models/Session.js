/**
 * Session model
 * A Session represents a single play session with all pre-play and post-play data.
 */

import { generateId } from '../utils/generateId';

/**
 * Creates a complete Session object with all defaults applied.
 * Any subset of fields can be passed — missing fields will be set to sensible defaults.
 *
 * @param {Partial<Session>} data
 * @returns {Session}
 */
export function createSession(data = {}) {
  return {
    id: data.id ?? generateId(),
    date: data.date ?? new Date().toISOString(),

    // Pre-play fields (captured before the match)
    gameType: data.gameType ?? '',
    prePlayMood: data.prePlayMood ?? '',
    energyLevel: data.energyLevel ?? 5,
    technicalIntent: data.technicalIntent ?? '',
    mentalIntent: data.mentalIntent ?? '',

    // Post-play ratings
    rating: data.rating ?? 0,         // 1-5 stars
    skillFocus: data.skillFocus ?? '', // what they actually worked on

    // Post-play reflection text
    wentWell: data.wentWell ?? '',
    improveFocus: data.improveFocus ?? '',
    highlights: data.highlights ?? '',
    ahamoment: data.ahamoment ?? '',
    coachCue: data.coachCue ?? '',

    // Post-play process scores (1-10)
    patienceScore: data.patienceScore ?? 0,
    patienceNotes: data.patienceNotes ?? '',
    emotionsScore: data.emotionsScore ?? 0,
    emotionsNotes: data.emotionsNotes ?? '',
    communicationScore: data.communicationScore ?? 0,

    // Metadata
    isPostPlayComplete: data.isPostPlayComplete ?? false,
    createdAt: data.createdAt ?? new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
}

/**
 * Merges post-play reflection data into a session.
 *
 * @param {Session} session
 * @param {Partial<Session>} reflectionData
 * @returns {Session}
 */
export function completeSessionReflection(session, reflectionData) {
  return {
    ...session,
    ...reflectionData,
    id: session.id,
    date: session.date,
    isPostPlayComplete: true,
    updatedAt: new Date().toISOString(),
  };
}

/**
 * Computes an overall process score from a session's individual scores.
 * Returns null if the session has no scores yet.
 *
 * @param {Session} session
 * @returns {number|null}
 */
export function calcProcessScore(session) {
  const scores = [
    session.patienceScore,
    session.emotionsScore,
    session.communicationScore,
  ].filter(s => s > 0);

  if (!scores.length) return null;
  return parseFloat((scores.reduce((a, b) => a + b, 0) / scores.length).toFixed(1));
}

/**
 * Returns the date portion (YYYY-MM-DD) of a session's date.
 *
 * @param {Session} session
 * @returns {string}
 */
export function getSessionDateKey(session) {
  return session.date.split('T')[0];
}

/**
 * Returns true if the session was played on today's date.
 *
 * @param {Session} session
 * @returns {boolean}
 */
export function isSessionToday(session) {
  const today = new Date().toISOString().split('T')[0];
  return getSessionDateKey(session) === today;
}
