import { useState } from 'react';
import { ChevronLeft, ChevronRight, Trash2 } from 'lucide-react';
import {
  MOOD_OPTIONS, GAME_TYPES, SKILL_FOCUS_OPTIONS,
  getTodayIntention,
} from '../../data/intentionTemplates';
import { useAppActions } from '../../context/AppContext';

// ─── Main Screen ──────────────────────────────────────────────────────────────
export default function JournalScreen({ sessions, onSave, onDelete, initialMode }) {
  const { saveIntention } = useAppActions();
  const [view, setView] = useState(initialMode || 'list');
  const [selectedSession, setSelectedSession] = useState(null);
  const [prePlayData, setPrePlayData] = useState(null);

  const handlePrePlayDone = (data) => {
    const template = getTodayIntention();
    saveIntention({
      date: new Date().toISOString().split('T')[0],
      theme: template.theme,
      performance: template.performance,
      mental: template.mental,
      joy: template.joy,
      quote: template.quote,
      cue: template.cue,
      technicalFocus: data.technicalIntent,
      mentalFocus: data.mentalIntent,
      gameType: data.gameType,
      prePlayMood: data.mood,
      energyLevel: data.energyLevel,
    });
    setPrePlayData(data);
    setView('list');
  };

  if (view === 'pre') {
    return <PrePlayFlow onDone={handlePrePlayDone} onBack={() => setView('list')} />;
  }
  if (view === 'post') {
    return <PostPlayFlow prePlayData={prePlayData} sessionCount={sessions.length} onSave={(s) => { onSave(s); setView('list'); }} onBack={() => setView('list')} />;
  }
  if (view === 'detail' && selectedSession) {
    return <SessionDetail session={selectedSession} onBack={() => { setSelectedSession(null); setView('list'); }} onDelete={(id) => { onDelete(id); setSelectedSession(null); setView('list'); }} />;
  }

  const recentSession = sessions.length > 0
    ? [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date))[0]
    : null;

  return (
    <div style={{ padding: '20px 20px 100px' }} className="animate-fade-in">
      <div style={{ marginBottom: 24 }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Session Journal</div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', marginBottom: 8 }}>
          Training Log
        </h1>
        <p style={{ color: '#888', fontSize: '0.875rem', lineHeight: 1.6 }}>
          Track sessions, review performance, identify patterns.
          {sessions.length > 0 && (
            <span style={{ color: '#c8f135' }}> {sessions.length} session{sessions.length !== 1 ? 's' : ''} logged.</span>
          )}
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 28 }}>
        <JournalCTA
          icon="PRE"
          label="Before Play"
          sub="Set intentions"
          accent
          onClick={() => setView('pre')}
        />
        <JournalCTA
          icon="POST"
          label="After Play"
          sub="Log session"
          onClick={() => setView('post')}
        />
      </div>

      {recentSession?.coachCue && (
        <div style={{
          background: 'rgba(168,85,247,0.06)', border: '1px solid rgba(168,85,247,0.2)',
          borderRadius: 18, padding: '16px', marginBottom: 20,
        }}>
          <div className="label-xs" style={{ color: '#a855f7', marginBottom: 8 }}>Last Coaching Cue</div>
          <p style={{ color: '#f5f5f5', fontSize: '0.875rem', margin: 0, lineHeight: 1.6 }}>
            {recentSession.coachCue}
          </p>
        </div>
      )}

      {sessions.length === 0 ? (
        <EmptyJournal onStartPre={() => setView('pre')} />
      ) : (
        <div>
          <div className="label-xs" style={{ color: '#555', marginBottom: 12 }}>
            {sessions.length} Session{sessions.length !== 1 ? 's' : ''} Logged
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[...sessions].sort((a, b) => new Date(b.date) - new Date(a.date)).map(s => (
              <SessionCard
                key={s.id}
                session={s}
                onClick={() => { setSelectedSession(s); setView('detail'); }}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Pre-Play Flow ─────────────────────────────────────────────────────────────
function PrePlayFlow({ onDone, onBack }) {
  const [step, setStep] = useState(0);
  const [data, setData] = useState({
    mood: '',
    energyLevel: 5,
    technicalIntent: '',
    mentalIntent: '',
    partnerNote: '',
    gameType: '',
  });

  const todayTheme = getTodayIntention();

  const steps = [
    { title: 'Pre-Session\nCheck-In', subtitle: 'Current state assessment.', component: <MoodStep data={data} setData={setData} /> },
    { title: 'Session\nIntentions', subtitle: `Today\'s theme: ${todayTheme.theme}`, component: <IntentionStep data={data} setData={setData} todayTheme={todayTheme} /> },
    { title: 'Session\nReady', subtitle: null, component: <PreReadyStep data={data} todayTheme={todayTheme} onConfirm={() => onDone(data)} /> },
  ];

  const current = steps[step];

  return (
    <div style={{ minHeight: '100vh', background: '#0a0a0a', display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '20px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', color: '#666', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.875rem' }}>
          <ChevronLeft size={16} /> Back
        </button>
        <div className="label-xs" style={{ color: '#c8f135' }}>Before Play</div>
        <div style={{ width: 60 }} />
      </div>

      <div style={{ padding: '16px 20px 0' }}>
        <div className="progress-bar">
          <div className="progress-fill" style={{ width: `${((step + 1) / steps.length) * 100}%` }} />
        </div>
      </div>

      <div style={{ flex: 1, padding: '32px 20px 100px', overflowY: 'auto' }}>
        <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2, marginBottom: 8, whiteSpace: 'pre-line' }}>
          {current.title}
        </h2>
        {current.subtitle && (
          <p style={{ color: '#888', fontSize: '0.875rem', marginBottom: 24, lineHeight: 1.5 }}>{current.subtitle}</p>
        )}
        {!current.subtitle && <div style={{ marginBottom: 20 }} />}
        {current.component}
      </div>

      {step < steps.length - 1 && (
        <div style={{ padding: '16px 20px', borderTop: '1px solid #2a2a2a' }}>
          <button
            onClick={() => setStep(s => s + 1)}
            className="press-scale"
            style={{
              width: '100%', background: 'linear-gradient(135deg, #c8f135, #a8d820)',
              color: '#0a0a0a', border: 'none', borderRadius: 16,
              padding: '16px', fontWeight: 800, fontSize: '0.95rem', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}
          >
            Continue <ChevronRight size={16} />
          </button>
        </div>
      )}
    </div>
  );
}

function MoodStep({ data, setData }) {
  const MOOD_COLORS = {
    'fired-up': '#ef4444',
    'focused': '#c8f135',
    'calm': '#3b82f6',
    'nervous': '#f97316',
    'tired': '#6b7280',
    'determined': '#a855f7',
    'frustrated': '#dc2626',
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
        {MOOD_OPTIONS.map(m => {
          const isSelected = data.mood === m.id;
          const borderColor = MOOD_COLORS[m.id] || '#c8f135';
          return (
            <button
              key={m.id}
              onClick={() => setData(d => ({ ...d, mood: m.id }))}
              className="press-scale"
              style={{
                background: isSelected ? 'rgba(200,241,53,0.06)' : '#141414',
                border: isSelected ? `2px solid ${borderColor}` : '1px solid #2a2a2a',
                borderRadius: 16, padding: '14px 8px', cursor: 'pointer', textAlign: 'center',
              }}
            >
              <div style={{
                color: isSelected ? borderColor : '#a0a0a0',
                fontSize: '0.8rem', fontWeight: 700, letterSpacing: '0.02em',
              }}>
                {m.label}
              </div>
            </button>
          );
        })}
      </div>

      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <span style={{ color: '#a0a0a0', fontSize: '0.875rem', fontWeight: 600 }}>Energy Level</span>
          <span style={{ color: '#c8f135', fontWeight: 800, fontSize: '1.1rem' }}>{data.energyLevel}/10</span>
        </div>
        <input
          type="range" min="1" max="10" value={data.energyLevel}
          onChange={e => setData(d => ({ ...d, energyLevel: +e.target.value }))}
          style={{ accentColor: '#c8f135' }}
        />
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
          <span style={{ color: '#444', fontSize: '0.7rem' }}>Low</span>
          <span style={{ color: '#444', fontSize: '0.7rem' }}>High</span>
        </div>
      </div>
    </div>
  );
}

function IntentionStep({ data, setData, todayTheme }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{
        background: 'rgba(200,241,53,0.06)', border: '1px solid rgba(200,241,53,0.2)',
        borderRadius: 18, padding: '16px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
          <div style={{
            width: 36, height: 36, borderRadius: '50%',
            background: 'linear-gradient(135deg, #c8f135, #a8d820)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: '1rem', fontWeight: 800, color: '#0a0a0a',
          }}>
            {todayTheme.theme[0]}
          </div>
          <div>
            <div style={{ color: '#c8f135', fontWeight: 700, fontSize: '0.9rem' }}>Theme: {todayTheme.theme}</div>
            <div style={{ color: '#888', fontSize: '0.78rem' }}>{todayTheme.mental}</div>
          </div>
        </div>
      </div>

      <div>
        <div className="label-xs" style={{ color: '#555', marginBottom: 10 }}>Game Type</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {GAME_TYPES.slice(0, 5).map(type => (
            <button
              key={type}
              onClick={() => setData(d => ({ ...d, gameType: type }))}
              style={{
                background: data.gameType === type ? 'rgba(200,241,53,0.1)' : '#141414',
                border: data.gameType === type ? '1.5px solid rgba(200,241,53,0.4)' : '1px solid #2a2a2a',
                color: data.gameType === type ? '#c8f135' : '#a0a0a0',
                borderRadius: 20, padding: '7px 14px', fontSize: '0.78rem', fontWeight: 600, cursor: 'pointer',
              }}
            >
              {type}
            </button>
          ))}
        </div>
      </div>

      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 10 }}>Technical Focus</div>
        <textarea
          value={data.technicalIntent}
          onChange={e => setData(d => ({ ...d, technicalIntent: e.target.value }))}
          placeholder={`e.g., ${todayTheme.performance} — ${todayTheme.cue}`}
          rows={2}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.6, resize: 'none', outline: 'none',
          }}
        />
      </div>

      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#60a5fa', marginBottom: 10 }}>Mental Intention</div>
        <textarea
          value={data.mentalIntent}
          onChange={e => setData(d => ({ ...d, mentalIntent: e.target.value }))}
          placeholder="e.g., Stay composed after errors. One point at a time."
          rows={2}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.6, resize: 'none', outline: 'none',
          }}
        />
      </div>
    </div>
  );
}

