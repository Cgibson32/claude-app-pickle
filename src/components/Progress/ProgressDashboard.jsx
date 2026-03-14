import { Flame, Target, Star, Calendar } from 'lucide-react';

function calcStreak(sessions) {
  if (!sessions.length) return 0;
  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  let streak = 0;
  for (let i = 0; i < sorted.length; i++) {
    const diff = (Date.now() - new Date(sorted[i].date)) / (1000 * 60 * 60 * 24);
    if (i === 0 && diff > 2) break;
    streak++;
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
  const recent = sorted.slice(0, Math.ceil(sorted.length / 2)).filter(s => s[key] > 0);
  const older = sorted.slice(Math.ceil(sorted.length / 2)).filter(s => s[key] > 0);
  if (!recent.length || !older.length) return null;
  const recentAvg = recent.reduce((a, s) => a + s[key], 0) / recent.length;
  const olderAvg = older.reduce((a, s) => a + s[key], 0) / older.length;
  return recentAvg - olderAvg;
}

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

  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  const last5 = sorted.slice(0, 5);

  return (
    <div style={{ padding: '20px 20px 100px' }} className="animate-fade-in">
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Your Growth</div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', marginBottom: 8 }}>
          Progress
        </h1>
        <p style={{ color: '#666', fontSize: '0.875rem' }}>
          Process metrics that reflect how you&apos;re actually improving
        </p>
      </div>

      {/* Streak Hero */}
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
          {streak > 0 ? '🔥' : '🏓'}
        </div>
        <div style={{ color: streak > 0 ? '#f97316' : '#c8f135', fontWeight: 900, fontSize: '3rem', lineHeight: 1 }}>
          {streak}
        </div>
        <div style={{ color: '#a0a0a0', fontSize: '0.875rem', marginTop: 4 }}>
          {streak === 1 ? 'Session streak' : streak > 1 ? 'Session streak 🔥' : 'sessions logged'}
        </div>
        {streak === 0 && (
          <p style={{ color: '#555', fontSize: '0.8rem', marginTop: 8 }}>
            Log your first session to start your streak
          </p>
        )}
      </div>

      {/* Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 20 }}>
        <StatCard
          icon={<Calendar size={16} color="#3b82f6" />}
          label="Total Sessions"
          value={totalSessions}
          sub={`${journaledSessions} with reflection`}
          accentColor="#3b82f6"
        />
        <StatCard
          icon={<Star size={16} color="#c8f135" />}
          label="Avg Rating"
          value={avgRating ? avgRating.toFixed(1) : '—'}
          sub="self assessment"
          accentColor="#c8f135"
        />
        <StatCard
          icon={<Target size={16} color="#a855f7" />}
          label="Intentions Set"
          value={intentions?.length || 0}
          sub="pre-play focus"
          accentColor="#a855f7"
        />
        <StatCard
          icon={<Flame size={16} color="#f97316" />}
          label="Best Streak"
          value={streak}
          sub="consecutive sessions"
          accentColor="#f97316"
        />
      </div>

      {/* Process Metrics */}
      {totalSessions >= 2 && (
        <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 22, padding: '20px', marginBottom: 20 }}>
          <div className="label-xs" style={{ color: '#555', marginBottom: 16 }}>Process Scores (10-point scale)</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            {[
              { label: 'Patience', avg: avgPatience, trend: patienceTrend, icon: '⏳', color: '#c8f135' },
              { label: 'Emotional Control', avg: avgEmotions, trend: emotionsTrend, icon: '🌊', color: '#3b82f6' },
              { label: 'Communication', avg: avgCommunication, trend: null, icon: '🤝', color: '#22c55e' },
            ].map(m => m.avg && (
              <MetricBar key={m.label} {...m} />
            ))}
          </div>
        </div>
      )}

      {/* Recent Sessions Timeline */}
      {last5.length > 0 && (
        <div>
          <div className="label-xs" style={{ color: '#555', marginBottom: 14 }}>Recent Sessions</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {last5.map((session, i) => (
              <TimelineSession key={session.id} session={session} isFirst={i === 0} />
            ))}
          </div>
        </div>
      )}

      {/* Empty state */}
      {totalSessions === 0 && (
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 24,
          padding: '40px 24px', textAlign: 'center',
        }}>
          <div style={{ fontSize: '3rem', marginBottom: 16 }}>📊</div>
          <h3 style={{ color: '#f5f5f5', fontWeight: 700, marginBottom: 8 }}>Nothing to track yet</h3>
          <p style={{ color: '#555', fontSize: '0.875rem', lineHeight: 1.6, margin: 0 }}>
            Log sessions in your journal to see process metrics, trends, and growth insights here.
          </p>
        </div>
      )}

      {/* Process philosophy note */}
      <div style={{
        background: 'rgba(200,241,53,0.04)', border: '1px solid rgba(200,241,53,0.15)',
        borderRadius: 18, padding: '16px', marginTop: 20,
      }}>
        <p style={{ color: '#666', fontSize: '0.8rem', lineHeight: 1.7, margin: 0, fontStyle: 'italic' }}>
          "These metrics track how you play, not just whether you win. A player who scores 8/10 on patience and emotional control is building habits that will outlast any single result."
        </p>
      </div>
    </div>
  );
}

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

function MetricBar({ label, avg, trend, icon, color }) {
  const pct = ((avg || 0) / 10) * 100;
  const trendIcon = trend === null ? '' : trend > 0.5 ? '↑' : trend < -0.5 ? '↓' : '→';
  const trendColor = trend === null ? '#555' : trend > 0.5 ? '#22c55e' : trend < -0.5 ? '#ef4444' : '#555';

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
        <span style={{ color: '#a0a0a0', fontSize: '0.875rem', display: 'flex', alignItems: 'center', gap: 6 }}>
          <span>{icon}</span> {label}
        </span>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {trendIcon && (
            <span style={{ color: trendColor, fontSize: '0.75rem', fontWeight: 700 }}>{trendIcon}</span>
          )}
          <span style={{ color, fontWeight: 800, fontSize: '0.9rem' }}>{(avg || 0).toFixed(1)}</span>
        </div>
      </div>
      <div className="progress-bar">
        <div className="progress-fill" style={{ width: `${pct}%`, background: `linear-gradient(90deg, ${color}, ${color}99)` }} />
      </div>
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
