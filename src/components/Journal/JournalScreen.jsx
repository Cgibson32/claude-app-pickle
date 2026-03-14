import { useState } from 'react';
import { ChevronLeft, ChevronRight, Trash2 } from 'lucide-react';
import {
  MOOD_OPTIONS, GAME_TYPES, SKILL_FOCUS_OPTIONS,
  getTodayIntention, getRandomReflectionPrompt, getPostSessionAffirmation,
} from '../../data/intentionTemplates';
import { useAppActions } from '../../context/AppContext';

// ─── Main Screen ──────────────────────────────────────────────────────────────
export default function JournalScreen({ sessions, onSave, onDelete, initialMode }) {
  const { saveIntention } = useAppActions();
  const [view, setView] = useState(initialMode || 'list'); // list | pre | post | detail
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
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Reflection</div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', marginBottom: 8 }}>
          My Journal
        </h1>
        <p style={{ color: '#888', fontSize: '0.875rem', lineHeight: 1.6 }}>
          The players who reflect are the players who improve.
          {sessions.length > 0 && (
            <span style={{ color: '#c8f135' }}> {sessions.length} session{sessions.length !== 1 ? 's' : ''} reflected on so far.</span>
          )}
        </p>
      </div>

      {/* CTAs */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 28 }}>
        <JournalCTA
          icon="▶️"
          label="Before Play"
          sub="Set your mind right"
          accent
          onClick={() => setView('pre')}
        />
        <JournalCTA
          icon="📓"
          label="After Play"
          sub="Grow from your session"
          onClick={() => setView('post')}
        />
      </div>

      {/* Last coaching cue reminder */}
      {recentSession?.coachCue && (
        <div style={{
          background: 'rgba(168,85,247,0.06)', border: '1px solid rgba(168,85,247,0.2)',
          borderRadius: 18, padding: '16px', marginBottom: 20,
        }}>
          <div className="label-xs" style={{ color: '#a855f7', marginBottom: 8 }}>Your Last Coaching Cue</div>
          <p style={{ color: '#f5f5f5', fontSize: '0.875rem', fontStyle: 'italic', margin: 0, lineHeight: 1.6 }}>
            &ldquo;{recentSession.coachCue}&rdquo;
          </p>
          <p style={{ color: '#555', fontSize: '0.75rem', margin: '8px 0 0' }}>
            Keep this in mind before your next session
          </p>
        </div>
      )}

      {/* Sessions list */}
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
    { title: "How are you\nfeeling?", subtitle: "Check in with yourself before you step on court.", component: <MoodStep data={data} setData={setData} /> },
    { title: "Your intention\nfor today", subtitle: `Today's theme: ${todayTheme.theme}`, component: <IntentionStep data={data} setData={setData} todayTheme={todayTheme} /> },
    { title: "You're\nready.", subtitle: null, component: <PreReadyStep data={data} todayTheme={todayTheme} onConfirm={() => onDone(data)} /> },
  ];

  const current = steps[step];

  return (
    <div style={{ minHeight: '100vh', background: '#0a0a0a', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{ padding: '20px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', color: '#666', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.875rem' }}>
          <ChevronLeft size={16} /> Back
        </button>
        <div className="label-xs" style={{ color: '#c8f135' }}>Before Play</div>
        <div style={{ width: 60 }} />
      </div>

      {/* Progress */}
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
  const selectedMood = MOOD_OPTIONS.find(m => m.id === data.mood);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
        {MOOD_OPTIONS.map(m => (
          <button
            key={m.id}
            onClick={() => setData(d => ({ ...d, mood: m.id }))}
            className="press-scale"
            style={{
              background: data.mood === m.id ? 'rgba(200,241,53,0.1)' : '#141414',
              border: data.mood === m.id ? '1.5px solid rgba(200,241,53,0.4)' : '1px solid #2a2a2a',
              borderRadius: 16, padding: '16px 8px', cursor: 'pointer', textAlign: 'center',
            }}
          >
            <div style={{ fontSize: '1.75rem', marginBottom: 6 }}>{m.emoji}</div>
            <div style={{ color: data.mood === m.id ? '#c8f135' : '#a0a0a0', fontSize: '0.75rem', fontWeight: 600 }}>
              {m.label}
            </div>
          </button>
        ))}
      </div>

      {/* Mood-specific encouragement */}
      {selectedMood && (
        <div style={{
          background: 'rgba(200,241,53,0.06)', border: '1px solid rgba(200,241,53,0.15)',
          borderRadius: 16, padding: '14px 16px', textAlign: 'center',
        }}>
          <p style={{ color: '#c8f135', fontSize: '0.85rem', fontWeight: 600, margin: 0, lineHeight: 1.5 }}>
            {selectedMood.message}
          </p>
        </div>
      )}

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
        {data.energyLevel <= 3 && (
          <p style={{ color: '#888', fontSize: '0.78rem', marginTop: 10, fontStyle: 'italic', textAlign: 'center' }}>
            Low energy days are growth days. Simplify your game plan and focus on consistency.
          </p>
        )}
      </div>
    </div>
  );
}

function IntentionStep({ data, setData, todayTheme }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {/* Today's theme card */}
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
            <div style={{ color: '#c8f135', fontWeight: 700, fontSize: '0.9rem' }}>Today&apos;s Theme: {todayTheme.theme}</div>
            <div style={{ color: '#888', fontSize: '0.78rem' }}>{todayTheme.mental}</div>
          </div>
        </div>
        <p style={{ color: '#a0a0a0', fontSize: '0.85rem', fontStyle: 'italic', margin: 0, lineHeight: 1.5 }}>
          &ldquo;{todayTheme.quote}&rdquo;
        </p>
      </div>

      {/* Game type */}
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
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 4 }}>Technical Focus</div>
        <p style={{ color: '#555', fontSize: '0.75rem', margin: '0 0 10px' }}>What specific skill will you be intentional about?</p>
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
        <div className="label-xs" style={{ color: '#60a5fa', marginBottom: 4 }}>Mental Intention</div>
        <p style={{ color: '#555', fontSize: '0.75rem', margin: '0 0 10px' }}>How will you manage your mind and emotions today?</p>
        <textarea
          value={data.mentalIntent}
          onChange={e => setData(d => ({ ...d, mentalIntent: e.target.value }))}
          placeholder="e.g., Stay calm after errors. One point at a time. Breathe between rallies..."
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

      <div style={{ background: '#141414', border: '1px solid rgba(200,241,53,0.2)', borderRadius: 18, padding: '24px', textAlign: 'center' }}>
        <div style={{ fontSize: '2.5rem', marginBottom: 12 }}>🏓</div>
        <p style={{ color: '#c8f135', fontWeight: 700, fontSize: '1rem', margin: '0 0 8px' }}>
          Play with intention. Play with joy.
        </p>
        <p style={{ color: '#a0a0a0', fontSize: '0.85rem', fontStyle: 'italic', margin: '0 0 12px', lineHeight: 1.5 }}>
          &ldquo;{todayTheme.affirmation || todayTheme.quote}&rdquo;
        </p>
        <p style={{ color: '#555', fontSize: '0.78rem', margin: 0 }}>
          Come back after to reflect and lock in your growth.
        </p>
      </div>

      <button
        onClick={onConfirm}
        className="press-scale"
        style={{
          width: '100%', background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          color: '#0a0a0a', border: 'none', borderRadius: 16,
          padding: '16px', fontWeight: 800, fontSize: '0.95rem', cursor: 'pointer',
        }}
      >
        I&apos;m Ready to Play
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
    { title: 'How was\nyour session?', subtitle: 'Be honest — honest reflection drives real growth.', component: <RatingStep data={data} setData={setData} /> },
    { title: 'What went\nwell?', subtitle: 'Celebrating wins — even small ones — rewires your confidence.', component: <WentWellStep data={data} setData={setData} /> },
    { title: 'The process\nscorecard', subtitle: 'These are the metrics that actually predict improvement.', component: <ProcessReviewStep data={data} setData={setData} /> },
    { title: 'Growth\nmoments', subtitle: 'The moments that shape who you become as a player.', component: <GrowthStep data={data} setData={setData} /> },
    { title: 'Session\ncomplete.', subtitle: null, component: <PostSummaryStep data={data} sessionCount={sessionCount} onSave={() => onSave(data)} /> },
  ];

  const current = steps[step];
  const isLast = step === steps.length - 1;

  return (
    <div style={{ minHeight: '100vh', background: '#0a0a0a', display: 'flex', flexDirection: 'column' }}>
      <div style={{ padding: '20px 20px 0', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <button onClick={onBack} style={{ background: 'none', border: 'none', color: '#666', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.875rem' }}>
          <ChevronLeft size={16} /> Back
        </button>
        <div className="label-xs" style={{ color: '#c8f135' }}>Post-Play Reflection</div>
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
  const ratingMessages = {
    0: 'Tap to rate your session',
    1: "Tough one. But showing up on hard days is what separates players who grow from those who don't.",
    2: 'A learning day. The awareness to rate it honestly already shows growth.',
    3: 'Solid session. There were good moments in there — hold onto them.',
    4: "Strong session! You're building something. That work is showing.",
    5: "Outstanding! Days like this are built on the hard days that came before.",
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '20px', textAlign: 'center' }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 16 }}>Overall Session Rating</div>
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
                transition: 'all 0.2s',
              }}
            >
              {n <= data.rating ? '⭐' : '☆'}
            </button>
          ))}
        </div>
        <p style={{
          color: data.rating > 0 ? '#c8f135' : '#555',
          fontWeight: 600, fontSize: '0.85rem', margin: 0, lineHeight: 1.5,
        }}>
          {ratingMessages[data.rating]}
        </p>
      </div>

      <div>
        <div className="label-xs" style={{ color: '#555', marginBottom: 4 }}>Skill Focus Today</div>
        <p style={{ color: '#666', fontSize: '0.75rem', margin: '0 0 10px' }}>What did you work on most?</p>
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
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 4 }}>What went well today?</div>
        <p style={{ color: '#555', fontSize: '0.75rem', margin: '0 0 10px' }}>
          Naming your wins — technical, mental, or emotional — builds real confidence.
        </p>
        <textarea
          value={data.wentWell}
          onChange={e => setData(d => ({ ...d, wentWell: e.target.value }))}
          placeholder={getRandomReflectionPrompt('wentWell')}
          rows={4}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>

      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#f97316', marginBottom: 4 }}>One focus for next time</div>
        <p style={{ color: '#555', fontSize: '0.75rem', margin: '0 0 10px' }}>
          Just one thing. The most impactful growth comes from focused attention.
        </p>
        <textarea
          value={data.improveFocus}
          onChange={e => setData(d => ({ ...d, improveFocus: e.target.value }))}
          placeholder={getRandomReflectionPrompt('improve')}
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
  const getScoreLabel = (score) => {
    if (score >= 9) return 'Elite-level';
    if (score >= 7) return 'Strong';
    if (score >= 5) return 'Building';
    if (score >= 3) return 'Work in progress';
    return 'Growth opportunity';
  };

  const metrics = [
    {
      key: 'patienceScore', label: 'Patience', emoji: '⏳', notes: 'patienceNotes',
      description: 'Did you wait for the right ball? Did you build points instead of forcing?',
      notesPlaceholder: 'Where did patience break down? Where did it show up?',
    },
    {
      key: 'emotionsScore', label: 'Emotional Control', emoji: '🌊', notes: 'emotionsNotes',
      description: 'Did you manage frustration? Did emotions affect your shot selection?',
      notesPlaceholder: 'How did emotions affect your play today?',
    },
    {
      key: 'communicationScore', label: 'Communication', emoji: '🤝', notes: null,
      description: 'Did you call balls, encourage your partner, and stay connected?',
    },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {metrics.map(m => (
        <div key={m.key} style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ color: '#a0a0a0', fontWeight: 600, fontSize: '0.9rem' }}>{m.emoji} {m.label}</span>
            <span style={{ color: '#c8f135', fontWeight: 800, fontSize: '1.1rem' }}>{data[m.key]}/10</span>
          </div>
          <p style={{ color: '#555', fontSize: '0.72rem', margin: '0 0 10px', lineHeight: 1.4 }}>
            {m.description}
          </p>
          <input
            type="range" min="1" max="10" value={data[m.key]}
            onChange={e => setData(d => ({ ...d, [m.key]: +e.target.value }))}
          />
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
            <span style={{ color: '#444', fontSize: '0.65rem' }}>Needs work</span>
            <span style={{ color: data[m.key] >= 7 ? '#c8f135' : '#666', fontSize: '0.72rem', fontWeight: 600 }}>
              {getScoreLabel(data[m.key])}
            </span>
          </div>
          {m.notes && (
            <textarea
              value={data[m.notes]}
              onChange={e => setData(d => ({ ...d, [m.notes]: e.target.value }))}
              placeholder={m.notesPlaceholder}
              rows={2}
              style={{
                width: '100%', background: '#1e1e1e', border: '1px solid #333',
                borderRadius: 10, padding: '10px 12px', color: '#f5f5f5', fontSize: '0.8rem',
                lineHeight: 1.6, resize: 'none', outline: 'none', marginTop: 12,
              }}
            />
          )}
        </div>
      ))}
    </div>
  );
}

