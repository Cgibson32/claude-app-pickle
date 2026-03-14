/**
 * AICoachService
 *
 * The single entry point for all AI coaching functionality.
 * Currently runs a deterministic mock that uses player profile + session history.
 *
 * ─── HOW TO SWITCH TO THE ANTHROPIC API ─────────────────────────────────────
 *
 * 1. Set VITE_AI_PROVIDER=anthropic in your .env file
 * 2. Add VITE_ANTHROPIC_API_KEY=sk-ant-... to .env (never expose in frontend)
 * 3. Set up a lightweight server-side proxy (e.g. Vercel edge function, Express):
 *
 *    POST /api/coach
 *    Body: { messages: [...], model: 'claude-opus-4-6', max_tokens: 1200 }
 *    — proxy forwards to https://api.anthropic.com/v1/messages with the API key
 *    — returns the raw Anthropic response
 *
 * 4. No component code changes needed — the function signatures are identical.
 *
 * ────────────────────────────────────────────────────────────────────────────
 */

import { createCoachingPlan, createAIInsight, createDrill, INSIGHT_TYPE, INSIGHT_PRIORITY } from '../models/AIInsight';
import { getProfileFocusAreas } from '../models/UserProfile';
import { STRUGGLE_OPTIONS, TECHNICAL_WEAKNESSES, MENTAL_WEAKNESSES, EXPERIENCE_LEVELS } from '../data/onboardingData';
import { getTodayIntention } from '../data/intentionTemplates';

// ─── Provider configuration ──────────────────────────────────────────────────
const AI_PROVIDER = import.meta.env.VITE_AI_PROVIDER || 'mock';
const AI_PROXY_URL = import.meta.env.VITE_AI_PROXY_URL || '/api/coach';

// ─── Public API ──────────────────────────────────────────────────────────────

/**
 * Generates a full coaching plan for a player.
 * Returns a CoachingPlan (insights + drill + daily cue).
 *
 * @param {UserProfile} profile
 * @param {Session[]} sessions
 * @returns {Promise<CoachingPlan>}
 */
export async function generateCoachingPlan(profile, sessions) {
  if (AI_PROVIDER === 'anthropic') {
    return _generateWithAnthropic(profile, sessions);
  }
  return _generateWithMock(profile, sessions);
}

/**
 * Generates only a single coaching cue for the home screen.
 * Fast — does not hit the AI API.
 *
 * @param {UserProfile} profile
 * @param {Session[]} sessions
 * @returns {string}
 */
export function getDailyMotivationalCue(profile, sessions) {
  const today = getTodayIntention();
  const topStruggle = profile?.struggles?.[0];

  if (topStruggle === 'patience') return 'Build first. Attack when the moment is right.';
  if (topStruggle === 'thirds') return 'Soft hands. Trust the arc. Land it deep.';
  if (topStruggle === 'frustration') return 'Miss. Breathe. Next ball. Always forward.';
  if (sessions.length === 0) return 'Every journey starts with the first session.';

  return today?.cue || 'Play with intention today.';
}

// ─── Anthropic Implementation ────────────────────────────────────────────────

