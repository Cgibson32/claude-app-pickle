/**
 * SessionRepository
 *
 * Handles all read/write operations for play sessions.
 * Currently backed by localStorage via StorageService.
 * Set SUPABASE_ENABLED = true (in SupabaseClient.js) to route through Supabase instead.
 */

import { storageGet, storageSet, STORAGE_KEYS } from '../services/StorageService';
import { createSession, getSessionDateKey, isSessionToday } from '../models/Session';
import { SUPABASE_ENABLED, supabase } from '../services/SupabaseClient';

// ─── Local Storage Implementation ────────────────────────────────────────────

/**
 * Returns all sessions, sorted newest first.
 *
 * @returns {Session[]}
 */
export function getAll() {
  if (SUPABASE_ENABLED) return _supabaseGetAll();

  const raw = storageGet(STORAGE_KEYS.SESSIONS, []);
  return raw.map(createSession).sort((a, b) => new Date(b.date) - new Date(a.date));
}

/**
 * Returns a single session by id, or null if not found.
 *
 * @param {string} id
 * @returns {Session|null}
 */
export function getById(id) {
  if (SUPABASE_ENABLED) return _supabaseGetById(id);

  const all = storageGet(STORAGE_KEYS.SESSIONS, []);
  const found = all.find(s => s.id === id);
  return found ? createSession(found) : null;
}

/**
 * Returns all sessions for a given date key (YYYY-MM-DD).
 *
 * @param {string} dateKey — e.g. '2025-03-14'
 * @returns {Session[]}
 */
export function getByDateKey(dateKey) {
  const all = getAll();
  return all.filter(s => getSessionDateKey(s) === dateKey);
}

/**
 * Returns the n most recent sessions, sorted newest first.
 *
 * @param {number} n
 * @returns {Session[]}
 */
export function getRecent(n = 5) {
  return getAll().slice(0, n);
}

/**
 * Returns today's session, or null if none has been started yet.
 * If multiple exist for today, returns the most recent.
 *
 * @returns {Session|null}
 */
export function getTodaySession() {
  const all = getAll();
  const todays = all.filter(isSessionToday);
  return todays[0] ?? null;
}

/**
 * Saves (upserts) a session. If a session with the same id exists it is replaced;
 * otherwise the session is appended.
 *
 * @param {Session} session
 * @returns {Session}
 */
export function save(session) {
  if (SUPABASE_ENABLED) return _supabaseSave(session);

  const normalized = createSession(session);
  const all = storageGet(STORAGE_KEYS.SESSIONS, []);
  const idx = all.findIndex(s => s.id === normalized.id);

  if (idx >= 0) {
    all[idx] = normalized;
  } else {
    all.push(normalized);
  }

  storageSet(STORAGE_KEYS.SESSIONS, all);
  return normalized;
}

/**
 * Removes a session by id. No-op if the id is not found.
 *
 * @param {string} id
 */
export function deleteById(id) {
  const all = storageGet(STORAGE_KEYS.SESSIONS, []);
  const filtered = all.filter(s => s.id !== id);
  storageSet(STORAGE_KEYS.SESSIONS, filtered);
}

/**
 * Calculates the current consecutive-day streak.
 * A day counts if at least one session was played on it.
 *
 * @returns {number}
 */
export function calcStreak() {
  const all = getAll();
  if (!all.length) return 0;

  // Build a Set of date keys that have sessions
  const daySet = new Set(all.map(getSessionDateKey));

  let streak = 0;
  const cursor = new Date();

  // Start from today; if today has no session, check if yesterday does
  // (a streak can still be alive if today hasn't been played yet)
  const todayKey = cursor.toISOString().split('T')[0];
  if (!daySet.has(todayKey)) {
    cursor.setDate(cursor.getDate() - 1);
  }

  while (true) {
    const key = cursor.toISOString().split('T')[0];
    if (!daySet.has(key)) break;
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }

  return streak;
}

// ─── Supabase Implementation Stubs ───────────────────────────────────────────

async function _supabaseGetAll() {
  const { data, error } = await supabase
    .from('sessions')
    .select('*')
    .order('date', { ascending: false });

  if (error || !data) return [];
  return data.map(_fromSupabaseRow);
}

async function _supabaseGetById(id) {
  const { data, error } = await supabase
    .from('sessions')
    .select('*')
    .eq('id', id)
    .single();

  if (error || !data) return null;
  return _fromSupabaseRow(data);
}

async function _supabaseSave(session) {
  const row = _toSupabaseRow(session);
  const { data, error } = await supabase
    .from('sessions')
    .upsert(row)
    .select()
    .single();

  if (error) throw new Error(`[SessionRepository] Supabase save failed: ${error.message}`);
  return _fromSupabaseRow(data);
}

function _toSupabaseRow(session) {
  return {
    id: session.id,
    date: session.date,
    game_type: session.gameType,
    pre_play_mood: session.prePlayMood,
    energy_level: session.energyLevel,
    technical_intent: session.technicalIntent,
    mental_intent: session.mentalIntent,
    rating: session.rating,
    skill_focus: session.skillFocus,
    went_well: session.wentWell,
    improve_focus: session.improveFocus,
    highlights: session.highlights,
    ahamoment: session.ahamoment,
    coach_cue: session.coachCue,
    patience_score: session.patienceScore,
    patience_notes: session.patienceNotes,
    emotions_score: session.emotionsScore,
    emotions_notes: session.emotionsNotes,
    communication_score: session.communicationScore,
    is_post_play_complete: session.isPostPlayComplete,
    updated_at: new Date().toISOString(),
  };
}

function _fromSupabaseRow(row) {
  return createSession({
    id: row.id,
    date: row.date,
    gameType: row.game_type,
    prePlayMood: row.pre_play_mood,
    energyLevel: row.energy_level,
    technicalIntent: row.technical_intent,
    mentalIntent: row.mental_intent,
    rating: row.rating,
    skillFocus: row.skill_focus,
    wentWell: row.went_well,
    improveFocus: row.improve_focus,
    highlights: row.highlights,
    ahamoment: row.ahamoment,
    coachCue: row.coach_cue,
    patienceScore: row.patience_score,
    patienceNotes: row.patience_notes,
    emotionsScore: row.emotions_score,
    emotionsNotes: row.emotions_notes,
    communicationScore: row.communication_score,
    isPostPlayComplete: row.is_post_play_complete,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  });
}