function GrowthStep({ data, setData }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 4 }}>Highlight moment</div>
        <p style={{ color: '#555', fontSize: '0.75rem', margin: '0 0 10px' }}>
          Remembering your best moments trains your brain to repeat them.
        </p>
        <textarea
          value={data.highlights}
          onChange={e => setData(d => ({ ...d, highlights: e.target.value }))}
          placeholder={getRandomReflectionPrompt('highlight')}
          rows={3}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#3b82f6', marginBottom: 4 }}>A-ha moment or insight</div>
        <p style={{ color: '#555', fontSize: '0.75rem', margin: '0 0 10px' }}>
          Breakthroughs often happen in small moments. Capture them before they fade.
        </p>
        <textarea
          value={data.ahamoment}
          onChange={e => setData(d => ({ ...d, ahamoment: e.target.value }))}
          placeholder={getRandomReflectionPrompt('aha')}
          rows={3}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#a855f7', marginBottom: 4 }}>One coaching cue for next time</div>
        <p style={{ color: '#555', fontSize: '0.75rem', margin: '0 0 10px' }}>
          Your future self will see this before the next session. Make it count.
        </p>
        <textarea
          value={data.coachCue}
          onChange={e => setData(d => ({ ...d, coachCue: e.target.value }))}
          placeholder="The one thing to remember before your next game..."
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