async function _generateWithAnthropic(profile, sessions) {
  const prompt = _buildCoachingPrompt(profile, sessions);

  const response = await fetch(AI_PROXY_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'claude-opus-4-6',
      max_tokens: 1200,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`AI coaching service error (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  return _parseAnthropicResponse(data);
}

/**
 * Builds the coaching prompt sent to Claude.
 * Separated from the fetch so it can be inspected and tested in isolation.
 *
 * @param {UserProfile} profile
 * @param {Session[]} sessions
 * @returns {string}
 */
function _buildCoachingPrompt(profile, sessions) {
  const levelLabel = EXPERIENCE_LEVELS.find(l => l.id === profile?.level)?.label || 'Unknown';
  const focusAreas = getProfileFocusAreas(profile);
  const recentSessions = sessions.slice(0, 5);

  const sessionSummary = recentSessions.length === 0
    ? 'No sessions logged yet.'
    : recentSessions.map(s => [
        `Date: ${s.date.split('T')[0]}`,
        `Rating: ${s.rating}/5`,
        s.patienceScore ? `Patience: ${s.patienceScore}/10` : null,
        s.emotionsScore ? `Emotional control: ${s.emotionsScore}/10` : null,
        s.wentWell ? `Went well: "${s.wentWell}"` : null,
        s.improveFocus ? `Needs work: "${s.improveFocus}"` : null,
        s.ahamoment ? `Insight: "${s.ahamoment}"` : null,
      ].filter(Boolean).join(', ')).join('\n- ');

  return `You are PicklePro's AI Coach — a world-class pickleball performance coach focused on process-oriented improvement, mental performance, and joy of the game.

PLAYER PROFILE:
- Name: ${profile?.name || 'Player'}
- Level: ${levelLabel}
- Play frequency: ${profile?.frequency || 'unknown'}
- Biggest struggles: ${focusAreas.technical.join(', ') || 'none specified'}
- Mental game challenges: ${focusAreas.mental.join(', ') || 'none specified'}
- Goals: ${focusAreas.goals.join(', ') || 'none specified'}
- Player type goal: ${profile?.playerType || 'not specified'}

RECENT SESSION HISTORY:
- ${sessionSummary}

Generate a personalized coaching plan with exactly this JSON structure (no markdown, raw JSON only):
{
  "insights": [
    {
      "type": "technical|mental|trend|process",
      "priority": "high|medium|low",
      "title": "Concise, specific title",
      "body": "2-3 sentences of specific, actionable coaching advice tailored to this player",
      "cue": "One short coaching cue (under 8 words)",
      "icon": "single emoji",
      "color": "#hexcolor matching the insight type"
    }
  ],
  "drill": {
    "name": "Drill name",
    "description": "Specific, step-by-step drill description",
    "focus": "Skill area",
    "time": "X min",
    "icon": "single emoji"
  },
  "dailyCue": "One inspiring, process-focused sentence for today"
}

Rules:
- Generate 3-5 insights ordered by priority (high first)
- Make advice specific to this player's level and stated struggles
- Tone: encouraging, process-focused, never outcome-obsessed
- The drill must be practical and doable in a typical session
- Colors: technical=#c8f135, mental=#3b82f6, trend=#f59e0b, process=#22c55e`;
}

/**
 * Parses the raw Anthropic API response into a CoachingPlan.
 *
 * @param {object} anthropicResponse - Raw response from the Anthropic API
 * @returns {CoachingPlan}
 */
function _parseAnthropicResponse(anthropicResponse) {
  try {
    const text = anthropicResponse?.content?.[0]?.text ?? '';
    // Strip any accidental markdown code fences
    const cleaned = text.replace(/```json\n?|\n?```/g, '').trim();
    const parsed = JSON.parse(cleaned);

    return createCoachingPlan({
      insights: parsed.insights || [],
      drill: parsed.drill || null,
      dailyCue: parsed.dailyCue || '',
      source: 'anthropic',
    });
  } catch (err) {
    console.error('[AICoachService] Failed to parse Anthropic response:', err);
    // Fall back to mock if parsing fails
    return _generateWithMock(null, []);
  }
}

// ─── Mock Implementation ─────────────────────────────────────────────────────

/**
 * Generates a coaching plan deterministically based on profile + sessions.
 * No API calls — fast, offline, and predictable.
 *
 * @param {UserProfile|null} profile
 * @param {Session[]} sessions
 * @returns {Promise<CoachingPlan>}
 */
async function _generateWithMock(profile, sessions) {
  // Simulate slight async delay to make the UX feel realistic
  await new Promise(resolve => setTimeout(resolve, 300));

  const insights = _buildMockInsights(profile, sessions);
  const drill = _pickDailyDrill();
  const dailyCue = getDailyMotivationalCue(profile, sessions);

  return createCoachingPlan({
    insights,
    drill,
    dailyCue,
    source: 'mock',
  });
}

function _buildMockInsights(profile, sessions) {
  const insights = [];
  const struggles = profile?.struggles || [];
  const mentalWeaknesses = profile?.mentalWeaknesses || [];
  const technicalWeaknesses = profile?.technicalWeaknesses || [];
  const level = profile?.level || 'beginner';

  const recentSessions = sessions.slice(0, 5);
  const avgPatience = _avgScore(recentSessions, 'patienceScore');
  const avgEmotions = _avgScore(recentSessions, 'emotionsScore');

  // ── Technical insights ────────────────────────────────────────────────────

  if (struggles.includes('thirds') || technicalWeaknesses.includes('third-shot')) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.TECHNICAL,
      priority: INSIGHT_PRIORITY.HIGH,
      title: 'Third Shot Drop: Your Highest-Leverage Skill',
      body: 'This is your single biggest unlock right now. A reliable third shot drop lets you transition to the kitchen on your own terms. Practice 50 drops per session — soft grip, committed swing, aiming deep in the kitchen, not the sidelines.',
      cue: 'Soft hands. Trust the arc.',
      icon: '🎯',
      color: '#c8f135',
    }));
  }

  if (struggles.includes('dinking') || technicalWeaknesses.includes('dink-xc')) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.TECHNICAL,
      priority: INSIGHT_PRIORITY.HIGH,
      title: 'Build Your Dink Pattern First',
      body: 'Cross-court dinking is the foundation of kitchen control. Aim cross-court 70-80% of the time — it clears the lowest part of the net, gives you the widest angle, and pulls opponents out of position. Build the habit before adding complexity.',
      cue: 'Cross-court first. Every time.',
      icon: '🏓',
      color: '#c8f135',
    }));
  }

  if (struggles.includes('resets') || technicalWeaknesses.includes('reset')) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.TECHNICAL,
      priority: INSIGHT_PRIORITY.MEDIUM,
      title: 'Master the Reset: Your Defensive Superpower',
      body: 'The ability to absorb a fast ball and drop it softly into the kitchen separates intermediate from advanced players. Use a soft, open-faced block — absorb, don\'t swing. Target the middle of the kitchen for the highest margin.',
      cue: 'Absorb. Redirect. Neutralize.',
      icon: '🔄',
      color: '#c8f135',
    }));
  }

  if (struggles.includes('positioning') || technicalWeaknesses.includes('kitchen-control')) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.FOUNDATION,
      priority: INSIGHT_PRIORITY.MEDIUM,
      title: 'Position Yourself to Win Before You Hit',
      body: 'Court positioning is the invisible skill that determines your options before the ball arrives. Your top priority after every return of serve: get to the kitchen line. This single habit will improve every other aspect of your game.',
      cue: 'Move forward. Kitchen line first.',
      icon: '📍',
      color: '#c8f135',
    }));
  }

  // ── Mental insights ───────────────────────────────────────────────────────

  if (struggles.includes('patience') || mentalWeaknesses.includes('patience-mental')) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.MENTAL,
      priority: INSIGHT_PRIORITY.HIGH,
      title: 'Patience Is the Most Powerful Shot You Have',
      body: 'Your profile points to patience as your #1 growth edge. Most errors come from forcing the rally before the right opportunity appears. Commit to not attacking until you receive a ball above shoulder height. Each dink you hit is an investment in the setup.',
      cue: 'High ball = attack. Low ball = build.',
      icon: '🧘',
      color: '#3b82f6',
    }));
  }

  if (mentalWeaknesses.includes('frustration') || struggles.includes('frustration')) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.MENTAL,
      priority: INSIGHT_PRIORITY.HIGH,
      title: 'Your Reset Routine Wins More Points Than Your Best Shot',
      body: 'Frustration is a performance tax. After any hard point, use your 10-second reset: walk, breathe once, choose one process cue. This micro-ritual interrupts the emotional spiral before it costs you the next point. Practice it in drills so it\'s automatic in matches.',
      cue: '10 seconds. Breathe. Next ball.',
      icon: '🌊',
      color: '#3b82f6',
    }));
  }

  if (mentalWeaknesses.includes('confidence-mental') || mentalWeaknesses.includes('pressure')) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.MENTAL,
      priority: INSIGHT_PRIORITY.MEDIUM,
      title: 'Confidence Comes From Commitment, Not Results',
      body: 'Half-committed shots miss more than fully committed ones. On important points, choose your shot early and swing with intention — even if it\'s conservative. A committed net ball teaches you more than a hesitant winner. Confidence grows through repetition of decisive action.',
      cue: 'Decide. Commit. Execute.',
      icon: '⚡',
      color: '#3b82f6',
    }));
  }

  // ── Trend insights (session-based) ────────────────────────────────────────

  if (avgPatience !== null && avgPatience < 6.5 && sessions.length >= 2) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.TREND,
      priority: INSIGHT_PRIORITY.MEDIUM,
      title: `Patience Trend: ${avgPatience.toFixed(1)}/10 Average`,
      body: `Your last ${Math.min(recentSessions.length, 5)} sessions show patience averaging ${avgPatience.toFixed(1)}/10. This is your active development zone. Before your next match, set one specific patience rule: "No attacks on balls below net height." Track it consciously for the first game.`,
      cue: 'One patience rule. Track it.',
      icon: '⏳',
      color: '#f59e0b',
    }));
  }

  if (avgEmotions !== null && avgEmotions < 6.5 && sessions.length >= 2) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.TREND,
      priority: INSIGHT_PRIORITY.MEDIUM,
      title: `Emotional Control: ${avgEmotions.toFixed(1)}/10 — This Is Winnable`,
      body: `Your emotional control scores are showing room to grow. The most effective intervention: identify your top 3 frustration triggers before you play. Name them. When they appear in a match, you'll recognize them faster and reset sooner. Awareness precedes control.`,
      cue: 'Name the trigger. Break the cycle.',
      icon: '🌊',
      color: '#f59e0b',
    }));
  }

  // ── Level-specific insights ───────────────────────────────────────────────

  if ((level === 'beginner' || level === 'intermediate') && insights.length < 4) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.FOUNDATION,
      priority: INSIGHT_PRIORITY.MEDIUM,
      title: 'The Kitchen Line Dominance Principle',
      body: 'Most players at your level spend too much time at the baseline. Getting to the kitchen line after your return puts you in the minority — and gives you enormous tactical advantage. Drill the return-and-advance as a single fluid movement until it\'s automatic.',
      cue: 'Return deep. Move forward immediately.',
      icon: '🏠',
      color: '#22c55e',
    }));
  }

  if ((level === 'advanced' || level === 'competitive') && insights.length < 4) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.ADVANCED,
      priority: INSIGHT_PRIORITY.MEDIUM,
      title: 'Disguise Is the Difference Maker at Your Level',
      body: 'At advanced/competitive level, your opponents read your patterns. The highest-leverage improvement is making your dinks and speed-ups look identical until the last millisecond. Same paddle preparation, same body language — only the contact point and swing speed differ.',
      cue: 'Look the same. Change the speed.',
      icon: '⚡',
      color: '#ef4444',
    }));
  }

  // ── Always include a process/growth insight ───────────────────────────────

  if (sessions.length === 0) {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.PROCESS,
      priority: INSIGHT_PRIORITY.LOW,
      title: 'Start the Loop: Intention → Play → Reflect',
      body: 'The most powerful thing you can do right now is start the habit loop: set an intention before you play, log a reflection after. Players who journal consistently improve 2x faster than those who don\'t. Your first session starts the compound growth engine.',
      cue: 'Set intention. Play. Reflect.',
      icon: '🌱',
      color: '#22c55e',
    }));
  } else {
    insights.push(createAIInsight({
      type: INSIGHT_TYPE.PROCESS,
      priority: INSIGHT_PRIORITY.LOW,
      title: `${sessions.length} Sessions In — The Compound Is Working`,
      body: 'Every session you reflect on is a deposit in your growth account. The players who improve fastest are not the ones who practice hardest once — they\'re the ones who show up consistently with intention and review honestly. You\'re building the right habits. Keep going.',
      cue: 'Consistency beats intensity. Always.',
      icon: '📈',
      color: '#22c55e',
    }));
  }

  // Limit to 5 insights, highest priority first
  const priorityOrder = { high: 0, medium: 1, low: 2 };
  return insights
    .sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority])
    .slice(0, 5);
}