function PreReadyStep({ data, todayTheme, onConfirm }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {data.technicalIntent && (
        <div style={{ background: 'rgba(200,241,53,0.08)', border: '1px solid rgba(200,241,53,0.2)', borderRadius: 18, padding: '16px' }}>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Technical Focus</div>
          <p style={{ color: '#f5f5f5', fontSize: '0.9rem', margin: 0, lineHeight: 1.6 }}>{data.technicalIntent}</p>
        </div>
      )}
      {data.mentalIntent && (
        <div style={{ background: 'rgba(59,130,246,0.08)', border: '1px solid rgba(59,130,246,0.2)', borderRadius: 18, padding: '16px' }}>
          <div className="label-xs" style={{ color: '#60a5fa', marginBottom: 8 }}>Mental Intention</div>
          <p style={{ color: '#f5f5f5', fontSize: '0.9rem', margin: 0, lineHeight: 1.6 }}>{data.mentalIntent}</p>
        </div>
      )}
      {data.gameType && (
        <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px' }}>
          <div className="label-xs" style={{ color: '#555', marginBottom: 8 }}>Game Type</div>
          <p style={{ color: '#f5f5f5', fontSize: '0.9rem', margin: 0 }}>{data.gameType}</p>
        </div>
      )}

      <button
        onClick={onConfirm}
        className="press-scale"
        style={{
          width: '100%', background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          color: '#0a0a0a', border: 'none', borderRadius: 16,
          padding: '16px', fontWeight: 800, fontSize: '0.95rem', cursor: 'pointer',
          marginTop: 8,
        }}
      >
        Start Session
      </button>
    </div>
  );
}