function PostSummaryStep({ data, sessionCount, onSave }) {
  const affirmation = getPostSessionAffirmation();
  const newTotal = sessionCount + 1;
  const isMilestone = [5, 10, 15, 25, 50, 75, 100].includes(newTotal);
  const avgProcess = Math.round(((data.patienceScore || 5) + (data.emotionsScore || 5) + (data.communicationScore || 5)) / 3 * 10) / 10;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {/* Celebration header */}
      <div style={{
        background: isMilestone
          ? 'linear-gradient(135deg, rgba(200,241,53,0.12), rgba(168,85,247,0.08))'
          : 'rgba(200,241,53,0.06)',
        border: isMilestone
          ? '1px solid rgba(200,241,53,0.4)'
          : '1px solid rgba(200,241,53,0.2)',
        borderRadius: 20, padding: '24px', textAlign: 'center',
      }}>
        <div style={{ fontSize: '2.5rem', marginBottom: 12 }}>{isMilestone ? '🎉' : '✅'}</div>
        <h3 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.1rem', marginBottom: 8 }}>
          {isMilestone
            ? `Session #${newTotal}! Milestone Reached!`
            : 'Session Reflected.'}
        </h3>
        <p style={{ color: '#a0a0a0', fontSize: '0.85rem', lineHeight: 1.6, margin: 0 }}>
          {affirmation}
        </p>
      </div>

      {/* Process score summary */}
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px' }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 12 }}>Process Scorecard</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 12 }}>
          <MiniScore label="Patience" value={data.patienceScore} emoji="⏳" />
          <MiniScore label="Emotions" value={data.emotionsScore} emoji="🌊" />
          <MiniScore label="Comms" value={data.communicationScore} emoji="🤝" />
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
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>What went well</div>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.6, margin: 0 }}>{data.wentWell}</p>
        </div>
      )}

      {data.coachCue && (
        <div style={{ background: 'rgba(168,85,247,0.06)', border: '1px solid rgba(168,85,247,0.2)', borderRadius: 18, padding: '16px' }}>
          <div className="label-xs" style={{ color: '#a855f7', marginBottom: 8 }}>Remember next time</div>
          <p style={{ color: '#f5f5f5', fontSize: '0.9rem', fontStyle: 'italic', margin: 0, lineHeight: 1.5 }}>
            &ldquo;{data.coachCue}&rdquo;
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
        Save My Session
      </button>
    </div>
  );
}

