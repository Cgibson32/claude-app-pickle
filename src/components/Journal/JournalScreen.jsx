import { useState } from 'react';
import { ChevronLeft, ChevronRight, Check, Trash2, Star, X } from 'lucide-react';
import { MOOD_OPTIONS, GAME_TYPES, SKILL_FOCUS_OPTIONS } from '../../data/intentionTemplates';

// ─── Main Screen ──────────────────────────────────────────────────────────────
export default function JournalScreen({ sessions, onSave, onDelete, initialMode }) {
  const [view, setView] = useState(initialMode || 'list'); // list | pre | post | detail
  const [selectedSession, setSelectedSession] = useState(null);
  const [prePlayData, setPrePlayData] = useState(null);

  if (view === 'pre') {
    return <PrePlayFlow onDone={(data) => { setPrePlayData(data); setView('list'); }} onBack={() => setView('list')} />;
  }
  if (view === 'post') {
    return <PostPlayFlow prePlayData={prePlayData} onSave={(s) => { onSave(s); setView('list'); }} onBack={() => setView('list')} />;
  }
  if (view === 'detail' && selectedSession) {
    return <SessionDetail session={selectedSession} onBack={() => { setSelectedSession(null); setView('list'); }} onDelete={(id) => { onDelete(id); setSelectedSession(null); setView('list'); }} />;
  }

  return (
    <div style={{ padding: '20px 20px 100px' }} className="animate-fade-in">
      <div style={{ marginBottom: 24 }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Reflection</div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', marginBottom: 8 }}>
          My Journal
        </h1>
        <p style={{ color: '#666', fontSize: '0.875rem' }}>
          Reflect, learn, and grow from every session
        </p>
      </div>

      {/* CTAs */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 28 }}>
        <JournalCTA
          icon="▶️"
          label="Before Play"
          sub="Set your intention"
          accent
          onClick={() => setView('pre')}
        />
        <JournalCTA
          icon="📓"
          label="After Play"
          sub="Log your session"
          onClick={() => setView('post')}
        />
      </div>

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

  const steps = [
    { title: "How are you\nfeeling?", component: <MoodStep data={data} setData={setData} /> },
    { title: "Your intention\nfor today", component: <IntentionStep data={data} setData={setData} /> },
    { title: "Ready to\nplay.", component: <PreReadyStep data={data} onConfirm={() => onDone(data)} /> },
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
        <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2, marginBottom: 28, whiteSpace: 'pre-line' }}>
          {current.title}
        </h2>
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

function IntentionStep({ data, setData }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
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
        <div className="label-xs" style={{ color: '#555', marginBottom: 10 }}>Technical Focus</div>
        <textarea
          value={data.technicalIntent}
          onChange={e => setData(d => ({ ...d, technicalIntent: e.target.value }))}
          placeholder="e.g., Keep my third shot drops low and be patient before attacking..."
          rows={2}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.6, resize: 'none', outline: 'none',
          }}
        />
      </div>

      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 10 }}>Mental Intention</div>
        <textarea
          value={data.mentalIntent}
          onChange={e => setData(d => ({ ...d, mentalIntent: e.target.value }))}
          placeholder="e.g., Stay calm after errors. One point at a time..."
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

function PreReadyStep({ data, onConfirm }) {
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
      <div style={{ background: '#141414', border: '1px solid rgba(200,241,53,0.2)', borderRadius: 18, padding: '20px', textAlign: 'center' }}>
        <div style={{ fontSize: '2.5rem', marginBottom: 12 }}>🏓</div>
        <p style={{ color: '#c8f135', fontWeight: 700, fontSize: '1rem', margin: '0 0 8px' }}>
          Play with intention. Play with joy.
        </p>
        <p style={{ color: '#555', fontSize: '0.8rem', margin: 0 }}>
          Come back after to reflect on your session.
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
        I&apos;m Ready to Play 🏓
      </button>
    </div>
  );
}