// ─── Post-Play Flow ────────────────────────────────────────────────────────────
function PostPlayFlow({ prePlayData, sessionCount, onSave, onBack }) {
  const [step, setStep] = useState(0);
  const [data, setData] = useState(() => ({
    id: String(Date.now()),
    date: new Date().toISOString(),
    gameType: prePlayData?.gameType || '',
    mood: prePlayData?.mood || '',
    energyLevel: prePlayData?.energyLevel || 5,
    skillFocus: '',
    rating: 0,
    wentWell: '',
    patienceScore: 5,
    patienceNotes: '',
    emotionsScore: 5,
    emotionsNotes: '',
    communicationScore: 5,
    improveFocus: '',
    highlights: '',
    ahamoment: '',
    coachCue: '',
  }));

  const steps = [
    { title: 'Session\nRating', subtitle: 'Rate this session honestly.', component: <RatingStep data={data} setData={setData} /> },
    { title: 'Session\nNotes', subtitle: 'What happened on court.', component: <WentWellStep data={data} setData={setData} /> },
    { title: 'Process\nScorecard', subtitle: 'Rate the controllable metrics.', component: <ProcessReviewStep data={data} setData={setData} /> },
    { title: 'Key\nTakeaways', subtitle: 'Capture what matters most.', component: <GrowthStep data={data} setData={setData} /> },
    { title: 'Session\nSummary', subtitle: null, component: <PostSummaryStep data={data} sessionCount={sessionCount} onSave={() => onSave(data)} /> },
  ];

  const current = steps[step];
  const isLast = step === steps.length - 1;

  return (
    <div style={{ minHeight: '100vh', background: '#0a0a0a', display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '20px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', color: '#666', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.875rem' }}>
          <ChevronLeft size={16} /> Back
        </button>
        <div className="label-xs" style={{ color: '#c8f135' }}>Post-Session Review</div>
        <div className="label-xs" style={{ color: '#555' }}>{step + 1}/{steps.length}</div>
      </div>

      <div style={{ padding: '12px 20px 0' }}>
        <div className="progress-bar">
          <div className="progress-fill" style={{ width: `${((step + 1) / steps.length) * 100}%` }} />
        </div>
      </div>

      <div style={{ flex: 1, padding: '28px 20px 120px', overflowY: 'auto' }}>
        <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2, marginBottom: 8, whiteSpace: 'pre-line' }}>
          {current.title}
        </h2>
        {current.subtitle && (
          <p style={{ color: '#888', fontSize: '0.85rem', marginBottom: 20, lineHeight: 1.5 }}>{current.subtitle}</p>
        )}
        {!current.subtitle && <div style={{ marginBottom: 16 }} />}
        {current.component}
      </div>

      {!isLast && (
        <div style={{ padding: '16px 20px', borderTop: '1px solid #2a2a2a' }}>
          <button
            onClick={() => setStep(s => s + 1)}
            className="press-scale"
            style={{
              width: '100%', background: 'linear-gradient(135deg, #c8f135, #a8d820)',
              color: '#0a0a0a', border: 'none', borderRadius: 16,
              padding: '16px', fontWeight: 800, fontSize: '0.95rem', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            }}
          >
            Continue <ChevronRight size={16} />
          </button>
        </div>
      )}
    </div>
  );
}

