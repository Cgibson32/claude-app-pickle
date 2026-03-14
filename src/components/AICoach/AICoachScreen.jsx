import { useState, useMemo } from 'react';
import { ChevronRight, Brain, RefreshCw, Sparkles, Target, Zap, Loader } from 'lucide-react';
import { getTodayIntention } from '../../data/intentionTemplates';
import {
  STRUGGLE_OPTIONS,
  MENTAL_WEAKNESSES,
  EXPERIENCE_LEVELS,
} from '../../data/onboardingData';
import { useAppState } from '../../context/AppContext';
import { useAICoach } from '../../hooks/useAICoach';

function generateInsights(profile, sessions) {
  const insights = [];
  const level = profile?.level || 'beginner';
  const struggles = profile?.struggles || [];
  const mentalWeaknesses = profile?.mentalWeaknesses || [];
  const technicalWeaknesses = profile?.technicalWeaknesses || [];

  // Session-based insights
  const recentSessions = sessions.slice(0, 5);
  const avgPatience = recentSessions.length > 0
    ? recentSessions.reduce((a, s) => a + (s.patienceScore || 5), 0) / recentSessions.length
    : null;
  const avgEmotions = recentSessions.length > 0
    ? recentSessions.reduce((a, s) => a + (s.emotionsScore || 5), 0) / recentSessions.length
    : null;

  // Technical insights based on struggles
  if (struggles.includes('thirds') || technicalWeaknesses.includes('third-shot')) {
    insights.push({
      type: 'technical',
      priority: 'high',
      title: 'Third Shot Drop is Your Gateway Skill',
      body: `Based on your profile, the third shot drop is your highest-leverage technical focus right now. This single skill will unlock more improvement than any other. Practice 50 drops per session — soft grip, committed swing, landing deep in the kitchen.`,
      cue: 'Soft hands. Trust the arc.',
      icon: null,
      color: '#c8f135',
    });
  }

  if (struggles.includes('dinking') || technicalWeaknesses.includes('dink-xc')) {
    insights.push({
      type: 'technical',
      priority: 'high',
      title: 'Cross-Court Dinking: Your Point Builder',
      body: `Cross-court dinking is the foundation of the kitchen game. Aim cross-court 70-80% of the time — lower net, wider angle, more margin for error. Build this pattern until it becomes automatic.`,
      cue: 'Cross-court first. Every time.',
      icon: null,
      color: '#3b82f6',
    });
  }

  if (struggles.includes('patience') || mentalWeaknesses.includes('patience-mental')) {
    insights.push({
      type: 'mental',
      priority: 'high',
      title: 'Patience is Your #1 Mental Skill',
      body: `Your reflections show patience is a key growth area. Most errors at your level come from forcing the point before the right opportunity arrives. Practice waiting for balls above net height before attacking. Every dink is a deposit.`,
      cue: 'Build first. Attack when ready.',
      icon: null,
      color: '#a855f7',
    });
  }

  if (avgPatience !== null && avgPatience < 6) {
    insights.push({
      type: 'trend',
      priority: 'medium',
      title: 'Patience Trend: Room to Grow',
      body: `Your recent sessions show patience scoring around ${avgPatience.toFixed(1)}/10. This is an area of active development. Before your next match, set one specific patience cue: "I won't attack until the ball is above shoulder height." Track this intentionally.`,
      cue: 'High ball = attack. Low ball = dink on.',
      icon: null,
      color: '#f59e0b',
    });
  }

  if (avgEmotions !== null && avgEmotions < 6) {
    insights.push({
      type: 'mental',
      priority: 'medium',
      title: 'Emotional Control: Your Competitive Edge',
      body: `Your journal shows emotional control as a growth area. The 10-second reset is your tool: after any frustrating point, walk to the baseline, take one breath, and return your focus to the next ball. Practice this ritual until it becomes automatic.`,
      cue: '10 seconds. Breathe. Next ball.',
      icon: null,
      color: '#14b8a6',
    });
  }

  if (struggles.includes('positioning') || technicalWeaknesses.includes('kitchen-control')) {
    insights.push({
      type: 'technical',
      priority: 'medium',
      title: 'Position Yourself to Win',
      body: `Court positioning is the invisible skill that separates recreational from competitive players. Your first goal after every return should be: get to the kitchen line. Practice the advance movement until it's automatic — serve, return, advance.`,
      cue: 'Move forward with every return.',
      icon: null,
      color: '#22c55e',
    });
  }

  if (struggles.includes('communication') || mentalWeaknesses.includes('communication')) {
    insights.push({
      type: 'mental',
      priority: 'medium',
      title: 'Communication is a Competitive Weapon',
      body: `Partner communication is one of the most underused competitive advantages. Before your next match, agree on: who takes middle balls, encouragement after mistakes, and one tactical goal. Teams that communicate play with shared confidence.`,
      cue: 'Call every ball. Encourage every miss.',
      icon: null,
      color: '#f97316',
    });
  }

  // Level-specific insights
  if (level === 'beginner' || level === 'intermediate') {
    insights.push({
      type: 'foundation',
      priority: 'medium',
      title: 'The Kitchen Line is Your Power Position',
      body: `At your current level, getting to the kitchen line consistently will transform your game more than any single shot. Most recreational players stay at the baseline — getting to the kitchen line puts you in the minority and gives you enormous tactical advantage.`,
      cue: 'Get to the kitchen. Stay there.',
      icon: null,
      color: '#c8f135',
    });
  }

  if (level === 'advanced' || level === 'competitive') {
    insights.push({
      type: 'advanced',
      priority: 'medium',
      title: 'Disguise Your Speed-Ups',
      body: `At your level, pattern recognition is everything. The best attackers look exactly like dinkers before they speed up. Work on creating the same paddle preparation for dinks and attacks — the disguise is what makes the attack work.`,
      cue: 'Look the same. Change the speed.',
      icon: null,
      color: '#ef4444',
    });
  }

  // Always include a process insight
  insights.push({
    type: 'process',
    priority: 'low',
    title: 'Growth Compounds — Every Session Matters',
    body: `The most consistent improvers in pickleball are the ones who show up repeatedly with intention. Not the ones who practice hardest once a month. Your streak of reflection and intention-setting is building a foundation that will pay off in ways you can't yet see. Keep going.`,
    cue: 'Show up. Set intention. Reflect.',
    icon: '🌱',
    color: '#22c55e',
  });

  return insights.slice(0, 5);
}

