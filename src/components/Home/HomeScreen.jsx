import { ChevronRight, Flame, BookOpen, Target, Play, Heart, Trophy, TrendingUp } from 'lucide-react';
import { getTodayIntention } from '../../data/intentionTemplates';

// ─── Dynamic Motivational Content ────────────────────────────────────────────

const MOTIVATIONAL_QUOTES = [
  { quote: "Play free today.", sub: "Freedom comes from trust in your preparation." },
  { quote: "Patience creates opportunity.", sub: "Every rally is a chance to build something." },
  { quote: "Compete hard. Stay loose.", sub: "The best players hold both truths at once." },
  { quote: "Growth compounds.", sub: "Every session you log is a deposit in your future game." },
  { quote: "Play with intention. Play with joy.", sub: "The players who improve most do both." },
  { quote: "Enjoy the rally.", sub: "The lesson you need today is hiding inside it." },
  { quote: "Your mindset is your paddle.", sub: "Sharpen both, and watch what happens." },
  { quote: "One ball at a time.", sub: "The rest will take care of itself." },
  { quote: "The court is your classroom.", sub: "Show up curious. Leave sharper." },
  { quote: "Trust the process, not the scoreboard.", sub: "Process players always catch up." },
  { quote: "Your next level is one habit away.", sub: "You're closer than you think." },
  { quote: "Champions are built in practice.", sub: "The match just reveals who did the work." },
  { quote: "Today's effort is tomorrow's edge.", sub: "Your future self will thank you for showing up today." },
  { quote: "The dink is a conversation.", sub: "Learn to listen before you shout." },
];

const COMEBACK_MESSAGES = [
  { days: 1, message: "Welcome back! Let's build on yesterday.", emoji: "💪" },
  { days: 2, message: "Two days rest — your body recovers, your mind stays sharp.", emoji: "🧠" },
  { days: 3, message: "Your paddle misses you. Let's get back to work.", emoji: "🏓" },
  { days: 5, message: "It's been a few days — but champions return. You're here now.", emoji: "🔥" },
  { days: 7, message: "A week away means fresh eyes. Today is a clean slate.", emoji: "✨" },
  { days: 14, message: "The court has been waiting for you. Every comeback starts with one session.", emoji: "🌱" },
  { days: 30, message: "You're back. That takes courage. Let's rebuild together, one rally at a time.", emoji: "❤️" },
];

const MILESTONE_MESSAGES = {
  5: { title: "5 Sessions Strong!", body: "You've built a real foundation. Most players never make it this far.", emoji: "🌟" },
  10: { title: "Double Digits!", body: "10 sessions of intentional practice. You're no longer hoping to improve — you're proving it.", emoji: "🔥" },
  25: { title: "25 Sessions Deep!", body: "A quarter-century of growth. Your patience, discipline, and love for the game are showing.", emoji: "💎" },
  50: { title: "Fifty and Fearless!", body: "50 sessions of showing up with intention. You are the kind of player others want to play with.", emoji: "🏆" },
  100: { title: "The Century Club!", body: "100 sessions. You've built something extraordinary — a practice of growth that will last a lifetime.", emoji: "👑" },
};

const STREAK_CELEBRATIONS = {
  3: "3-day streak! Consistency is your superpower.",
  5: "5 days running! You're building real momentum.",
  7: "A full week! This is what commitment looks like.",
  10: "10-day streak! Your dedication is inspiring.",
  14: "Two weeks strong! You're in the top 5% of players who track their growth.",
  21: "21 days — this is officially a habit now. You've changed who you are as a player.",
  30: "30-day streak! A full month of intentional growth. Remarkable.",
};

// ─── Helper Functions ─────────────────────────────────────────────────────────

function getDaysSinceLastSession(sessions) {
  if (!sessions.length) return Infinity;
  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  return Math.floor((Date.now() - new Date(sorted[0].date)) / (1000 * 60 * 60 * 24));
}

function getComeback(daysSince) {
  const msg = [...COMEBACK_MESSAGES].reverse().find(m => daysSince >= m.days);
  return msg || COMEBACK_MESSAGES[0];
}

function getMilestone(count) {
  const milestones = [100, 50, 25, 10, 5];
  for (const m of milestones) {
    if (count === m) return MILESTONE_MESSAGES[m];
  }
  return null;
}

function getStreakCelebration(streak) {
  const thresholds = [30, 21, 14, 10, 7, 5, 3];
  for (const t of thresholds) {
    if (streak === t) return STREAK_CELEBRATIONS[t];
  }
  return null;
}

