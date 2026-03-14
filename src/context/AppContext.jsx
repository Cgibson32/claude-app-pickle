/* eslint-disable react-refresh/only-export-components */
/**
 * AppContext
 *
 * Global state management for PicklePro using useReducer.
 * All repositories are called here — components read via useAppContext()
 * and dispatch actions via useAppDispatch().
 *
 * State shape:
 *   profile         UserProfile | null
 *   sessions        Session[]          (sorted newest first)
 *   intentions      Intention[]        (sorted newest first)
 *   savedSkills     string[]           (array of skill IDs)
 *   aiPlan          CoachingPlan | null
 *   isLoadingAI     boolean
 *   currentTab      string             ('home' | 'skills' | 'journal' | 'mental' | 'progress')
 */

import { createContext, useContext, useReducer, useEffect, useCallback } from 'react';
import * as ProfileRepo from '../repositories/ProfileRepository';
import * as SessionRepo from '../repositories/SessionRepository';
import * as IntentionRepo from '../repositories/IntentionRepository';
import { storageGet, storageSet, STORAGE_KEYS } from '../services/StorageService';
import { generateCoachingPlan } from '../services/AICoachService';

// ─── Action Types ─────────────────────────────────────────────────────────────

export const ACTIONS = {
  // Profile
  SET_PROFILE: 'SET_PROFILE',
  CLEAR_PROFILE: 'CLEAR_PROFILE',

  // Sessions
  SET_SESSIONS: 'SET_SESSIONS',
  UPSERT_SESSION: 'UPSERT_SESSION',
  DELETE_SESSION: 'DELETE_SESSION',

  // Intentions
  SET_INTENTIONS: 'SET_INTENTIONS',
  UPSERT_INTENTION: 'UPSERT_INTENTION',

  // Saved skills
  SET_SAVED_SKILLS: 'SET_SAVED_SKILLS',
  TOGGLE_SAVED_SKILL: 'TOGGLE_SAVED_SKILL',

  // AI Coach
  SET_AI_PLAN: 'SET_AI_PLAN',
  SET_AI_LOADING: 'SET_AI_LOADING',

  // Navigation
  SET_TAB: 'SET_TAB',
};

// ─── Initial State ────────────────────────────────────────────────────────────

const initialState = {
  profile: null,
  sessions: [],
  intentions: [],
  savedSkills: [],
  aiPlan: null,
  isLoadingAI: false,
  currentTab: 'home',
};

// ─── Reducer ──────────────────────────────────────────────────────────────────

function appReducer(state, action) {
  switch (action.type) {
    case ACTIONS.SET_PROFILE:
      return { ...state, profile: action.payload };

    case ACTIONS.CLEAR_PROFILE:
      return { ...state, profile: null, sessions: [], intentions: [], aiPlan: null };

    case ACTIONS.SET_SESSIONS:
      return { ...state, sessions: action.payload };

    case ACTIONS.UPSERT_SESSION: {
      const updated = action.payload;
      const exists = state.sessions.some(s => s.id === updated.id);
      const next = exists
        ? state.sessions.map(s => s.id === updated.id ? updated : s)
        : [updated, ...state.sessions];
      return { ...state, sessions: next.sort((a, b) => new Date(b.date) - new Date(a.date)) };
    }

    case ACTIONS.DELETE_SESSION:
      return { ...state, sessions: state.sessions.filter(s => s.id !== action.payload) };

    case ACTIONS.SET_INTENTIONS:
      return { ...state, intentions: action.payload };

    case ACTIONS.UPSERT_INTENTION: {
      const updated = action.payload;
      const exists = state.intentions.some(i => i.date === updated.date);
      const next = exists
        ? state.intentions.map(i => i.date === updated.date ? updated : i)
        : [updated, ...state.intentions];
      return { ...state, intentions: next.sort((a, b) => new Date(b.date) - new Date(a.date)) };
    }

    case ACTIONS.SET_SAVED_SKILLS:
      return { ...state, savedSkills: action.payload };

    case ACTIONS.TOGGLE_SAVED_SKILL: {
      const id = action.payload;
      const isSaved = state.savedSkills.includes(id);
      return {
        ...state,
        savedSkills: isSaved
          ? state.savedSkills.filter(s => s !== id)
          : [...state.savedSkills, id],
      };
    }

    case ACTIONS.SET_AI_PLAN:
      return { ...state, aiPlan: action.payload, isLoadingAI: false };

    case ACTIONS.SET_AI_LOADING:
      return { ...state, isLoadingAI: action.payload };

    case ACTIONS.SET_TAB:
      return { ...state, currentTab: action.payload };

    default:
      return state;
  }
}

