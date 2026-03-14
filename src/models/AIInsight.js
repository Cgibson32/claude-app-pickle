/**
 * AIInsight and CoachingPlan models
 * Defines the shape of data coming back from the AI coach service.
 * Both mock and real (Anthropic) implementations must return this shape.
 */

import { generateId } from '../utils/generateId';

/**
 * Insight priority levels
 */
export const INSIGHT_PRIORITY = {
  HIGH: 'high',
  MEDIUM: 'medium',
  LOW: 'low',
};

/**
 * Insight type categories
 */
export const INSIGHT_TYPE = {
  TECHNICAL: 'technical',
  MENTAL: 'mental',
  TREND: 'trend',
  PROCESS: 'process',
  ADVANCED: 'advanced',
  FOUNDATION: 'foundation',
};

/**
 * Creates a single AIInsight object.
 *
 * @param {Partial<AIInsight>} data
 * @returns {AIInsight}
 */
export function createAIInsight(data = {}) {
  return {
    id: data.id ?? generateId(),
    type: data.type ?? INSIGHT_TYPE.PROCESS,
    priority: data.priority ?? INSIGHT_PRIORITY.MEDIUM,
    title: data.title ?? '',
    body: data.body ?? '',
    cue: data.cue ?? '',
    icon: data.icon ?? '💡',
    color: data.color ?? '#c8f135',
  };
}

/**
 * Creates a DrillRecommendation object.
 *
 * @param {Partial<DrillRecommendation>} data
 * @returns {DrillRecommendation}
 */
export function createDrill(data = {}) {
  return {
    id: data.id ?? generateId(),
    name: data.name ?? '',
    description: data.description ?? '',
    focus: data.focus ?? '',
    time: data.time ?? '10 min',
    icon: data.icon ?? '🎯',
    steps: Array.isArray(data.steps) ? data.steps : [],
  };
}

/**
 * Creates a full CoachingPlan — the complete output of the AI coach service.
 *
 * @param {Partial<CoachingPlan>} data
 * @returns {CoachingPlan}
 */
export function createCoachingPlan(data = {}) {
  return {
    id: data.id ?? generateId(),
    generatedAt: data.generatedAt ?? new Date().toISOString(),
    insights: Array.isArray(data.insights) ? data.insights.map(createAIInsight) : [],
    drill: data.drill ? createDrill(data.drill) : null,
    dailyCue: data.dailyCue ?? '',
    // Source: 'mock' | 'anthropic' — useful for debugging and analytics
    source: data.source ?? 'mock',
  };
}