function getPersonalizedNudge(profile, sessions) {
  const struggles = profile?.struggles || [];
  const mentalWeaknesses = profile?.mentalWeaknesses || [];
  const recentSessions = sessions.slice(0, 5);

  if (recentSessions.length >= 3) {
    const avgPatience = recentSessions.reduce((a, s) => a + (s.patienceScore || 0), 0) / recentSessions.length;
    if (avgPatience > 0 && avgPatience >= 7) {
      return { text: "Your patience scores are climbing. That's the sign of a player who's learning to trust the rally.", icon: "📈", color: "#22c55e" };
    }
    const avgEmotions = recentSessions.reduce((a, s) => a + (s.emotionsScore || 0), 0) / recentSessions.length;
    if (avgEmotions > 0 && avgEmotions >= 7) {
      return { text: "Your emotional control is becoming a weapon. Opponents can't rattle someone this composed.", icon: "🧘", color: "#3b82f6" };
    }
  }

  if (mentalWeaknesses.includes('patience-mental')) {
    return { text: "Today's edge: patience. The players who wait for the right ball always win more points.", icon: "⏳", color: "#f59e0b" };
  }
  if (struggles.includes('thirds')) {
    return { text: "One tip: before you play today, visualize 5 perfect third shot drops. See the arc. Feel the softness.", icon: "🎯", color: "#c8f135" };
  }
  if (mentalWeaknesses.includes('frustration')) {
    return { text: "Remember: frustration is just passion without direction. Channel it into focus today.", icon: "🌊", color: "#3b82f6" };
  }
  if (struggles.includes('communication')) {
    return { text: "Quick partner challenge: call every ball today. 'Mine!' or 'Yours!' — zero ambiguity.", icon: "🤝", color: "#22c55e" };
  }

  return { text: "Every time you step on the court with intention, you're separating yourself from 90% of players.", icon: "💡", color: "#a855f7" };
}