function MiniScore({ label, value, emoji }) {
  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ fontSize: '0.9rem', marginBottom: 4 }}>{emoji}</div>
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
  const moodEmoji = MOOD_OPTIONS.find(m => m.id === session.mood)?.emoji || '🏓';
  const avgProcess = session.patienceScore && session.emotionsScore && session.communicationScore
    ? Math.round(((session.patienceScore || 0) + (session.emotionsScore || 0) + (session.communicationScore || 0)) / 3 * 10) / 10
    : null;

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
        <span style={{ fontSize: '1.5rem' }}>{moodEmoji}</span>
        <div style={{ flex: 1 }}>
          <div style={{ color: '#f5f5f5', fontWeight: 600, fontSize: '0.875rem' }}>
            {session.gameType || 'Session'} · {session.skillFocus || 'General'}
          </div>
          <div style={{ color: '#555', fontSize: '0.75rem', marginTop: 2 }}>{dateStr}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {avgProcess && (
            <span style={{ color: avgProcess >= 7 ? '#c8f135' : '#888', fontSize: '0.75rem', fontWeight: 700 }}>
              {avgProcess}
            </span>
          )}
          <div style={{ display: 'flex', gap: 3 }}>
            {[1, 2, 3, 4, 5].map(n => (
              <div key={n} style={{
                width: 7, height: 7, borderRadius: '50%',
                background: n <= (session.rating || 0) ? '#c8f135' : '#2a2a2a',
              }} />
            ))}
          </div>
        </div>
      </div>
      {session.wentWell && (
        <p style={{ color: '#666', fontSize: '0.78rem', lineHeight: 1.5, margin: '10px 0 0', paddingLeft: 40 }}>
          {session.wentWell.slice(0, 70)}{session.wentWell.length > 70 ? '...' : ''}
        </p>
      )}
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
            {[1,2,3,4,5].map(n => (
              <span key={n} style={{ fontSize: '1.25rem' }}>{n <= session.rating ? '⭐' : '☆'}</span>
            ))}
          </div>
        )}

        {[
          { label: 'What went well', value: session.wentWell, color: '#c8f135' },
          { label: 'Focus for next time', value: session.improveFocus, color: '#f97316' },
          { label: 'A-ha moment', value: session.ahamoment, color: '#3b82f6' },
          { label: 'Coaching cue', value: session.coachCue, color: '#a855f7' },
          { label: 'Highlight moment', value: session.highlights, color: '#22c55e' },
        ].filter(i => i.value).map(item => (
          <div key={item.label} style={{
            background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px', marginBottom: 12,
          }}>
            <div className="label-xs" style={{ color: item.color, marginBottom: 8 }}>{item.label}</div>
            <p style={{ color: '#c0c0c0', fontSize: '0.875rem', lineHeight: 1.7, margin: 0 }}>{item.value}</p>
          </div>
        ))}

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginTop: 8 }}>
          <ScoreBlock label="Patience" value={session.patienceScore} emoji="⏳" />
          <ScoreBlock label="Emotions" value={session.emotionsScore} emoji="🌊" />
          <ScoreBlock label="Communication" value={session.communicationScore} emoji="🤝" />
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