function RatingStep({ data, setData }) {
  const ratingLabels = {
    0: 'Select a rating',
    1: 'Poor session',
    2: 'Below average',
    3: 'Average session',
    4: 'Strong session',
    5: 'Excellent session',
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '20px', textAlign: 'center' }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 16 }}>Overall Rating</div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 12, marginBottom: 16 }}>
          {[1, 2, 3, 4, 5].map(n => (
            <button
              key={n}
              onClick={() => setData(d => ({ ...d, rating: n }))}
              style={{
                width: 48, height: 48, borderRadius: '50%', cursor: 'pointer',
                background: n <= data.rating ? 'rgba(200,241,53,0.15)' : '#1e1e1e',
                border: n <= data.rating ? '1.5px solid rgba(200,241,53,0.5)' : '1px solid #333',
                fontSize: '1.25rem', display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: n <= data.rating ? '#c8f135' : '#555',
                fontWeight: 800,
                transition: 'all 0.2s',
              }}
            >
              {n <= data.rating ? '\u2605' : '\u2606'}
            </button>
          ))}
        </div>
        <p style={{
          color: data.rating > 0 ? '#c8f135' : '#555',
          fontWeight: 600, fontSize: '0.85rem', margin: 0,
        }}>
          {ratingLabels[data.rating]}
        </p>
      </div>

      <div>
        <div className="label-xs" style={{ color: '#555', marginBottom: 10 }}>Skill Focus</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
          {SKILL_FOCUS_OPTIONS.map(s => (
            <button
              key={s}
              onClick={() => setData(d => ({ ...d, skillFocus: s }))}
              style={{
                background: data.skillFocus === s ? 'rgba(200,241,53,0.1)' : '#141414',
                border: data.skillFocus === s ? '1.5px solid rgba(200,241,53,0.4)' : '1px solid #2a2a2a',
                color: data.skillFocus === s ? '#c8f135' : '#a0a0a0',
                borderRadius: 20, padding: '7px 14px', fontSize: '0.78rem', fontWeight: 600, cursor: 'pointer',
              }}
            >
              {s}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

function WentWellStep({ data, setData }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 10 }}>What Went Well</div>
        <textarea
          value={data.wentWell}
          onChange={e => setData(d => ({ ...d, wentWell: e.target.value }))}
          placeholder="Technical, mental, or tactical positives from this session."
          rows={4}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>

      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#f97316', marginBottom: 10 }}>Focus for Next Time</div>
        <textarea
          value={data.improveFocus}
          onChange={e => setData(d => ({ ...d, improveFocus: e.target.value }))}
          placeholder="One specific area to target in the next session."
          rows={3}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>
    </div>
  );
}