function generateDailyDrill() {
  const drills = [
    {
      name: '50 Third Shot Drops',
      description: 'Stand at the baseline, drop a ball, and hit 50 consecutive soft drops over the net into the kitchen. Track your make percentage. Goal: 80%+ in the kitchen.',
      focus: 'Third Shot Drop',
      time: '10 min',
      icon: null,
    },
    {
      name: 'Cross-Court Dink Rally',
      description: 'With a partner, rally cross-court from the kitchen for 50 consecutive shots without error. Focus on arc, soft hands, and consistent placement.',
      focus: 'Dinking',
      time: '8 min',
      icon: null,
    },
    {
      name: '10-Second Reset Practice',
      description: 'After every error in your next drill or match, use your 10-second reset: walk to baseline, one breath, one positive cue, then return focus. Count how many times you successfully reset.',
      focus: 'Mental Game',
      time: 'Full session',
      icon: null,
    },
    {
      name: 'Advance Drill',
      description: 'Practice the serve-return-advance sequence 20 times in a row. Focus on smooth forward movement through the transition zone, landing at the kitchen line ready for the next shot.',
      focus: 'Positioning',
      time: '10 min',
      icon: null,
    },
    {
      name: 'Backhand Isolation',
      description: 'Spend 10 minutes dinking only with your backhand. Move your feet to each ball. This builds the weaker side into a reliable weapon.',
      focus: 'Backhand',
      time: '10 min',
      icon: null,
    },
    {
      name: 'Pattern Game',
      description: 'Play points where you commit to dinking cross-court 5 times before going anywhere else. Build the pattern habit. First player to deviate from the pattern loses a point.',
      focus: 'Dink Patterns',
      time: '15 min',
      icon: null,
    },
  ];

  const dayIndex = new Date().getDate() % drills.length;
  return drills[dayIndex];
}

