/**
 * IntentionRepository
 *
 * Handles all read/write operations for daily intentions.
 * One intention per calendar day — upsert semantics.
 * Currently backed by localStorage via StorageService.
 * Set SUPABASE_ENABLED = true (in SupabaseClient.js) to route through Supabase instead.
 */

import { storageGet, storageSet, STORAGE_KEYS } from '../services/StorageService';
import { createIntention, getTodayDateKey, isIntentionToday } from '../models/Intention';
import { SUPABASE_ENABLED, supabase } from '../services/SupabaseClient';

// ─── Local Storage Implementation ────────────────────────────────────────────

/**
 * Returns all stored intentions, sorted newest first.
 *
 * @returns {Intention[]}
 */
export function getAll() {
  if (SUPABASE_ENABLED) return _supabaseGetAll();

  const raw = storageGet(STORAGE_KEYS.INTENTIONS, []);
  return raw.map(createIntention).sort((a, b) => new Date(b.date) - new Date(a.date));
}

/**
 * Returns today's intention, or null if none has been set.
 *
 * @returns {Intention|null}
 */
export function getTodayIntention() {
  if (SUPABASE_ENABLED) return _supabaseGetByDate(getTodayDateKey());

  const all = storageGet(STORAGE_KEYS.INTENTIONS, []);
  const found = all.find(i => isIntentionToday(createIntention(i)));
  return found ? createIntention(found) : null;
}

/**
 * Returns the intention for a specific date key (YYYY-MM-DD), or null.
 *
 * @param {string} dateKey
 * @returns {Intention|null}
 */
export function getByDateKey(dateKey) {
  if (SUPABASE_ENABLED) return _supabaseGetByDate(dateKey);

  const all = storageGet(STORAGE_KEYS.INTENTIONS, []);
  const found = all.find(i => i.date === dateKey);
  return found ? createIntention(found) : null;
}

/**
 * Saves (upserts) an intention. One per day — if an intention already exists
 * for the same date it is replaced; otherwise appended.
 *
 * @param {Intention} intention
 * @returns {Intention}
 */
export function save(intention) {
  if (SUPABASE_ENABLED) return _supabaseSave(intention);

  const normalized = createIntention(intention);
  const all = storageGet(STORAGE_KEYS.INTENTIONS, []);
  const idx = all.findIndex(i => i.date === normalized.date);

  if (idx >= 0) {
    all[idx] = normalized;
  } else {
    all.push(normalized);
  }

  storageSet(STORAGE_KEYS.INTENTIONS, all);
  return normalized;
}

// ─── Supabase Implementation Stubs ───────────────────────────────────────────

async function _supabaseGetAll() {
  const { data, error } = await supabase
    .from('intentions')
    .select('*')
    .order('date', { ascending: false });

  if (error || !data) return [];
  return data.map(_fromSupabaseRow);
}

async function _supabaseGetByDate(dateKey) {
  const { data, error } = await supabase
    .from('intentions')
    .select('*')
    .eq('date', dateKey)
    .single();

  if (error || !data) return null;
  return _fromSupabaseRow(data);
}

async function _supabaseSave(intention) {
  const row = _toSupabaseRow(intention);
  const { data, error } = await supabase
    .from('intentions')
    .upsert(row, { onConflict: 'date' })
    .select()
    .single();

  if (error) throw new Error(`[IntentionRepository] Supabase save failed: ${error.message}`);
  return _fromSupabaseRow(data);
}

function _toSupabaseRow(intention) {
  return {
    id: intention.id,
    date: intention.date,
    theme: intention.theme,
    performance: intention.performance,
    mental: intention.mental,
    joy: intention.joy,
    quote: intention.quote,
    cue: intention.cue,
    technical_focus: intention.technicalFocus,
    mental_focus: intention.mentalFocus,
    game_type: intention.gameType,
    pre_play_mood: intention.prePlayMood,
    energy_level: intention.energyLevel,
  };
}

function _fromSupabaseRow(row) {
  return createIntention({
    id: row.id,
    date: row.date,
    theme: row.theme,
    performance: row.performance,
    mental: row.mental,
    joy: row.joy,
    quote: row.quote,
    cue: row.cue,
    technicalFocus: row.technical_focus,
    mentalFocus: row.mental_focus,
    gameType: row.game_type,
    prePlayMood: row.pre_play_mood,
    energyLevel: row.energy_level,
    createdAt: row.created_at,
  });
}