function ProcessReviewStep({ data, setData }) {
  const metrics = [
    { key: 'patienceScore', label: 'Patience' },
    { key: 'emotionsScore', label: 'Emotional Control' },
    { key: 'communicationScore', label: 'Communication' },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {metrics.map(m => (
        <div key={m.key} style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <span style={{ color: '#a0a0a0', fontWeight: 700, fontSize: '0.9rem' }}>{m.label}</span>
            <span style={{ color: '#c8f135', fontWeight: 800, fontSize: '1.1rem' }}>{data[m.key]}/10</span>
          </div>
          <input
            type="range" min="1" max="10" value={data[m.key]}
            onChange={e => setData(d => ({ ...d, [m.key]: +e.target.value }))}
            style={{ accentColor: '#c8f135' }}
          />
        </div>
      ))}
    </div>
  );
}

function GrowthStep({ data, setData }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 10 }}>Highlight</div>
        <textarea
          value={data.highlights}
          onChange={e => setData(d => ({ ...d, highlights: e.target.value }))}
          placeholder="Best moment or play from this session."
          rows={3}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#3b82f6', marginBottom: 10 }}>Insight</div>
        <textarea
          value={data.ahamoment}
          onChange={e => setData(d => ({ ...d, ahamoment: e.target.value }))}
          placeholder="Something you noticed or learned today."
          rows={3}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#a855f7', marginBottom: 10 }}>Coaching Cue</div>
        <textarea
          value={data.coachCue}
          onChange={e => setData(d => ({ ...d, coachCue: e.target.value }))}
          placeholder="One cue to carry into the next session."
          rows={2}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>
    </div>
  );
}

