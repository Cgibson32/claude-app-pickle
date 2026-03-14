/**
 * useAICoach
 *
 * Hook that manages async AI coaching plan state.
 * Reads from AppContext so any component can use it without prop drilling.
 * Automatically fetches a plan on first load if none is cached.
 */

import { useEffect, useRef } from 'react';
import { useAppState, useAppActions } from '../context/AppContext';

/**
 * @returns {{
 *   plan: CoachingPlan | null,
 *   isLoading: boolean,
 *   refresh: () => void,
 * }}
 */
export function useAICoach() {
  const { profile, sessions, aiPlan, isLoadingAI } = useAppState();
  const { refreshAIPlan } = useAppActions();
  const fetchedRef = useRef(false);

  // Auto-fetch on first render if no plan is cached yet
  useEffect(() => {
    if (!fetchedRef.current && profile && !aiPlan && !isLoadingAI) {
      fetchedRef.current = true;
      refreshAIPlan(profile, sessions);
    }
  }, [profile, sessions, aiPlan, isLoadingAI, refreshAIPlan]);

  const refresh = () => {
    if (profile) {
      fetchedRef.current = true;
      refreshAIPlan(profile, sessions);
    }
  };

  return {
    plan: aiPlan,
    isLoading: isLoadingAI,
    refresh,
  };
}
