import { Flame, Target, Star, Calendar, TrendingUp, Award, Heart } from 'lucide-react';

// ─── Growth Messages ─────────────────────────────────────────────────────────

function getGrowthMessage(sessions, avgPatience, avgEmotions, avgCommunication) {
  const messages = [];

  if (sessions.length >= 3 && sessions.length <= 5) {
    messages.push({
      text: "You're building a habit that most players never start. Every reflection you write is sharpening your awareness.",
      icon: "🌱", color: "#22c55e",
    });
  }
  if (sessions.length >= 10) {
    messages.push({
      text: "10+ sessions of intentional practice. You're no longer guessing about your game — you're studying it.",
      icon: "📚", color: "#3b82f6",
    });
  }

  if (avgPatience && avgPatience >= 7) {
    messages.push({
      text: "Your patience scores are strong. That means you're learning to trust the rally and wait for your moment. This is elite-level thinking.",
      icon: "⏳", color: "#c8f135",
    });
  }
  if (avgEmotions && avgEmotions >= 7) {
    messages.push({
      text: "High emotional control is your competitive edge. When other players tilt, you stay composed. That's the difference-maker.",
      icon: "🧘", color: "#a855f7",
    });
  }
  if (avgCommunication && avgCommunication >= 7) {
    messages.push({
      text: "Your communication scores show a true partner player. Teams with strong communication play 2 levels above their skill.",
      icon: "🤝", color: "#22c55e",
    });
  }
  if (avgPatience && avgPatience < 5) {
    messages.push({
      text: "Patience is your biggest growth opportunity right now. One drill: count to 5 dinks before attacking. Watch what happens.",
      icon: "💡", color: "#f59e0b",
    });
  }
  if (avgEmotions && avgEmotions < 5) {
    messages.push({
      text: "Emotional control is a skill — not a talent. Try naming your frustration triggers before your next match. Awareness is step one.",
      icon: "🌊", color: "#3b82f6",
    });
  }

  return messages.slice(0, 2);
}

