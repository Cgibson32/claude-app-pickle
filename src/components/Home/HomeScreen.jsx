import { useState } from 'react';
import { ChevronRight } from 'lucide-react';
import { getTodayIntention, MOOD_OPTIONS } from '../../data/intentionTemplates';

export default function HomeScreen({ profile, sessions, intentions, onNavigate }) {
  const todayKey = new Date().toISOString().split('T')[0];
  const savedToday = (intentions || []).find(i => i.date === todayKey);
  const today = savedToday ?? getTodayIntention();
  const firstName = profile?.name?.split(' ')[0] || 'Athlete';

  const dateDisplay = new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });

  const recentSessions = (sessions || []).slice(0, 3);

  return (
    <div className="animate-fade-in" style={{ paddingBottom: 100, background: '#0a0a0a' }}>
      <div style={{ padding: '24px 20px 0' }}>

        {/* Header */}
        <div style={{ marginBottom: 28 }}>
          <p style={{ color: '#555', fontSize: '0.75rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 6 }}>
            {dateDisplay}
          </p>
          <h1 style={{ fontSize: '1.8rem', fontWeight: 900, color: '#f5f5f5', letterSpacing: '-0.03em', margin: 0 }}>
            {firstName}
          </h1>
        </div>

        {/* Today's Intention */}
        <div style={{ marginBottom: 20 }}>
          <span className="label-xs" style={{ color: '#a0a0a0', textTransform: 'uppercase', letterSpacing: '0.1em', display: 'block', marginBottom: 10, fontWeight: 700 }}>
            TODAY&apos;S INTENTION
          </span>
          <div style={{
            background: '#141414',
            border: '1px solid #2a2a2a',
            borderRadius: 20,
            padding: '22px 20px',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
              <span style={{
                background: 'rgba(200,241,53,0.1)',
                border: '1px solid rgba(200,241,53,0.2)',
                color: '#c8f135',
                borderRadius: 20,
                padding: '4px 14px',
                fontSize: '0.7rem',
                fontWeight: 700,
                textTransform: 'uppercase',
                letterSpacing: '0.06em',
              }}>
                {today.theme}
              </span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <IntentionRow label="PERFORMANCE FOCUS" value={today.performance} />
              <IntentionRow label="MENTAL CUE" value={today.mental} />
            </div>

            <div style={{ marginTop: 18, paddingTop: 16, borderTop: '1px solid #2a2a2a' }}>
              <p style={{ color: '#f5f5f5', fontSize: '0.95rem', fontWeight: 700, margin: 0, lineHeight: 1.5, fontStyle: 'italic' }}>
                &ldquo;{today.quote}&rdquo;
              </p>
              <p style={{ color: '#555', fontSize: '0.75rem', margin: '6px 0 0', fontWeight: 500 }}>{today.cue}</p>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div style={{ marginBottom: 24 }}>
          <span className="label-xs" style={{ color: '#a0a0a0', textTransform: 'uppercase', letterSpacing: '0.1em', display: 'block', marginBottom: 10, fontWeight: 700 }}>
            QUICK ACTIONS
          </span>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <button
              onClick={() => onNavigate('journal', { mode: 'pre' })}
              className="press-scale"
              style={{
                background: 'rgba(200,241,53,0.08)',
                border: '1.5px solid rgba(200,241,53,0.25)',
                borderRadius: 16,
                padding: '18px 16px',
                cursor: 'pointer',
                textAlign: 'left',
              }}
            >
              <span style={{ color: '#c8f135', fontWeight: 700, fontSize: '0.88rem', display: 'block' }}>
                Set Intention
              </span>
              <span style={{ color: '#555', fontSize: '0.72rem', marginTop: 4, display: 'block' }}>
                Pre-session focus
              </span>
            </button>
            <button
              onClick={() => onNavigate('journal', { mode: 'post' })}
              className="press-scale"
              style={{
                background: '#141414',
                border: '1px solid #2a2a2a',
                borderRadius: 16,
                padding: '18px 16px',
                cursor: 'pointer',
                textAlign: 'left',
              }}
            >
              <span style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.88rem', display: 'block' }}>
                Log Session
              </span>
              <span style={{ color: '#555', fontSize: '0.72rem', marginTop: 4, display: 'block' }}>
                Post-session review
              </span>
            </button>
          </div>
        </div>

        {/* Recent Sessions */}
        {recentSessions.length > 0 && (
          <div>
            <span className="label-xs" style={{ color: '#a0a0a0', textTransform: 'uppercase', letterSpacing: '0.1em', display: 'block', marginBottom: 10, fontWeight: 700 }}>
              RECENT SESSIONS
            </span>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {recentSessions.map(s => (
                <SessionRow key={s.id} session={s} />
              ))}
            </div>
            <button
              onClick={() => onNavigate('journal')}
              style={{
                background: 'none',
                border: 'none',
                color: '#c8f135',
                fontSize: '0.78rem',
                fontWeight: 600,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 4,
                marginTop: 12,
                padding: 0,
              }}
            >
              View All <ChevronRight size={14} />
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function IntentionRow({ label, value }) {
  return (
    <div>
      <div className="label-xs" style={{ color: '#555', marginBottom: 3, textTransform: 'uppercase', letterSpacing: '0.08em', fontWeight: 700, fontSize: '0.65rem' }}>
        {label}
      </div>
      <div style={{ color: '#d0d0d0', fontSize: '0.88rem', fontWeight: 500, lineHeight: 1.4 }}>
        {value}
      </div>
    </div>
  );
}

function SessionRow({ session }) {
  const dateStr = session.date
    ? new Date(session.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    : '--';

  const processScores = [];
  if (session.patienceScore) processScores.push({ label: 'PAT', value: session.patienceScore });
  if (session.emotionsScore) processScores.push({ label: 'EMO', value: session.emotionsScore });
  if (session.communicationScore) processScores.push({ label: 'COM', value: session.communicationScore });

  return (
    <div style={{
      background: '#141414',
      border: '1px solid #2a2a2a',
      borderRadius: 16,
      padding: '14px 16px',
      display: 'flex',
      alignItems: 'center',
      gap: 12,
    }}>
      <div style={{ flex: 1 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.88rem' }}>
            {session.gameType || 'Session'}
          </span>
          <span style={{ color: '#555', fontSize: '0.72rem', fontWeight: 500 }}>
            {dateStr}
          </span>
        </div>
        {processScores.length > 0 && (
          <div style={{ display: 'flex', gap: 10, marginTop: 6 }}>
            {processScores.map(ps => (
              <span key={ps.label} style={{ color: '#a0a0a0', fontSize: '0.68rem', fontWeight: 600, letterSpacing: '0.04em' }}>
                {ps.label} {ps.value}/10
              </span>
            ))}
          </div>
        )}
      </div>
      {session.rating > 0 && (
        <div style={{ display: 'flex', gap: 3, flexShrink: 0 }}>
          {[1, 2, 3, 4, 5].map(i => (
            <div key={i} style={{
              width: 7,
              height: 7,
              borderRadius: '50%',
              background: i <= session.rating ? '#c8f135' : '#2a2a2a',
            }} />
          ))}
        </div>
      )}
    </div>
  );
}