export default function AICoachScreen({ onNavigate }) {
  const { profile, sessions } = useAppState();
  const { plan, isLoading, refresh } = useAICoach();
  const today = getTodayIntention();

  // Fall back to local mock insights if async plan hasn't loaded yet
  const insights = useMemo(
    () => plan?.insights ?? generateInsights(profile, sessions),
    [plan, profile, sessions]
  );
  const drill = useMemo(
    () => plan?.drill ?? generateDailyDrill(),
    [plan]
  );

  return (
    <div style={{ padding: '20px 20px 100px' }} className="animate-fade-in">
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
          <div style={{
            width: 28, height: 28, borderRadius: 8, background: 'rgba(168,85,247,0.15)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Brain size={14} color="#a855f7" />
          </div>
          <span className="label-xs" style={{ color: '#a855f7' }}>AI Coach</span>
        </div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', marginBottom: 8 }}>
          Your Coaching Plan
        </h1>
        <p style={{ color: '#666', fontSize: '0.875rem' }}>
          Personalized insights based on your profile and sessions
        </p>
      </div>

      {/* Today's Focus */}
      <div style={{
        background: 'linear-gradient(135deg, #1a0a2e, #120a20)',
        border: '1px solid rgba(168,85,247,0.3)', borderRadius: 22, padding: '20px', marginBottom: 20,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
          <Sparkles size={14} color="#a855f7" />
          <span className="label-xs" style={{ color: '#a855f7' }}>Today&apos;s AI Focus</span>
        </div>
        <h3 style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '1rem', margin: '0 0 8px' }}>
          Theme: {today.theme}
        </h3>
        <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.6, margin: '0 0 14px' }}>
          Today your AI coach recommends focusing on <strong style={{ color: '#f5f5f5' }}>{today.performance}</strong> with the mental cue: <em style={{ color: '#c8a0f0' }}>"{today.mental}"</em>
        </p>
        <div style={{ borderTop: '1px solid rgba(168,85,247,0.15)', paddingTop: 12 }}>
          <p style={{ color: '#a855f7', fontSize: '0.85rem', fontStyle: 'italic', fontWeight: 600, margin: 0 }}>
            "{today.quote}"
          </p>
        </div>
      </div>

      {/* Daily Drill */}
      {drill && (
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 22, padding: '20px', marginBottom: 20,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
            <Zap size={14} color="#c8f135" />
            <span className="label-xs" style={{ color: '#c8f135' }}>Today&apos;s Drill</span>
            <span style={{
              marginLeft: 'auto', background: '#1e1e1e', border: '1px solid #333',
              color: '#555', borderRadius: 20, padding: '2px 8px', fontSize: '0.65rem',
            }}>
              {drill.time}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
            <div>
              <h3 style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.95rem', margin: '0 0 6px' }}>
                {drill.name}
              </h3>
              <p style={{ color: '#a0a0a0', fontSize: '0.8rem', lineHeight: 1.6, margin: 0 }}>
                {drill.description}
              </p>
              <span style={{
                display: 'inline-block', marginTop: 10, background: 'rgba(200,241,53,0.1)',
                border: '1px solid rgba(200,241,53,0.25)', color: '#c8f135',
                borderRadius: 20, padding: '3px 10px', fontSize: '0.7rem', fontWeight: 600,
              }}>
                {drill.focus}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Personalized Insights */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <span className="label-xs" style={{ color: '#555' }}>
          Personalized Insights ({insights.length})
        </span>
        <button
          onClick={refresh}
          disabled={isLoading}
          style={{
            background: 'none', border: 'none', color: isLoading ? '#444' : '#555', cursor: isLoading ? 'default' : 'pointer',
            display: 'flex', alignItems: 'center', gap: 4, fontSize: '0.75rem',
          }}
        >
          {isLoading ? <Loader size={12} style={{ animation: 'spin 1s linear infinite' }} /> : <RefreshCw size={12} />}
          {isLoading ? 'Loading...' : 'Refresh'}
        </button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {insights.map((insight, i) => (
          <InsightCard key={i} insight={insight} index={i} />
        ))}
      </div>

      {/* Profile summary */}
      {profile && (
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 22, padding: '18px', marginTop: 20,
        }}>
          <div className="label-xs" style={{ color: '#555', marginBottom: 14 }}>Your Coaching Profile</div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {profile.level && (
              <Tag label={EXPERIENCE_LEVELS.find(l => l.id === profile.level)?.label || profile.level} color="#c8f135" />
            )}
            {(profile.struggles || []).slice(0, 3).map(id => {
              const item = STRUGGLE_OPTIONS.find(s => s.id === id);
              return item ? <Tag key={id} label={item.label} color="#3b82f6" /> : null;
            })}
            {(profile.mentalWeaknesses || []).slice(0, 2).map(id => {
              const item = MENTAL_WEAKNESSES.find(m => m.id === id);
              return item ? <Tag key={id} label={item.label} color="#a855f7" /> : null;
            })}
          </div>
          <button
            onClick={() => onNavigate('profile')}
            style={{
              background: 'none', border: 'none', color: '#555', cursor: 'pointer',
              fontSize: '0.75rem', marginTop: 12, display: 'flex', alignItems: 'center', gap: 4,
            }}
          >
            Update profile <ChevronRight size={12} />
          </button>
        </div>
      )}

      {sessions.length === 0 && (
        <div style={{
          background: 'rgba(168,85,247,0.06)', border: '1px solid rgba(168,85,247,0.2)',
          borderRadius: 20, padding: '20px', textAlign: 'center', marginTop: 16,
        }}>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.6, margin: '0 0 14px' }}>
            Log a session in your journal to unlock deeper AI insights based on your actual play patterns.
          </p>
          <button
            onClick={() => onNavigate('journal', { mode: 'post' })}
            style={{
              background: 'rgba(168,85,247,0.15)', border: '1px solid rgba(168,85,247,0.3)',
              color: '#a855f7', borderRadius: 12, padding: '10px 20px',
              fontSize: '0.85rem', fontWeight: 700, cursor: 'pointer',
            }}
          >
            Log Your First Session
          </button>
        </div>
      )}
    </div>
  );
}