const PROCESS_QUOTES = [
  "These metrics track how you play, not whether you win. A player scoring 8/10 on patience is building habits that outlast any single match result.",
  "The scoreboard resets every game. These scores compound for life. Keep tracking. Keep growing.",
  "Most players measure themselves by wins and losses. You measure yourself by patience, emotional control, and communication. That's why you'll surpass them.",
  "The players who journal and reflect improve 3x faster than those who just play. You're doing the work that matters.",
  "Your future self — the one who plays with confidence and composure — is being built right here, session by session.",
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

function calcStreak(sessions) {
  if (!sessions.length) return 0;
  const daySet = new Set();
  sessions.forEach(s => daySet.add(new Date(s.date).toISOString().split('T')[0]));
  let streak = 0;
  const cursor = new Date();
  const todayKey = cursor.toISOString().split('T')[0];
  if (!daySet.has(todayKey)) cursor.setDate(cursor.getDate() - 1);
  while (true) {
    const key = cursor.toISOString().split('T')[0];
    if (!daySet.has(key)) break;
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

function getAvg(sessions, key) {
  const valid = sessions.filter(s => s[key] > 0);
  if (!valid.length) return null;
  return valid.reduce((a, s) => a + s[key], 0) / valid.length;
}

function getTrend(sessions, key) {
  if (sessions.length < 4) return null;
  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  const half = Math.ceil(sorted.length / 2);
  const recent = sorted.slice(0, half).filter(s => s[key] > 0);
  const older = sorted.slice(half).filter(s => s[key] > 0);
  if (!recent.length || !older.length) return null;
  const recentAvg = recent.reduce((a, s) => a + s[key], 0) / recent.length;
  const olderAvg = older.reduce((a, s) => a + s[key], 0) / older.length;
  return recentAvg - olderAvg;
}

function getTrendLabel(trend) {
  if (trend === null) return null;
  if (trend > 1) return { text: 'Strong improvement', color: '#22c55e', icon: '🚀' };
  if (trend > 0.3) return { text: 'Improving', color: '#22c55e', icon: '📈' };
  if (trend > -0.3) return { text: 'Steady', color: '#f59e0b', icon: '→' };
  return { text: 'Needs attention', color: '#ef4444', icon: '📉' };
}

// ─── Main Component ──────────────────────────────────────────────────────────

export default function ProgressDashboard({ sessions, intentions }) {
  const streak = calcStreak(sessions);
  const totalSessions = sessions.length;
  const journaledSessions = sessions.filter(s => s.wentWell || s.ahamoment).length;

  const avgRating = getAvg(sessions, 'rating');
  const avgPatience = getAvg(sessions, 'patienceScore');
  const avgEmotions = getAvg(sessions, 'emotionsScore');
  const avgCommunication = getAvg(sessions, 'communicationScore');

  const patienceTrend = getTrend(sessions, 'patienceScore');
  const emotionsTrend = getTrend(sessions, 'emotionsScore');
  const commTrend = getTrend(sessions, 'communicationScore');

  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  const last5 = sorted.slice(0, 5);

  const growthMessages = getGrowthMessage(sessions, avgPatience, avgEmotions, avgCommunication);
  const quoteIdx = new Date().getDate() % PROCESS_QUOTES.length;

  return (
    <div style={{ padding: '20px 20px 100px' }} className="animate-fade-in">
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Your Growth</div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', marginBottom: 8 }}>
          Progress
        </h1>
        <p style={{ color: '#666', fontSize: '0.875rem' }}>
          {totalSessions > 0
            ? "Process metrics that show how you're actually growing as a player"
            : "Track the metrics that matter: patience, composure, and communication"}
        </p>
      </div>

      {/* ─── Streak Hero ──────────────────────────────────────── */}
      <div style={{
        background: streak > 0
          ? 'linear-gradient(135deg, #1a0e00, #241200)'
          : 'linear-gradient(135deg, #141414, #1e1e1e)',
        border: streak > 0 ? '1px solid rgba(249,115,22,0.4)' : '1px solid #2a2a2a',
        borderRadius: 24, padding: '24px', marginBottom: 20, textAlign: 'center',
        position: 'relative', overflow: 'hidden',
      }}>
        {streak > 0 && (
          <div style={{
            position: 'absolute', top: -30, right: -30,
            width: 120, height: 120, borderRadius: '50%',
            background: 'rgba(249,115,22,0.08)', pointerEvents: 'none',
          }} />
        )}
        <div style={{ fontSize: '3rem', marginBottom: 8 }}>
          {streak >= 7 ? '🏆' : streak > 0 ? '🔥' : '🏓'}
        </div>
        <div style={{ color: streak > 0 ? '#f97316' : '#c8f135', fontWeight: 900, fontSize: '3rem', lineHeight: 1 }}>
          {streak}
        </div>
        <div style={{ color: '#a0a0a0', fontSize: '0.875rem', marginTop: 4 }}>
          {streak === 0 ? 'day streak' : streak === 1 ? 'day streak — it begins!' : `day streak${streak >= 7 ? ' — unstoppable!' : ' — keep it going!'}`}
        </div>
        {streak === 0 && totalSessions === 0 && (
          <p style={{ color: '#555', fontSize: '0.82rem', marginTop: 10, lineHeight: 1.6 }}>
            Your first session lights the fire. Every day you show up and reflect, the streak grows — and so do you.
          </p>
        )}
        {streak === 0 && totalSessions > 0 && (
          <p style={{ color: '#555', fontSize: '0.82rem', marginTop: 10, lineHeight: 1.6 }}>
            Your streak reset, but your growth didn&apos;t. Every comeback starts with one session. Today?
          </p>
        )}
      </div>

      {/* ─── Personalized Growth Messages ──────────────────────── */}
      {growthMessages.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 20 }}>
          {growthMessages.map((msg, i) => (
            <div key={i} style={{
              background: `${msg.color}08`, border: `1px solid ${msg.color}25`,
              borderRadius: 16, padding: '14px 16px',
              display: 'flex', alignItems: 'flex-start', gap: 12,
            }}>
              <span style={{ fontSize: '1.25rem', flexShrink: 0 }}>{msg.icon}</span>
              <p style={{ color: '#c0c0c0', fontSize: '0.84rem', lineHeight: 1.6, margin: 0 }}>
                {msg.text}
              </p>
            </div>
          ))}
        </div>
      )}

      {/* ─── Stats Grid ───────────────────────────────────────── */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 20 }}>
        <StatCard
          icon={<Calendar size={16} color="#3b82f6" />}
          label="Total Sessions"
          value={totalSessions}
          sub={journaledSessions > 0 ? `${journaledSessions} with deep reflection` : 'start journaling to unlock insights'}
          accentColor="#3b82f6"
        />
        <StatCard
          icon={<Star size={16} color="#c8f135" />}
          label="Avg Self-Rating"
          value={avgRating ? avgRating.toFixed(1) : '—'}
          sub={avgRating ? (avgRating >= 4 ? 'you\'re playing well' : 'room to grow — that\'s exciting') : 'rate your sessions'}
          accentColor="#c8f135"
        />
        <StatCard
          icon={<Target size={16} color="#a855f7" />}
          label="Intentions Set"
          value={intentions?.length || 0}
          sub="pre-play focus sessions"
          accentColor="#a855f7"
        />
        <StatCard
          icon={<Flame size={16} color="#f97316" />}
          label="Current Streak"
          value={streak}
          sub={streak >= 7 ? 'incredible consistency' : streak > 0 ? 'building momentum' : 'play today to start'}
          accentColor="#f97316"
        />
      </div>

      {/* ─── Process Metrics ──────────────────────────────────── */}
      {totalSessions >= 2 && (avgPatience || avgEmotions || avgCommunication) && (
        <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 22, padding: '20px', marginBottom: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
            <span className="label-xs" style={{ color: '#555' }}>Process Scores</span>
            <span style={{ color: '#444', fontSize: '0.7rem' }}>10-point scale</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {avgPatience && (
              <MetricBar label="Patience" avg={avgPatience} trend={patienceTrend} icon="⏳" color="#c8f135"
                description="Your ability to wait for the right ball before attacking" />
            )}
            {avgEmotions && (
              <MetricBar label="Emotional Control" avg={avgEmotions} trend={emotionsTrend} icon="🌊" color="#3b82f6"
                description="How well you manage frustration and stay composed" />
            )}
            {avgCommunication && (
              <MetricBar label="Communication" avg={avgCommunication} trend={commTrend} icon="🤝" color="#22c55e"
                description="Partner coordination, calling balls, and encouragement" />
            )}
          </div>
        </div>
      )}

      {/* ─── Recent Sessions Timeline ─────────────────────────── */}
      {last5.length > 0 && (
        <div style={{ marginBottom: 20 }}>
          <div className="label-xs" style={{ color: '#555', marginBottom: 14 }}>Recent Sessions</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {last5.map((session, i) => (
              <TimelineSession key={session.id} session={session} isFirst={i === 0} />
            ))}
          </div>
        </div>
      )}

      {/* ─── Empty State ──────────────────────────────────────── */}
      {totalSessions === 0 && (
        <div style={{
          background: 'linear-gradient(135deg, #141414 0%, #0e1a0e 100%)',
          border: '1px solid rgba(200,241,53,0.15)', borderRadius: 24,
          padding: '44px 24px', textAlign: 'center',
        }}>
          <div style={{ fontSize: '3.5rem', marginBottom: 16 }}>📊</div>
          <h3 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.1rem', marginBottom: 12 }}>Your Growth Story Starts Here</h3>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.7, marginBottom: 8 }}>
            This dashboard tracks the things that actually make you better: <strong style={{ color: '#c8f135' }}>patience</strong>, <strong style={{ color: '#3b82f6' }}>emotional control</strong>, and <strong style={{ color: '#22c55e' }}>communication</strong>.
          </p>
          <p style={{ color: '#666', fontSize: '0.82rem', lineHeight: 1.6, margin: 0 }}>
            Log your first session, rate your process scores, and watch your growth unfold over time.
          </p>
        </div>
      )}

      {/* ─── Process Philosophy ────────────────────────────────── */}
      <div style={{
        background: 'rgba(200,241,53,0.04)', border: '1px solid rgba(200,241,53,0.12)',
        borderRadius: 18, padding: '16px', marginTop: totalSessions === 0 ? 20 : 0,
      }}>
        <p style={{ color: '#666', fontSize: '0.82rem', lineHeight: 1.7, margin: 0, fontStyle: 'italic' }}>
          &ldquo;{PROCESS_QUOTES[quoteIdx]}&rdquo;
        </p>
      </div>
    </div>
  );
}