// ─── Post-Play Flow ────────────────────────────────────────────────────────────
function PostPlayFlow({ prePlayData, onSave, onBack }) {
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
    { title: 'How was\nyour session?', component: <RatingStep data={data} setData={setData} /> },
    { title: 'What went\nwell?', component: <WentWellStep data={data} setData={setData} /> },
    { title: 'Process\nreview', component: <ProcessReviewStep data={data} setData={setData} /> },
    { title: 'Growth\nmoments', component: <GrowthStep data={data} setData={setData} /> },
    { title: 'Great\nwork.', component: <PostSummaryStep data={data} onSave={() => onSave(data)} /> },
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
        <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2, marginBottom: 24, whiteSpace: 'pre-line' }}>
          {current.title}
        </h2>
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
                width: 44, height: 44, borderRadius: '50%', cursor: 'pointer',
                background: n <= data.rating ? 'rgba(200,241,53,0.15)' : '#1e1e1e',
                border: n <= data.rating ? '1.5px solid rgba(200,241,53,0.5)' : '1px solid #333',
                fontSize: '1.25rem', display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}
            >
              {n <= data.rating ? '⭐' : '☆'}
            </button>
          ))}
        </div>
        <p style={{ color: data.rating > 0 ? '#c8f135' : '#555', fontWeight: 600, fontSize: '0.875rem', margin: 0 }}>
          {data.rating === 0 ? 'Tap to rate' : data.rating === 5 ? 'Outstanding session! 🔥' : data.rating >= 4 ? 'Strong session!' : data.rating >= 3 ? 'Good session.' : data.rating >= 2 ? 'Learning day.' : 'Tough one — what can we learn?'}
        </p>
      </div>

      <div>
        <div className="label-xs" style={{ color: '#555', marginBottom: 10 }}>Skill Focus Today</div>
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
        <div className="label-xs" style={{ color: '#555', marginBottom: 10 }}>What went well today?</div>
        <textarea
          value={data.wentWell}
          onChange={e => setData(d => ({ ...d, wentWell: e.target.value }))}
          placeholder="Moments of patience, great shots, good communication, mental toughness..."
          rows={4}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>

      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 10 }}>Main focus for next time?</div>
        <textarea
          value={data.improveFocus}
          onChange={e => setData(d => ({ ...d, improveFocus: e.target.value }))}
          placeholder="What specific skill or habit needs more attention?"
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
    { key: 'patienceScore', label: 'Patience', emoji: '⏳', notes: 'patienceNotes', notesPlaceholder: 'Where did patience break down? Where did it show up?' },
    { key: 'emotionsScore', label: 'Emotional Control', emoji: '🌊', notes: 'emotionsNotes', notesPlaceholder: 'How did emotions affect your play?' },
    { key: 'communicationScore', label: 'Communication', emoji: '🤝', notes: null },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {metrics.map(m => (
        <div key={m.key} style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <span style={{ color: '#a0a0a0', fontWeight: 600, fontSize: '0.9rem' }}>{m.emoji} {m.label}</span>
            <span style={{ color: '#c8f135', fontWeight: 800, fontSize: '1.1rem' }}>{data[m.key]}/10</span>
          </div>
          <input
            type="range" min="1" max="10" value={data[m.key]}
            onChange={e => setData(d => ({ ...d, [m.key]: +e.target.value }))}
          />
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
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 10 }}>Highlight moment</div>
        <textarea
          value={data.highlights}
          onChange={e => setData(d => ({ ...d, highlights: e.target.value }))}
          placeholder="The shot, rally, or moment you're most proud of today..."
          rows={3}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#3b82f6', marginBottom: 10 }}>A-ha moment or insight</div>
        <textarea
          value={data.ahamoment}
          onChange={e => setData(d => ({ ...d, ahamoment: e.target.value }))}
          placeholder="Any realization, lesson, or new understanding that clicked today..."
          rows={3}
          style={{
            width: '100%', background: '#1e1e1e', border: '1px solid #333',
            borderRadius: 12, padding: '12px', color: '#f5f5f5', fontSize: '0.875rem',
            lineHeight: 1.7, resize: 'none', outline: 'none',
          }}
        />
      </div>
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '18px' }}>
        <div className="label-xs" style={{ color: '#a855f7', marginBottom: 10 }}>One coaching cue for next time</div>
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

function PostSummaryStep({ data, onSave }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <div style={{
        background: 'rgba(200,241,53,0.06)', border: '1px solid rgba(200,241,53,0.2)',
        borderRadius: 20, padding: '24px', textAlign: 'center',
      }}>
        <div style={{ fontSize: '2.5rem', marginBottom: 12 }}>✅</div>
        <h3 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.1rem', marginBottom: 8 }}>
          Session Reflected.
        </h3>
        <p style={{ color: '#666', fontSize: '0.85rem', lineHeight: 1.6, margin: 0 }}>
          Every reflection is a step forward. The players who grow fastest are the ones who review honestly.
        </p>
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
          <p style={{ color: '#f5f5f5', fontSize: '0.9rem', fontStyle: 'italic', margin: 0 }}>"{data.coachCue}"</p>
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
        Save My Session ✓
      </button>
    </div>
  );
}

// ─── Session Card & Detail ─────────────────────────────────────────────────────
function SessionCard({ session, onClick }) {
  const dateStr = session.date
    ? new Date(session.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    : '';
  const moodEmoji = MOOD_OPTIONS.find(m => m.id === session.mood)?.emoji || '🏓';

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
        <div style={{ display: 'flex', gap: 3 }}>
          {[1, 2, 3, 4, 5].map(n => (
            <div key={n} style={{
              width: 7, height: 7, borderRadius: '50%',
              background: n <= (session.rating || 0) ? '#c8f135' : '#2a2a2a',
            }} />
          ))}
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
          <ScoreBlock label="Patience" value={session.patienceScore} />
          <ScoreBlock label="Emotions" value={session.emotionsScore} />
          <ScoreBlock label="Communication" value={session.communicationScore} />
        </div>
      </div>
    </div>
  );
}

function ScoreBlock({ label, value }) {
  return (
    <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 14, padding: '12px', textAlign: 'center' }}>
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
      <span style={{ color: '#555', fontSize: '0.75rem' }}>{sub}</span>
    </button>
  );
}

function EmptyJournal({ onStartPre }) {
  return (
    <div style={{ textAlign: 'center', padding: '60px 20px' }}>
      <div style={{ fontSize: '3rem', marginBottom: 16 }}>📓</div>
      <h3 style={{ color: '#f5f5f5', fontWeight: 700, marginBottom: 8 }}>Your journal is empty</h3>
      <p style={{ color: '#555', fontSize: '0.875rem', lineHeight: 1.6, marginBottom: 24 }}>
        Start by setting your intention before your next match. The habit of reflection is where growth begins.
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
        Set Pre-Play Intention
      </button>
    </div>
  );
}
