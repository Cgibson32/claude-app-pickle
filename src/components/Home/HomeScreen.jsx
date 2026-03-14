import { ChevronRight, Flame, BookOpen, Target, Play } from 'lucide-react';
import { getTodayIntention } from '../../data/intentionTemplates';

const MOTIVATIONAL_QUOTES = [
  { quote: "Play free today.", sub: "Freedom comes from trust in your preparation." },
  { quote: "Patience creates opportunity.", sub: "Every rally is a chance to build." },
  { quote: "Compete hard. Stay loose.", sub: "These two are not opposites." },
  { quote: "Growth compounds.", sub: "Every session is a deposit." },
  { quote: "Play with intention. Play with joy.", sub: "The best players do both." },
  { quote: "Enjoy the rally.", sub: "The lesson is inside it." },
  { quote: "Your mindset is your paddle.", sub: "Sharpen both." },
  { quote: "One ball at a time.", sub: "The rest will take care of itself." },
];

export default function HomeScreen({ profile, sessions, onNavigate }) {
  const today = getTodayIntention();
  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  const greetingEmoji = hour < 12 ? '☀️' : hour < 17 ? '🎯' : '🌙';

  const quoteIndex = new Date().getDay();
  const todayQuote = MOTIVATIONAL_QUOTES[quoteIndex % MOTIVATIONAL_QUOTES.length];

  // Streak calculation
  const streak = calcStreak(sessions);

  const firstName = profile?.name?.split(' ')[0] || 'Player';

  return (
    <div className="animate-fade-in" style={{ paddingBottom: 100 }}>
      {/* Header */}
      <div style={{ padding: '20px 20px 0' }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 20 }}>
          <div>
            <p style={{ color: '#666', fontSize: '0.8rem', marginBottom: 4 }}>
              {greetingEmoji} {greeting}
            </p>
            <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em' }}>
              {firstName}<span style={{ color: '#c8f135' }}>.</span>
            </h1>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            {streak > 0 && (
              <div style={{
                background: 'rgba(249,115,22,0.12)', border: '1px solid rgba(249,115,22,0.3)',
                borderRadius: 20, padding: '6px 12px', display: 'flex', alignItems: 'center', gap: 6,
              }}>
                <Flame size={14} color="#f97316" />
                <span style={{ color: '#f97316', fontWeight: 700, fontSize: '0.8rem' }}>{streak}</span>
              </div>
            )}
          </div>
        </div>

        {/* Today's Intention Card */}
        <div style={{
          background: 'linear-gradient(135deg, #141414 0%, #1a1a0e 100%)',
          border: '1px solid rgba(200,241,53,0.25)',
          borderRadius: 24, padding: '22px 20px', marginBottom: 16,
          position: 'relative', overflow: 'hidden',
        }}>
          {/* Glow */}
          <div style={{
            position: 'absolute', top: -40, right: -40, width: 200, height: 200,
            borderRadius: '50%', background: 'rgba(200,241,53,0.06)',
            pointerEvents: 'none',
          }} />

          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
            <div style={{
              background: 'rgba(200,241,53,0.15)', borderRadius: 8,
              width: 28, height: 28, display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Target size={14} color="#c8f135" />
            </div>
            <span className="label-xs" style={{ color: '#c8f135' }}>Today&apos;s Intention</span>
            <span style={{
              marginLeft: 'auto', background: 'rgba(200,241,53,0.1)',
              border: '1px solid rgba(200,241,53,0.2)', color: '#c8f135',
              borderRadius: 20, padding: '2px 10px', fontSize: '0.65rem', fontWeight: 700,
            }}>
              {today.theme}
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <IntentionRow icon="⚡" label="Performance" value={today.performance} />
            <IntentionRow icon="🧠" label="Mental Cue" value={today.mental} />
            <IntentionRow icon="😄" label="Joy Intention" value={today.joy} />
          </div>

          <div style={{
            marginTop: 16, paddingTop: 16, borderTop: '1px solid #2a2a2a',
          }}>
            <p style={{ color: '#c8f135', fontSize: '0.9rem', fontStyle: 'italic', fontWeight: 600, margin: 0 }}>
              "{today.quote}"
            </p>
            <p style={{ color: '#555', fontSize: '0.75rem', marginTop: 4, margin: '4px 0 0' }}>{today.cue}</p>
          </div>
        </div>

        {/* Before/After Play CTAs */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 20 }}>
          <ActionButton
            icon={<Play size={16} color="#c8f135" />}
            label="Before Play"
            sub="Set your intention"
            accent
            onClick={() => onNavigate('journal', { mode: 'pre' })}
          />
          <ActionButton
            icon={<BookOpen size={16} color="#a0a0a0" />}
            label="After Play"
            sub="Reflect & grow"
            onClick={() => onNavigate('journal', { mode: 'post' })}
          />
        </div>
      </div>

      {/* Inspirational Quote */}
      <div style={{ padding: '0 20px', marginBottom: 20 }}>
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 20, padding: '18px 20px',
        }}>
          <p style={{ color: '#f5f5f5', fontSize: '1.1rem', fontWeight: 700, margin: 0, lineHeight: 1.4 }}>
            "{todayQuote.quote}"
          </p>
          <p style={{ color: '#555', fontSize: '0.8rem', margin: '8px 0 0' }}>{todayQuote.sub}</p>
        </div>
      </div>

      {/* Quick Access */}
      <SectionHeader title="Explore" style={{ padding: '0 20px', marginBottom: 12 }} />
      <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 24 }}>
        <QuickCard
          icon="🎯"
          title="Skill Library"
          sub="9 skill categories · Drills & coaching"
          color="#c8f135"
          onClick={() => onNavigate('skills')}
        />
        <QuickCard
          icon="🧠"
          title="Mental Game"
          sub="9 mental pillars · Mindset training"
          color="#3b82f6"
          onClick={() => onNavigate('mental')}
        />
        <QuickCard
          icon="🤖"
          title="AI Coach"
          sub="Personalized insights just for you"
          color="#a855f7"
          onClick={() => onNavigate('coach')}
        />
      </div>

      {/* Stats Row */}
      {sessions.length > 0 && (
        <>
          <SectionHeader title="Your Progress" onAction={() => onNavigate('progress')} actionLabel="See all" style={{ padding: '0 20px', marginBottom: 12 }} />
          <div style={{ padding: '0 20px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 24 }}>
            <MiniStat label="Sessions" value={sessions.length} icon="📓" />
            <MiniStat label="Streak" value={`${streak}🔥`} icon="⚡" />
            <MiniStat label="Avg Rating" value={getAvgRating(sessions)} icon="⭐" />
          </div>
        </>
      )}

      {/* Recent sessions */}
      {sessions.length > 0 && (
        <>
          <SectionHeader title="Recent Sessions" onAction={() => onNavigate('journal')} actionLabel="All" style={{ padding: '0 20px', marginBottom: 12 }} />
          <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 10 }}>
            {sessions.slice(0, 2).map(s => (
              <RecentSession key={s.id} session={s} />
            ))}
          </div>
        </>
      )}

      {/* Empty state */}
      {sessions.length === 0 && (
        <div style={{ padding: '0 20px' }}>
          <div style={{
            background: '#141414', border: '1px solid #2a2a2a', borderRadius: 24,
            padding: '40px 24px', textAlign: 'center',
          }}>
            <div style={{ fontSize: '3rem', marginBottom: 16 }}>🏓</div>
            <h3 style={{ color: '#f5f5f5', fontWeight: 700, marginBottom: 8 }}>Start Your Journey</h3>
            <p style={{ color: '#666', fontSize: '0.875rem', lineHeight: 1.6, marginBottom: 20 }}>
              Set your first intention before your next game. The process begins here.
            </p>
            <button
              onClick={() => onNavigate('journal', { mode: 'pre' })}
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
        </div>
      )}
    </div>
  );
}