// ─── Sub-Components ──────────────────────────────────────────────────────────

function StatCard({ icon, label, value, sub, accentColor }) {
  return (
    <div style={{
      background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
        {icon}
        <span className="label-xs" style={{ color: '#555' }}>{label}</span>
      </div>
      <div style={{ color: accentColor, fontWeight: 900, fontSize: '1.75rem', lineHeight: 1 }}>{value}</div>
      <div style={{ color: '#555', fontSize: '0.7rem', marginTop: 4 }}>{sub}</div>
    </div>
  );
}

function MetricBar({ label, avg, trend, icon, color, description }) {
  const pct = ((avg || 0) / 10) * 100;
  const trendLabel = getTrendLabel(trend);

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
        <span style={{ color: '#a0a0a0', fontSize: '0.875rem', display: 'flex', alignItems: 'center', gap: 6 }}>
          <span>{icon}</span> {label}
        </span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {trendLabel && (
            <span style={{ color: trendLabel.color, fontSize: '0.68rem', fontWeight: 600 }}>
              {trendLabel.icon} {trendLabel.text}
            </span>
          )}
          <span style={{ color, fontWeight: 800, fontSize: '0.9rem' }}>{(avg || 0).toFixed(1)}</span>
        </div>
      </div>
      <div className="progress-bar" style={{ marginBottom: 4 }}>
        <div className="progress-fill" style={{ width: `${pct}%`, background: `linear-gradient(90deg, ${color}, ${color}99)` }} />
      </div>
      <p style={{ color: '#444', fontSize: '0.68rem', margin: 0 }}>{description}</p>
    </div>
  );
}

function TimelineSession({ session, isFirst }) {
  const dateStr = session.date
    ? new Date(session.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    : '';

  return (
    <div style={{
      background: '#141414', border: isFirst ? '1px solid rgba(200,241,53,0.2)' : '1px solid #2a2a2a',
      borderRadius: 16, padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 12, flexShrink: 0,
        background: isFirst ? 'rgba(200,241,53,0.1)' : '#1e1e1e',
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1rem',
      }}>
        {session.rating === 5 ? '⭐' : session.rating >= 4 ? '🔥' : session.rating >= 3 ? '✅' : '📓'}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ color: '#f5f5f5', fontWeight: 600, fontSize: '0.85rem' }}>
          {session.gameType || 'Session'} · {session.skillFocus || 'General'}
        </div>
        <div style={{ color: '#555', fontSize: '0.72rem', marginTop: 2 }}>
          {dateStr}
          {session.patienceScore > 0 && ` · Patience: ${session.patienceScore}/10`}
        </div>
      </div>
      <div style={{ display: 'flex', gap: 3 }}>
        {[1, 2, 3, 4, 5].map(n => (
          <div key={n} style={{
            width: 6, height: 6, borderRadius: '50%',
            background: n <= (session.rating || 0) ? '#c8f135' : '#2a2a2a',
          }} />
        ))}
      </div>
    </div>
  );
}
