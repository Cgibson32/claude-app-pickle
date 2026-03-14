/**
 * UserProfile model
 * Factory, validation, and schema for the player profile.
 * This is the single source of truth for what a profile looks like.
 */

import { generateId } from '../utils/generateId';

/**
 * Valid values for profile fields.
 * Used for validation and as documentation of accepted values.
 */
export const PROFILE_SCHEMA = {
  levels: ['beginner', 'intermediate', 'advanced', 'competitive'],
  frequencies: ['rarely', 'weekly', 'frequent', 'daily'],
  formats: ['doubles', 'singles', 'both'],
  playerTypes: ['patient', 'aggressive', 'all-around', 'teammate'],
};

/**
 * Creates a fully-typed, defaulted UserProfile object.
 * Use this everywhere a profile needs to be created or normalized.
 *
 * @param {Partial<UserProfile>} data
 * @returns {UserProfile}
 */
export function createUserProfile(data = {}) {
  return {
    id: data.id ?? generateId(),
    name: data.name ?? '',
    level: data.level ?? '',
    frequency: data.frequency ?? '',
    struggles: Array.isArray(data.struggles) ? data.struggles : [],
    technicalWeaknesses: Array.isArray(data.technicalWeaknesses) ? data.technicalWeaknesses : [],
    mentalWeaknesses: Array.isArray(data.mentalWeaknesses) ? data.mentalWeaknesses : [],
    goals: Array.isArray(data.goals) ? data.goals : [],
    playerType: data.playerType ?? '',
    format: data.format ?? '',
    onboardingCompletedAt: data.onboardingCompletedAt ?? null,
    createdAt: data.createdAt ?? new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
}

/**
 * Merges a partial update into an existing profile.
 * Always bumps updatedAt.
 *
 * @param {UserProfile} profile
 * @param {Partial<UserProfile>} updates
 * @returns {UserProfile}
 */
export function updateUserProfile(profile, updates) {
  return {
    ...profile,
    ...updates,
    id: profile.id, // id is immutable
    createdAt: profile.createdAt, // createdAt is immutable
    updatedAt: new Date().toISOString(),
  };
}

/**
 * Returns true if the profile has enough data to use the app meaningfully.
 *
 * @param {UserProfile|null} profile
 * @returns {boolean}
 */
export function isProfileComplete(profile) {
  if (!profile) return false;
  return !!(profile.name && profile.level && profile.frequency);
}

/**
 * Computes the player's primary focus areas from their profile.
 * Used by the AI coach to prioritize recommendations.
 *
 * @param {UserProfile} profile
 * @returns {{ technical: string[], mental: string[], goals: string[] }}
 */
export function getProfileFocusAreas(profile) {
  return {
    technical: [...(profile.struggles ?? []), ...(profile.technicalWeaknesses ?? [])],
    mental: profile.mentalWeaknesses ?? [],
    goals: profile.goals ?? [],
  };
}