// ─── Contexts ─────────────────────────────────────────────────────────────────

const AppStateContext = createContext(null);
const AppDispatchContext = createContext(null);

// ─── Provider ────────────────────────────────────────────────────────────────

export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  // Bootstrap: load all persisted data on mount
  useEffect(() => {
    const profile = ProfileRepo.getProfile();
    const sessions = SessionRepo.getAll();
    const intentions = IntentionRepo.getAll();
    const savedSkills = storageGet(STORAGE_KEYS.SAVED_SKILLS, []);

    dispatch({ type: ACTIONS.SET_PROFILE, payload: profile });
    dispatch({ type: ACTIONS.SET_SESSIONS, payload: sessions });
    dispatch({ type: ACTIONS.SET_INTENTIONS, payload: intentions });
    dispatch({ type: ACTIONS.SET_SAVED_SKILLS, payload: savedSkills });
  }, []);

  // Persist savedSkills whenever it changes
  useEffect(() => {
    storageSet(STORAGE_KEYS.SAVED_SKILLS, state.savedSkills);
  }, [state.savedSkills]);

  return (
    <AppStateContext.Provider value={state}>
      <AppDispatchContext.Provider value={dispatch}>
        {children}
      </AppDispatchContext.Provider>
    </AppStateContext.Provider>
  );
}

// ─── Hooks ───────────────────────────────────────────────────────────────────

export function useAppState() {
  const ctx = useContext(AppStateContext);
  if (!ctx) throw new Error('useAppState must be used inside AppProvider');
  return ctx;
}

export function useAppDispatch() {
  const ctx = useContext(AppDispatchContext);
  if (!ctx) throw new Error('useAppDispatch must be used inside AppProvider');
  return ctx;
}

/**
 * Convenience hook: returns common action creators bound to dispatch.
 * Components import this instead of wiring dispatch manually.
 */
export function useAppActions() {
  const dispatch = useAppDispatch();

  const saveProfile = useCallback((profile) => {
    const saved = ProfileRepo.saveProfile(profile);
    dispatch({ type: ACTIONS.SET_PROFILE, payload: saved });
    return saved;
  }, [dispatch]);

  const patchProfile = useCallback((updates) => {
    const saved = ProfileRepo.patchProfile(updates);
    dispatch({ type: ACTIONS.SET_PROFILE, payload: saved });
    return saved;
  }, [dispatch]);

  const clearProfile = useCallback(() => {
    ProfileRepo.clearProfile();
    dispatch({ type: ACTIONS.CLEAR_PROFILE });
  }, [dispatch]);

  const saveSession = useCallback((session) => {
    const saved = SessionRepo.save(session);
    dispatch({ type: ACTIONS.UPSERT_SESSION, payload: saved });
    return saved;
  }, [dispatch]);

  const deleteSession = useCallback((id) => {
    SessionRepo.deleteById(id);
    dispatch({ type: ACTIONS.DELETE_SESSION, payload: id });
  }, [dispatch]);

  const saveIntention = useCallback((intention) => {
    const saved = IntentionRepo.save(intention);
    dispatch({ type: ACTIONS.UPSERT_INTENTION, payload: saved });
    return saved;
  }, [dispatch]);

  const toggleSavedSkill = useCallback((skillId) => {
    dispatch({ type: ACTIONS.TOGGLE_SAVED_SKILL, payload: skillId });
  }, [dispatch]);

  const refreshAIPlan = useCallback(async (profile, sessions) => {
    dispatch({ type: ACTIONS.SET_AI_LOADING, payload: true });
    try {
      const plan = await generateCoachingPlan(profile, sessions);
      dispatch({ type: ACTIONS.SET_AI_PLAN, payload: plan });
      return plan;
    } catch (err) {
      console.error('[AppContext] AI plan generation failed:', err);
      dispatch({ type: ACTIONS.SET_AI_LOADING, payload: false });
      return null;
    }
  }, [dispatch]);

  const navigate = useCallback((tab) => {
    dispatch({ type: ACTIONS.SET_TAB, payload: tab });
  }, [dispatch]);

  return {
    saveProfile,
    patchProfile,
    clearProfile,
    saveSession,
    deleteSession,
    saveIntention,
    toggleSavedSkill,
    refreshAIPlan,
    navigate,
  };
}