const DRILLS = [
  {
    name: '50 Third Shot Drops',
    description: 'Stand at the baseline. Drop a ball and hit soft, arcing drops over the net into the kitchen. Track your make percentage — aim for 80%+ landing in the kitchen. Rest 30 seconds between sets of 10.',
    focus: 'Third Shot Drop',
    time: '10–12 min',
    icon: '🎯',
    steps: [
      'Stand at center baseline, paddle relaxed in front',
      'Drop ball, swing from shoulder with a soft, open paddle face',
      'Aim for deep kitchen — not the sidelines',
      'Follow through upward toward target',
      'Track your makes: mark every hit that lands in the kitchen',
    ],
  },
  {
    name: 'Cross-Court Dink Consistency',
    description: 'With a partner at the kitchen line, rally cross-court targeting 50 consecutive shots without an error. Focus on soft hands, consistent arc, and controlled placement — not pace.',
    focus: 'Dink Patterns',
    time: '8–10 min',
    icon: '🏓',
    steps: [
      'Both players at kitchen line, cross-court from each other',
      'Dink softly, aiming for backhand hip area',
      'Keep paddle face slightly open',
      'Track consecutive count — reset at any error',
      'Goal: 50 consecutive before moving on',
    ],
  },
  {
    name: '10-Second Reset Drill',
    description: 'During your next practice game, after every error — commit to a full 10-second reset: walk to your position, take one breath, speak one positive process cue. Count how many times you complete the reset vs. skip it.',
    focus: 'Mental Reset',
    time: 'Full session',
    icon: '🧘',
    steps: [
      'Agree with partner: this session practices reset routines',
      'After each error: walk slowly to your position',
      'Take one deliberate breath',
      'Say your process cue quietly (e.g. "soft hands", "next ball")',
      'Count your resets at the end — aim for 100% completion',
    ],
  },
  {
    name: 'Advance Drill: Return → Kitchen',
    description: 'Practice the return-of-serve advance movement. Partner serves, you return deep to their baseline, then immediately move forward to the kitchen line in 3 smooth steps. Goal: reach the kitchen before the ball bounces twice.',
    focus: 'Court Positioning',
    time: '10 min',
    icon: '📍',
    steps: [
      'Partner serves from baseline',
      'Return deep (aim at their feet or deep baseline)',
      'Immediately begin moving forward as ball leaves paddle',
      'Split step as partner contacts the ball',
      'Arrive at kitchen line, ready position',
    ],
  },
  {
    name: 'Body-Attack Speed-Up',
    description: 'Partner dinks cross-court, feeding you a ball that\'s slightly high (above net height). Attack it at their dominant shoulder. Practice reading the height and timing the acceleration precisely.',
    focus: 'Speed-Up Attack',
    time: '8 min',
    icon: '⚡',
    steps: [
      'Partner dinks cross-court, intentionally going a little high',
      'You read the height — only attack balls above net',
      'Accelerate through the ball, aim at shoulder',
      'Immediately reset back to dink position',
      'Goal: 15 successful attacks before switching roles',
    ],
  },
  {
    name: 'Backhand Isolation Rally',
    description: 'Spend an entire 10-minute stretch dinking exclusively with your backhand — even on balls that would normally be a forehand. This rapidly builds the weaker side into a reliable weapon.',
    focus: 'Backhand',
    time: '10 min',
    icon: '🤚',
    steps: [
      'Partner understands: you will only use backhand this round',
      'Move your feet to get around balls on the right (if right-handed)',
      'Focus on consistent contact point — in front of body',
      'Maintain soft grip throughout',
      'Compete: partner tries to exploit your forehand with placements',
    ],
  },
];

function _pickDailyDrill() {
  const dayIndex = new Date().getDate() % DRILLS.length;
  const drill = DRILLS[dayIndex];
  return createDrill(drill);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function _avgScore(sessions, key) {
  const valid = sessions.filter(s => s[key] > 0);
  if (!valid.length) return null;
  return parseFloat((valid.reduce((a, s) => a + s[key], 0) / valid.length).toFixed(1));
}