function InsightCard({ insight, index }) {
  const [expanded, setExpanded] = useState(index === 0);

  const priorityBadge = {
    high: { label: 'High Priority', bg: 'rgba(239,68,68,0.1)', border: 'rgba(239,68,68,0.3)', color: '#ef4444' },
    medium: { label: 'Focus Area', bg: 'rgba(245,158,11,0.1)', border: 'rgba(245,158,11,0.3)', color: '#f59e0b' },
    low: { label: 'Foundation', bg: 'rgba(34,197,94,0.1)', border: 'rgba(34,197,94,0.3)', color: '#22c55e' },
  }[insight.priority];

  return (
    <div style={{
      background: '#141414', border: '1px solid #2a2a2a', borderRadius: 20, overflow: 'hidden',
    }}>
      <button
        onClick={() => setExpanded(e => !e)}
        style={{
          width: '100%', background: 'none', border: 'none', padding: '16px 18px',
          display: 'flex', alignItems: 'flex-start', gap: 12, cursor: 'pointer', textAlign: 'left',
        }}
      >
        <div style={{
            width: 8, height: 8, borderRadius: '50%', flexShrink: 0, marginTop: 6,
            background: insight.color,
          }} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4, flexWrap: 'wrap' }}>
            <span style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.875rem' }}>{insight.title}</span>
            <span style={{
              background: priorityBadge.bg, border: `1px solid ${priorityBadge.border}`,
              color: priorityBadge.color, borderRadius: 20, padding: '1px 8px', fontSize: '0.6rem', fontWeight: 700,
            }}>
              {priorityBadge.label}
            </span>
          </div>
          {!expanded && (
            <p style={{ color: '#555', fontSize: '0.78rem', margin: 0, lineHeight: 1.5 }}>
              {insight.body.slice(0, 60)}... <span style={{ color: insight.color }}>Read more</span>
            </p>
          )}
        </div>
        <span style={{ color: '#444', fontSize: '1rem', flexShrink: 0 }}>{expanded ? '▲' : '▼'}</span>
      </button>

      {expanded && (
        <div style={{ padding: '0 18px 18px' }}>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.7, margin: '0 0 14px' }}>
            {insight.body}
          </p>
          <div style={{
            background: `${insight.color}12`, border: `1px solid ${insight.color}30`,
            borderRadius: 12, padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <Target size={14} color={insight.color} />
            <span style={{ color: insight.color, fontSize: '0.8rem', fontWeight: 700, fontStyle: 'italic' }}>
              "{insight.cue}"
            </span>
          </div>
        </div>
      )}
    </div>
  );
}

function Tag({ label, color }) {
  return (
    <span style={{
      background: `${color}12`, border: `1px solid ${color}30`, color,
      borderRadius: 20, padding: '4px 10px', fontSize: '0.7rem', fontWeight: 600,
    }}>
      {label}
    </span>
  );
}