function PostSummaryStep({ data, onSave }) {
  const avgProcess = Math.round(((data.patienceScore || 5) + (data.emotionsScore || 5) + (data.communicationScore || 5)) / 3 * 10) / 10;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px' }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 12 }}>Process Scores</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 12 }}>
          <MiniScore label="Patience" value={data.patienceScore} />
          <MiniScore label="Emotions" value={data.emotionsScore} />
          <MiniScore label="Comms" value={data.communicationScore} />
        </div>
        <div style={{ textAlign: 'center' }}>
          <span style={{ color: '#888', fontSize: '0.78rem' }}>Process Average: </span>
          <span style={{ color: avgProcess >= 7 ? '#c8f135' : avgProcess >= 5 ? '#f5f5f5' : '#f97316', fontWeight: 800, fontSize: '0.9rem' }}>
            {avgProcess}/10
          </span>
        </div>
      </div>

      {data.wentWell && (
        <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px' }}>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>What Went Well</div>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.6, margin: 0 }}>{data.wentWell}</p>
        </div>
      )}

      {data.coachCue && (
        <div style={{ background: 'rgba(168,85,247,0.06)', border: '1px solid rgba(168,85,247,0.2)', borderRadius: 18, padding: '16px' }}>
          <div className="label-xs" style={{ color: '#a855f7', marginBottom: 8 }}>Coaching Cue</div>
          <p style={{ color: '#f5f5f5', fontSize: '0.9rem', margin: 0, lineHeight: 1.5 }}>
            {data.coachCue}
          </p>
        </div>
      )}

      <button
        onClick={onSave}
        className="press-scale"
        style={{
          width: '100%', background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          color: '#0a0a0a', border: 'none', borderRadius: 16,
          padding: '18px', fontWeight: 800, fontSize: '0.95rem', cursor: 'pointer',
        }}
      >
        Save Session
      </button>
    </div>
  );
}

function MiniScore({ label, value }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ color: value >= 7 ? '#c8f135' : '#f5f5f5', fontWeight: 800, fontSize: '1.1rem' }}>{value}</div>
      <div style={{ color: '#555', fontSize: '0.65rem', fontWeight: 600, marginTop: 2 }}>{label}</div>
    </div>
  );
}

// ─── Session Card & Detail ─────────────────────────────────────────────────────
function SessionCard({ session, onClick }) {
  const dateStr = session.date
    ? new Date(session.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    : '';

  return (
    <button
      onClick={onClick}
      className="press-scale"
      style={{
        background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18,
        padding: '16px', textAlign: 'left', cursor: 'pointer', width: '100%',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.875rem' }}>
            {session.gameType || 'Session'} · {session.skillFocus || 'General'}
          </div>
          <div style={{ color: '#555', fontSize: '0.75rem', marginTop: 2 }}>{dateStr}</div>
        </div>
        <div style={{ display: 'flex', gap: 3 }}>
          {[1, 2, 3, 4, 5].map(n => (
            <div key={n} style={{
              width: 7, height: 7, borderRadius: '50%',
              background: n <= (session.rating || 0) ? '#c8f135' : '#2a2a2a',
            }} />
          ))}
        </div>
      </div>
    </button>
  );
}

function SessionDetail({ session, onBack, onDelete }) {
  const dateStr = session.date
    ? new Date(session.date).toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })
    : '';

  return (
    <div style={{ paddingBottom: 100 }} className="animate-slide-up">
      <div style={{ padding: '16px 20px', background: '#0a0a0a', borderBottom: '1px solid #2a2a2a', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} className="press-scale" style={{
          background: '#1e1e1e', border: '1px solid #333', borderRadius: 12,
          padding: '8px 14px', display: 'flex', alignItems: 'center', gap: 6,
          color: '#a0a0a0', fontSize: '0.85rem', cursor: 'pointer',
        }}>
          <ChevronLeft size={16} /> Journal
        </button>
        <button onClick={() => onDelete(session.id)} className="press-scale" style={{
          background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
          borderRadius: 12, padding: '8px 14px', display: 'flex', alignItems: 'center', gap: 6,
          color: '#ef4444', fontSize: '0.8rem', cursor: 'pointer',
        }}>
          <Trash2 size={14} /> Delete
        </button>
      </div>

      <div style={{ padding: '24px 20px' }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 8 }}>{dateStr}</div>
        <h2 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.3rem', marginBottom: 20 }}>
          {session.gameType || 'Session'} · {session.skillFocus || 'General'}
        </h2>

        {session.rating > 0 && (
          <div style={{ display: 'flex', gap: 6, marginBottom: 20 }}>
            {[1, 2, 3, 4, 5].map(n => (
              <span key={n} style={{ fontSize: '1.25rem', color: n <= session.rating ? '#c8f135' : '#333' }}>
                {n <= session.rating ? '\u2605' : '\u2606'}
              </span>
            ))}
          </div>
        )}

        {[
          { label: 'What Went Well', value: session.wentWell, color: '#c8f135' },
          { label: 'Focus for Next Time', value: session.improveFocus, color: '#f97316' },
          { label: 'Insight', value: session.ahamoment, color: '#3b82f6' },
          { label: 'Coaching Cue', value: session.coachCue, color: '#a855f7' },
          { label: 'Highlight', value: session.highlights, color: '#22c55e' },
        ].filter(i => i.value).map(item => (
          <div key={item.label} style={{
            background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px', marginBottom: 12,
          }}>
            <div className="label-xs" style={{ color: item.color, marginBottom: 8 }}>{item.label}</div>
            <p style={{ color: '#c0c0c0', fontSize: '0.875rem', lineHeight: 1.7, margin: 0 }}>{item.value}</p>
          </div>
        ))}

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginTop: 8 }}>
          <ScoreBlock label="Patience" value={session.patienceScore} />
          <ScoreBlock label="Emotions" value={session.emotionsScore} />
          <ScoreBlock label="Communication" value={session.communicationScore} />
        </div>

        {session.patienceNotes && (
          <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 14, padding: '14px', marginTop: 12 }}>
            <div className="label-xs" style={{ color: '#555', marginBottom: 6 }}>Patience Notes</div>
            <p style={{ color: '#a0a0a0', fontSize: '0.8rem', lineHeight: 1.6, margin: 0 }}>{session.patienceNotes}</p>
          </div>
        )}
        {session.emotionsNotes && (
          <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 14, padding: '14px', marginTop: 12 }}>
            <div className="label-xs" style={{ color: '#555', marginBottom: 6 }}>Emotions Notes</div>
            <p style={{ color: '#a0a0a0', fontSize: '0.8rem', lineHeight: 1.6, margin: 0 }}>{session.emotionsNotes}</p>
          </div>
        )}
      </div>
    </div>
  );
}