function IntentionRow({ icon, label, value }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
      <span style={{ fontSize: '0.9rem', marginTop: 2 }}>{icon}</span>
      <div>
        <div className="label-xs" style={{ color: '#555', marginBottom: 2 }}>{label}</div>
        <div style={{ color: '#d0d0d0', fontSize: '0.875rem', fontWeight: 500, lineHeight: 1.4 }}>{value}</div>
      </div>
    </div>
  );
}

function ActionButton({ icon, label, sub, accent, onClick }) {
  return (
    <button
      onClick={onClick}
      className="press-scale"
      style={{
        background: accent ? 'rgba(200,241,53,0.1)' : '#141414',
        border: accent ? '1.5px solid rgba(200,241,53,0.3)' : '1px solid #2a2a2a',
        borderRadius: 18, padding: '16px 14px', cursor: 'pointer', textAlign: 'left',
        display: 'flex', flexDirection: 'column', gap: 8, transition: 'all 0.2s',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {icon}
        <span style={{ color: accent ? '#c8f135' : '#a0a0a0', fontWeight: 700, fontSize: '0.85rem' }}>{label}</span>
      </div>
      <span style={{ color: '#555', fontSize: '0.75rem', lineHeight: 1.4 }}>{sub}</span>
    </button>
  );
}

function QuickCard({ icon, title, sub, color, onClick }) {
  return (
    <button
      onClick={onClick}
      className="press-scale"
      style={{
        background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18,
        padding: '16px 18px', cursor: 'pointer', textAlign: 'left',
        display: 'flex', alignItems: 'center', gap: 14, width: '100%',
        transition: 'all 0.2s',
      }}
    >
      <div style={{
        width: 44, height: 44, borderRadius: 14, flexShrink: 0,
        background: `${color}18`, border: `1px solid ${color}30`,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.25rem',
      }}>
        {icon}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.9rem', marginBottom: 3 }}>{title}</div>
        <div style={{ color: '#555', fontSize: '0.75rem' }}>{sub}</div>
      </div>
      <ChevronRight size={16} color="#555" />
    </button>
  );
}

function MiniStat({ label, value, icon }) {
  return (
    <div style={{
      background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16, padding: '14px 12px', textAlign: 'center',
    }}>
      <div style={{ fontSize: '1.1rem', marginBottom: 6 }}>{icon}</div>
      <div style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.1rem', marginBottom: 2 }}>{value}</div>
      <div className="label-xs" style={{ color: '#555' }}>{label}</div>
    </div>
  );
}

function RecentSession({ session }) {
  const dateStr = session.date
    ? new Date(session.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    : 'Recently';
  return (
    <div style={{
      background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16,
      padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <span style={{ fontSize: '1.5rem' }}>
        {session.mood === 'fired-up' ? '🔥' : session.mood === 'calm' ? '🧘' : session.mood === 'focused' ? '🎯' : '🏓'}
      </span>
      <div style={{ flex: 1 }}>
        <div style={{ color: '#f5f5f5', fontWeight: 600, fontSize: '0.875rem' }}>
          {session.gameType || 'Session'}
        </div>
        <div style={{ color: '#555', fontSize: '0.75rem', marginTop: 2 }}>
          {dateStr} · {session.skillFocus || 'General play'}
        </div>
      </div>
      {session.rating > 0 && (
        <div style={{ display: 'flex', gap: 2 }}>
          {[1, 2, 3, 4, 5].map(i => (
            <div key={i} style={{
              width: 6, height: 6, borderRadius: '50%',
              background: i <= session.rating ? '#c8f135' : '#2a2a2a',
            }} />
          ))}
        </div>
      )}
    </div>
  );
}

function SectionHeader({ title, onAction, actionLabel, style }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', ...style }}>
      <span style={{ color: '#a0a0a0', fontSize: '0.75rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
        {title}
      </span>
      {onAction && (
        <button onClick={onAction} style={{ background: 'none', border: 'none', color: '#c8f135', fontSize: '0.75rem', fontWeight: 600, cursor: 'pointer' }}>
          {actionLabel}
        </button>
      )}
    </div>
  );
}

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

function getAvgRating(sessions) {
  const withRating = sessions.filter(s => s.rating > 0);
  if (!withRating.length) return '—';
  return (withRating.reduce((a, s) => a + s.rating, 0) / withRating.length).toFixed(1);
}