function ScoreBlock({ label, value, emoji }) {
  return (
    <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 14, padding: '12px', textAlign: 'center' }}>
      <div style={{ fontSize: '0.85rem', marginBottom: 4 }}>{emoji}</div>
      <div style={{ color: '#c8f135', fontWeight: 800, fontSize: '1.3rem' }}>{value || '—'}</div>
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
      <span style={{ fontSize: '1.75rem' }}>{icon}</span>
      <span style={{ color: accent ? '#c8f135' : '#f5f5f5', fontWeight: 700, fontSize: '0.9rem' }}>{label}</span>
      <span style={{ color: '#888', fontSize: '0.75rem' }}>{sub}</span>
    </button>
  );
}

function EmptyJournal({ onStartPre }) {
  return (
    <div style={{ textAlign: 'center', padding: '48px 20px' }}>
      <div style={{ fontSize: '3rem', marginBottom: 16 }}>📓</div>
      <h3 style={{ color: '#f5f5f5', fontWeight: 700, marginBottom: 8 }}>Your Story Starts Here</h3>
      <p style={{ color: '#888', fontSize: '0.875rem', lineHeight: 1.7, marginBottom: 12 }}>
        Every champion has a journal. The habit of reflection turns ordinary sessions into extraordinary growth.
      </p>
      <p style={{ color: '#555', fontSize: '0.8rem', lineHeight: 1.6, marginBottom: 24, fontStyle: 'italic' }}>
        &ldquo;The players who reflect improve 3x faster than those who just play.&rdquo;
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
        Set My First Intention
      </button>
    </div>
  );
}