function ScoreBlock({ label, value }) {
  return (
    <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 14, padding: '12px', textAlign: 'center' }}>
      <div style={{ color: '#c8f135', fontWeight: 800, fontSize: '1.3rem' }}>{value || '\u2014'}</div>
      <div className="label-xs" style={{ color: '#555', marginTop: 4 }}>{label}</div>
    </div>
  );
}

function JournalCTA({ icon, label, sub, accent, onClick }) {
  return (
    <button
      onClick={onClick}
      className="press-scale"
      style={{
        background: accent ? 'rgba(200,241,53,0.08)' : '#141414',
        border: accent ? '1.5px solid rgba(200,241,53,0.3)' : '1px solid #2a2a2a',
        borderRadius: 20, padding: '20px 16px', cursor: 'pointer', textAlign: 'center',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
      }}
    >
      <span style={{ fontSize: '0.85rem', fontWeight: 800, color: accent ? '#c8f135' : '#888', letterSpacing: '0.08em' }}>{icon}</span>
      <span style={{ color: accent ? '#c8f135' : '#f5f5f5', fontWeight: 700, fontSize: '0.9rem' }}>{label}</span>
      <span style={{ color: '#888', fontSize: '0.75rem' }}>{sub}</span>
    </button>
  );
}

function EmptyJournal({ onStartPre }) {
  return (
    <div style={{ textAlign: 'center', padding: '48px 20px' }}>
      <h3 style={{ color: '#f5f5f5', fontWeight: 700, marginBottom: 8 }}>No Sessions Yet</h3>
      <p style={{ color: '#888', fontSize: '0.875rem', lineHeight: 1.7, marginBottom: 24 }}>
        No sessions yet. Set your first intention to get started.
      </p>
      <button
        onClick={onStartPre}
        className="press-scale"
        style={{
          background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          color: '#0a0a0a', border: 'none', borderRadius: 14,
          padding: '14px 28px', fontWeight: 800, fontSize: '0.9rem', cursor: 'pointer',
        }}
      >
        Set First Intention
      </button>
    </div>
  );
}
