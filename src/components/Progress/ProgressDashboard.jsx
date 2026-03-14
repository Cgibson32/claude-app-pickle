import { useState } from 'react';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

// ─── Helpers ─────────────────────────────────────────────────────────────────

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

function getTrendInfo(trend) {
  if (trend === null) return null;
  if (trend > 0.3) return { text: 'Improving', color: '#22c55e', Icon: TrendingUp };
  if (trend >= -0.3) return { text: 'Steady', color: '#f59e0b', Icon: Minus };
  return { text: 'Declining', color: '#ef4444', Icon: TrendingDown };
}

function getProcessAvg(session) {
  const scores = [session.patienceScore, session.emotionsScore, session.communicationScore].filter(s => s > 0);
  if (!scores.length) return null;
  return scores.reduce((a, b) => a + b, 0) / scores.length;
}

// ─── Main Component ──────────────────────────────────────────────────────────

export default function ProgressDashboard({ sessions, intentions }) {
  const totalSessions = sessions.length;
  const avgRating = getAvg(sessions, 'rating');
  const avgPatience = getAvg(sessions, 'patienceScore');
  const avgEmotions = getAvg(sessions, 'emotionsScore');
  const avgCommunication = getAvg(sessions, 'communicationScore');

  const processScores = [avgPatience, avgEmotions, avgCommunication].filter(v => v !== null);
  const avgProcessScore = processScores.length
    ? processScores.reduce((a, b) => a + b, 0) / processScores.length
    : null;

  const patienceTrend = getTrend(sessions, 'patienceScore');
  const emotionsTrend = getTrend(sessions, 'emotionsScore');
  const commTrend = getTrend(sessions, 'communicationScore');

  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  const last5 = sorted.slice(0, 5);

  const hasTrends = patienceTrend !== null || emotionsTrend !== null || commTrend !== null;
  const hasProcessMetrics = totalSessions >= 2 && (avgPatience || avgEmotions || avgCommunication);

  // ─── Empty State ───────────────────────────────────────────
  if (totalSessions === 0) {
    return (
      <div style={{ padding: '20px 20px 100px', background: '#0a0a0a', minHeight: '100vh' }}>
        <div style={{ marginBottom: 24 }}>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>PROGRESS</div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', margin: 0 }}>
            Performance Analytics
          </h1>
        </div>
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16,
          padding: '48px 24px', textAlign: 'center',
        }}>
          <div style={{
            width: 48, height: 48, borderRadius: 12, background: '#1e1e1e',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 20px',
          }}>
            <Minus size={24} color="#555" />
          </div>
          <h3 style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '1rem', marginBottom: 12 }}>
            No sessions logged yet.
          </h3>
          <p style={{ color: '#666', fontSize: '0.875rem', lineHeight: 1.7, margin: 0, maxWidth: 320, marginLeft: 'auto', marginRight: 'auto' }}>
            Complete your first post-play reflection to start tracking progress.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: '20px 20px 100px', background: '#0a0a0a', minHeight: '100vh' }} className="animate-fade-in">
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>PROGRESS</div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', margin: 0 }}>
          Performance Analytics
        </h1>
      </div>

      {/* ─── Overview Cards ────────────────────────────────────── */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 20 }}>
        <OverviewCard label="Total Sessions" value={totalSessions} color="#3b82f6" />
        <OverviewCard label="Avg Rating" value={avgRating ? avgRating.toFixed(1) : '--'} color="#c8f135" />
        <OverviewCard label="Avg Process" value={avgProcessScore ? avgProcessScore.toFixed(1) : '--'} color="#a855f7" />
      </div>

      {/* ─── Process Metrics ───────────────────────────────────── */}
      {hasProcessMetrics && (
        <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16, padding: '20px', marginBottom: 20 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
            <span className="label-xs" style={{ color: '#555' }}>PROCESS METRICS</span>
            <span style={{ color: '#444', fontSize: '0.7rem', fontWeight: 600 }}>OUT OF 10</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
            {avgPatience !== null && (
              <ProcessBar label="Patience" value={avgPatience} color="#c8f135" />
            )}
            {avgEmotions !== null && (
              <ProcessBar label="Emotional Control" value={avgEmotions} color="#3b82f6" />
            )}
            {avgCommunication !== null && (
              <ProcessBar label="Communication" value={avgCommunication} color="#a855f7" />
            )}
          </div>
        </div>
      )}

      {/* ─── Trend Section ─────────────────────────────────────── */}
      {hasTrends && (
        <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16, padding: '20px', marginBottom: 20 }}>
          <div className="label-xs" style={{ color: '#555', marginBottom: 16 }}>TRENDS</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {patienceTrend !== null && <TrendRow label="Patience" trend={patienceTrend} />}
            {emotionsTrend !== null && <TrendRow label="Emotional Control" trend={emotionsTrend} />}
            {commTrend !== null && <TrendRow label="Communication" trend={commTrend} />}
          </div>
        </div>
      )}

      {/* ─── Recent Sessions ───────────────────────────────────── */}
      {last5.length > 0 && (
        <div style={{ marginBottom: 20 }}>
          <div className="label-xs" style={{ color: '#555', marginBottom: 14 }}>RECENT SESSIONS</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {last5.map((session) => (
              <SessionRow key={session.id} session={session} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Sub-Components ──────────────────────────────────────────────────────────

function OverviewCard({ label, value, color }) {
  return (
    <div style={{
      background: '#141414', border: '1px solid #2a2a2a', borderRadius: 14, padding: '16px 12px',
      textAlign: 'center',
    }}>
      <div style={{ color, fontWeight: 800, fontSize: '1.5rem', lineHeight: 1, marginBottom: 6 }}>
        {value}
      </div>
      <div style={{ color: '#666', fontSize: '0.68rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.04em' }}>
        {label}
      </div>
    </div>
  );
}

function ProcessBar({ label, value, color }) {
  const pct = Math.min(((value || 0) / 10) * 100, 100);

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
        <span style={{ color: '#a0a0a0', fontSize: '0.85rem', fontWeight: 600 }}>{label}</span>
        <span style={{ color, fontWeight: 800, fontSize: '0.9rem' }}>{(value || 0).toFixed(1)}</span>
      </div>
      <div style={{
        width: '100%', height: 8, borderRadius: 4, background: '#1e1e1e', overflow: 'hidden',
      }}>
        <div style={{
          width: `${pct}%`, height: '100%', borderRadius: 4,
          background: `linear-gradient(90deg, ${color}, ${color}aa)`,
          transition: 'width 0.4s ease',
        }} />
      </div>
    </div>
  );
}

function TrendRow({ label, trend }) {
  const info = getTrendInfo(trend);
  if (!info) return null;
  const { text, color, Icon } = info;

  return (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '8px 0', borderBottom: '1px solid #1e1e1e',
    }}>
      <span style={{ color: '#a0a0a0', fontSize: '0.85rem', fontWeight: 600 }}>{label}</span>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <Icon size={14} color={color} />
        <span style={{ color, fontSize: '0.8rem', fontWeight: 700 }}>{text}</span>
      </div>
    </div>
  );
}

function SessionRow({ session }) {
  const dateStr = session.date
    ? new Date(session.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    : '--';
  const processAvg = getProcessAvg(session);

  return (
    <div style={{
      background: '#141414', border: '1px solid #2a2a2a', borderRadius: 12,
      padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 14,
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.85rem', marginBottom: 2 }}>
          {session.gameType || 'Session'}
        </div>
        <div style={{ color: '#555', fontSize: '0.72rem' }}>{dateStr}</div>
      </div>
      <div style={{ textAlign: 'right', flexShrink: 0 }}>
        <div style={{ color: '#c8f135', fontWeight: 800, fontSize: '0.85rem' }}>
          {session.rating ? `${session.rating}/5` : '--'}
        </div>
        <div style={{ color: '#666', fontSize: '0.68rem', marginTop: 1 }}>
          {processAvg !== null ? `Process: ${processAvg.toFixed(1)}` : ''}
        </div>
      </div>
    </div>
  );
}