function calcStreak(sessions) {
  if (!sessions.length) return 0;
  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  const daySet = new Set();
  sorted.forEach(s => {
    const key = new Date(s.date).toISOString().split('T')[0];
    daySet.add(key);
  });

  let streak = 0;
  const cursor = new Date();
  const todayKey = cursor.toISOString().split('T')[0];
  if (!daySet.has(todayKey)) {
    cursor.setDate(cursor.getDate() - 1);
  }
  while (true) {
    const key = cursor.toISOString().split('T')[0];
    if (!daySet.has(key)) break;
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

function getAvgRating(sessions) {
  const withRating = sessions.filter(s => s.rating > 0);
  if (!withRating.length) return '—';
  return (withRating.reduce((a, s) => a + s.rating, 0) / withRating.length).toFixed(1);
}

// ─── Main Component ──────────────────────────────────────────────────────────

export default function HomeScreen({ profile, sessions, intentions, onNavigate }) {
  const todayKey = new Date().toISOString().split('T')[0];
  const savedToday = (intentions || []).find(i => i.date === todayKey);
  const today = savedToday ?? getTodayIntention();
  const hour = new Date().getHours();

  const greeting = hour < 5 ? 'Night owl' : hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  const greetingEmoji = hour < 5 ? '🌙' : hour < 12 ? '☀️' : hour < 17 ? '🎯' : '🌙';
  const firstName = profile?.name?.split(' ')[0] || 'Player';

  const streak = calcStreak(sessions);
  const daysSince = getDaysSinceLastSession(sessions);
  const milestone = getMilestone(sessions.length);
  const streakCelebration = getStreakCelebration(streak);
  const comeback = daysSince >= 3 && sessions.length > 0 ? getComeback(daysSince) : null;
  const nudge = getPersonalizedNudge(profile, sessions);

  const quoteIdx = (new Date().getDate() + new Date().getMonth()) % MOTIVATIONAL_QUOTES.length;
  const todayQuote = MOTIVATIONAL_QUOTES[quoteIdx];

  const todaySessionExists = sessions.some(s => new Date(s.date).toISOString().split('T')[0] === todayKey);

  return (
    <div className="animate-fade-in" style={{ paddingBottom: 100 }}>
      <div style={{ padding: '20px 20px 0' }}>
        {/* ─── Greeting ──────────────────────────────────────────── */}
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 20 }}>
          <div>
            <p style={{ color: '#666', fontSize: '0.8rem', marginBottom: 4 }}>
              {greetingEmoji} {greeting}
            </p>
            <h1 style={{ fontSize: '1.6rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em' }}>
              {firstName}<span style={{ color: '#c8f135' }}>.</span>
            </h1>
            {sessions.length > 0 && !comeback && (
              <p style={{ color: '#555', fontSize: '0.78rem', marginTop: 4 }}>
                {todaySessionExists ? "You showed up today. That matters." : "Ready to grow today?"}
              </p>
            )}
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

        {/* ─── Milestone Celebration ──────────────────────────────── */}
        {milestone && (
          <div className="animate-scale-in" style={{
            background: 'linear-gradient(135deg, #1a1a00 0%, #1a1000 100%)',
            border: '1px solid rgba(200,241,53,0.4)',
            borderRadius: 20, padding: '20px', marginBottom: 16, textAlign: 'center',
            boxShadow: '0 0 30px rgba(200,241,53,0.1)',
          }}>
            <div style={{ fontSize: '2.5rem', marginBottom: 8 }}>{milestone.emoji}</div>
            <h3 style={{ color: '#c8f135', fontWeight: 800, fontSize: '1.1rem', margin: '0 0 8px' }}>{milestone.title}</h3>
            <p style={{ color: '#a0a0a0', fontSize: '0.85rem', lineHeight: 1.6, margin: 0 }}>{milestone.body}</p>
          </div>
        )}

        {/* ─── Streak Celebration ─────────────────────────────────── */}
        {streakCelebration && !milestone && (
          <div style={{
            background: 'rgba(249,115,22,0.08)', border: '1px solid rgba(249,115,22,0.25)',
            borderRadius: 16, padding: '14px 16px', marginBottom: 16,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <span style={{ fontSize: '1.5rem' }}>🔥</span>
            <p style={{ color: '#f97316', fontSize: '0.85rem', fontWeight: 600, margin: 0, lineHeight: 1.5 }}>
              {streakCelebration}
            </p>
          </div>
        )}

        {/* ─── Comeback Welcome ───────────────────────────────────── */}
        {comeback && (
          <div style={{
            background: 'rgba(168,85,247,0.08)', border: '1px solid rgba(168,85,247,0.25)',
            borderRadius: 16, padding: '16px', marginBottom: 16,
            display: 'flex', alignItems: 'flex-start', gap: 12,
          }}>
            <span style={{ fontSize: '1.5rem' }}>{comeback.emoji}</span>
            <div>
              <p style={{ color: '#e0d0f0', fontSize: '0.9rem', fontWeight: 600, margin: '0 0 4px' }}>
                {comeback.message}
              </p>
              <p style={{ color: '#666', fontSize: '0.78rem', margin: 0 }}>
                Growth isn&apos;t linear. Showing up again is what matters.
              </p>
            </div>
          </div>
        )}

        {/* ─── Today's Intention Card ─────────────────────────────── */}
        <div style={{
          background: 'linear-gradient(135deg, #141414 0%, #1a1a0e 100%)',
          border: '1px solid rgba(200,241,53,0.25)',
          borderRadius: 24, padding: '22px 20px', marginBottom: 16,
          position: 'relative', overflow: 'hidden',
        }}>
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

          <div style={{ marginTop: 16, paddingTop: 16, borderTop: '1px solid #2a2a2a' }}>
            <p style={{ color: '#c8f135', fontSize: '0.9rem', fontStyle: 'italic', fontWeight: 600, margin: 0 }}>
              &ldquo;{today.quote}&rdquo;
            </p>
            <p style={{ color: '#555', fontSize: '0.75rem', margin: '4px 0 0' }}>{today.cue}</p>
          </div>
        </div>

        {/* ─── Personalized Coaching Nudge ─────────────────────────── */}
        {nudge && (
          <div style={{
            background: `${nudge.color}08`, border: `1px solid ${nudge.color}25`,
            borderRadius: 16, padding: '14px 16px', marginBottom: 16,
            display: 'flex', alignItems: 'flex-start', gap: 12,
          }}>
            <span style={{ fontSize: '1.25rem', flexShrink: 0 }}>{nudge.icon}</span>
            <p style={{ color: '#c0c0c0', fontSize: '0.84rem', lineHeight: 1.6, margin: 0 }}>
              {nudge.text}
            </p>
          </div>
        )}

        {/* ─── Before / After Play CTAs ───────────────────────────── */}
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

      {/* ─── Inspirational Quote ───────────────────────────────── */}
      <div style={{ padding: '0 20px', marginBottom: 20 }}>
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 20, padding: '18px 20px',
        }}>
          <p style={{ color: '#f5f5f5', fontSize: '1.05rem', fontWeight: 700, margin: 0, lineHeight: 1.5 }}>
            &ldquo;{todayQuote.quote}&rdquo;
          </p>
          <p style={{ color: '#555', fontSize: '0.8rem', margin: '8px 0 0' }}>{todayQuote.sub}</p>
        </div>
      </div>

      {/* ─── Quick Access ──────────────────────────────────────── */}
      <SectionHeader title="Your Toolkit" style={{ padding: '0 20px', marginBottom: 12 }} />
      <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 24 }}>
        <QuickCard
          icon="🎯"
          title="Skill Library"
          sub="9 skill categories with drills, tips & coaching cues"
          color="#c8f135"
          onClick={() => onNavigate('skills')}
        />
        <QuickCard
          icon="🧠"
          title="Mental Game"
          sub="9 pillars of sports psychology for pickleball"
          color="#3b82f6"
          onClick={() => onNavigate('mental')}
        />
        <QuickCard
          icon="🤖"
          title="AI Coach"
          sub="Personalized insights based on your sessions"
          color="#a855f7"
          onClick={() => onNavigate('coach')}
        />
      </div>

      {/* ─── Progress Stats ────────────────────────────────────── */}
      {sessions.length > 0 && (
        <>
          <SectionHeader title="Your Progress" onAction={() => onNavigate('progress')} actionLabel="See all" style={{ padding: '0 20px', marginBottom: 12 }} />
          <div style={{ padding: '0 20px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 24 }}>
            <MiniStat label="Sessions" value={sessions.length} icon={<BookOpen size={16} color="#3b82f6" />} />
            <MiniStat label="Streak" value={streak > 0 ? `${streak}` : '—'} icon={<Flame size={16} color="#f97316" />} />
            <MiniStat label="Avg Rating" value={getAvgRating(sessions)} icon={<TrendingUp size={16} color="#c8f135" />} />
          </div>
        </>
      )}

      {/* ─── Recent Sessions ──────────────────────────────────── */}
      {sessions.length > 0 && (
        <>
          <SectionHeader title="Recent Sessions" onAction={() => onNavigate('journal')} actionLabel="All" style={{ padding: '0 20px', marginBottom: 12 }} />
          <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 10 }}>
            {sessions.slice(0, 3).map(s => (
              <RecentSession key={s.id} session={s} />
            ))}
          </div>
        </>
      )}

      {/* ─── Empty State ──────────────────────────────────────── */}
      {sessions.length === 0 && (
        <div style={{ padding: '0 20px' }}>
          <div style={{
            background: 'linear-gradient(135deg, #141414 0%, #1a1a0e 100%)',
            border: '1px solid rgba(200,241,53,0.2)', borderRadius: 24,
            padding: '44px 24px', textAlign: 'center',
          }}>
            <div style={{ fontSize: '3.5rem', marginBottom: 16 }}>🏓</div>
            <h3 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.2rem', marginBottom: 12 }}>
              Your Journey Starts Today
            </h3>
            <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.7, marginBottom: 8, maxWidth: 280, margin: '0 auto 8px' }}>
              The best pickleball players don&apos;t just play more — they <em style={{ color: '#f5f5f5' }}>reflect</em> more.
            </p>
            <p style={{ color: '#666', fontSize: '0.82rem', lineHeight: 1.6, marginBottom: 24 }}>
              Set your first pre-play intention, and after your session, log what you learned. This simple habit separates recreational players from players who genuinely grow.
            </p>
            <button
              onClick={() => onNavigate('journal', { mode: 'pre' })}
              className="press-scale"
              style={{
                background: 'linear-gradient(135deg, #c8f135, #a8d820)',
                color: '#0a0a0a', border: 'none', borderRadius: 14,
                padding: '16px 32px', fontWeight: 800, fontSize: '0.95rem', cursor: 'pointer',
                boxShadow: '0 0 20px rgba(200,241,53,0.3)',
              }}
            >
              Set My First Intention
            </button>
          </div>
        </div>
      )}

      {/* ─── Process Philosophy Footer ─────────────────────────── */}
      {sessions.length > 0 && (
        <div style={{ padding: '20px 20px 0' }}>
          <div style={{
            background: 'rgba(200,241,53,0.04)', border: '1px solid rgba(200,241,53,0.12)',
            borderRadius: 16, padding: '16px',
          }}>
            <p style={{ color: '#555', fontSize: '0.8rem', lineHeight: 1.7, margin: 0, fontStyle: 'italic' }}>
              &ldquo;You don&apos;t get better by playing more. You get better by paying attention to how you play. That&apos;s what this app is for — and that&apos;s what makes you different from most players on the court.&rdquo;
            </p>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Sub-Components ──────────────────────────────────────────────────────────

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
      <div style={{ marginBottom: 6, display: 'flex', justifyContent: 'center' }}>{icon}</div>
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
        {session.prePlayMood === 'fired-up' || session.mood === 'fired-up' ? '🔥' :
         session.prePlayMood === 'calm' || session.mood === 'calm' ? '🧘' :
         session.prePlayMood === 'focused' || session.mood === 'focused' ? '🎯' : '🏓'}
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
