import { Trophy, Flame, BookOpen, Target, TrendingUp, Star, ChevronRight, Zap } from 'lucide-react';

export default function Dashboard({ sessions, onNavigate }) {
  const totalGames = sessions.length;
  const totalWins = sessions.filter(s => s.result === 'win').length;
  const winRate = totalGames > 0 ? Math.round((totalWins / totalGames) * 100) : 0;

  // Streak calculation
  let streak = 0;
  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  for (let i = 0; i < sorted.length; i++) {
    const diff = (new Date() - new Date(sorted[i].date)) / (1000 * 60 * 60 * 24);
    if (i === 0 && diff > 2) break;
    streak++;
  }

  const recentSessions = sorted.slice(0, 3);

  const avgRating = sessions.length > 0
    ? (sessions.reduce((acc, s) => acc + (s.rating || 0), 0) / sessions.length).toFixed(1)
    : '—';

  const quotes = [
    '"Champions are made in the kitchen — the non-volley zone." ',
    '"Soft hands, quick feet, calm mind." ',
    '"Every dink rally is a chess match. Think 3 shots ahead." ',
    '"The third shot drop is the key that unlocks the net." ',
    '"Control the kitchen, control the game." ',
  ];
  const todayQuote = quotes[new Date().getDay() % quotes.length];

  return (
    <div className="animate-fade-in space-y-6 pb-8">
      {/* Hero Banner */}
      <div className="bg-gradient-to-br from-pickle-600 via-pickle-700 to-pickle-800 rounded-3xl p-6 text-white shadow-xl">
        <div className="flex items-center gap-2 mb-1">
          <span className="text-2xl">🥒</span>
          <h1 className="text-2xl font-bold tracking-tight">PicklePro</h1>
        </div>
        <p className="text-pickle-100 text-sm mb-4">Your personal pickleball growth coach</p>
        <blockquote className="bg-white/10 rounded-2xl p-3 text-sm italic text-pickle-50 border-l-4 border-pickle-300">
          {todayQuote}
        </blockquote>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-2 gap-3">
        <StatCard icon={<Trophy className="w-5 h-5 text-yellow-500" />} label="Win Rate" value={`${winRate}%`} sub={`${totalWins}W / ${totalGames - totalWins}L`} bg="bg-yellow-50" border="border-yellow-200" />
        <StatCard icon={<Flame className="w-5 h-5 text-orange-500" />} label="Game Streak" value={streak} sub="sessions logged" bg="bg-orange-50" border="border-orange-200" />
        <StatCard icon={<BookOpen className="w-5 h-5 text-blue-500" />} label="Games Logged" value={totalGames} sub="total sessions" bg="bg-blue-50" border="border-blue-200" />
        <StatCard icon={<Star className="w-5 h-5 text-purple-500" />} label="Avg Rating" value={avgRating} sub="self assessment" bg="bg-purple-50" border="border-purple-200" />
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-gray-700 font-semibold text-sm uppercase tracking-wider mb-3">Quick Start</h2>
        <div className="space-y-2">
          <QuickAction
            icon="🎯"
            title="Set Today's Intentions"
            subtitle="Focus your mind before you play"
            color="bg-gradient-to-r from-blue-500 to-blue-600"
            onClick={() => onNavigate('intentions')}
          />
          <QuickAction
            icon="📓"
            title="Log a Game"
            subtitle="Journal your session & reflect"
            color="bg-gradient-to-r from-pickle-500 to-pickle-600"
            onClick={() => onNavigate('journal')}
          />
          <QuickAction
            icon="💡"
            title="Tips & Tricks"
            subtitle="Learn from the pros"
            color="bg-gradient-to-r from-amber-500 to-orange-500"
            onClick={() => onNavigate('tips')}
          />
          <QuickAction
            icon="📈"
            title="My Progress"
            subtitle="Track your improvement over time"
            color="bg-gradient-to-r from-purple-500 to-purple-600"
            onClick={() => onNavigate('progress')}
          />
        </div>
      </div>

      {/* Recent Sessions */}
      {recentSessions.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-gray-700 font-semibold text-sm uppercase tracking-wider">Recent Sessions</h2>
            <button
              onClick={() => onNavigate('history')}
              className="text-pickle-600 text-xs font-medium flex items-center gap-1"
            >
              See all <ChevronRight className="w-3 h-3" />
            </button>
          </div>
          <div className="space-y-2">
            {recentSessions.map(session => (
              <SessionCard key={session.id} session={session} />
            ))}
          </div>
        </div>
      )}

      {totalGames === 0 && (
        <div className="text-center py-8 bg-white rounded-2xl shadow-sm border border-gray-100">
          <div className="text-5xl mb-3">🏓</div>
          <h3 className="text-gray-700 font-semibold text-lg mb-1">Start Your Journey</h3>
          <p className="text-gray-500 text-sm mb-4 px-6">Set your first intentions and log your first game to begin tracking your growth.</p>
          <button
            onClick={() => onNavigate('intentions')}
            className="bg-pickle-500 text-white px-6 py-2.5 rounded-full text-sm font-semibold shadow-md active:scale-95 transition-transform"
          >
            Set Intentions Now
          </button>
        </div>
      )}

      {/* Tip of the Day */}
      <TipOfDay onNavigate={onNavigate} />
    </div>
  );
}

function StatCard({ icon, label, value, sub, bg, border }) {
  return (
    <div className={`${bg} border ${border} rounded-2xl p-4 shadow-sm`}>
      <div className="flex items-center gap-2 mb-1">
        {icon}
        <span className="text-xs text-gray-500 font-medium">{label}</span>
      </div>
      <div className="text-2xl font-bold text-gray-800">{value}</div>
      <div className="text-xs text-gray-500 mt-0.5">{sub}</div>
    </div>
  );
}

function QuickAction({ icon, title, subtitle, color, onClick }) {
  return (
    <button
      onClick={onClick}
      className={`${color} w-full text-left flex items-center gap-4 p-4 rounded-2xl shadow-md active:scale-98 transition-all`}
    >
      <span className="text-2xl">{icon}</span>
      <div className="flex-1">
        <div className="text-white font-semibold text-sm">{title}</div>
        <div className="text-white/70 text-xs">{subtitle}</div>
      </div>
      <ChevronRight className="w-5 h-5 text-white/60" />
    </button>
  );
}

function SessionCard({ session }) {
  const resultColors = {
    win: 'bg-green-100 text-green-700',
    loss: 'bg-red-100 text-red-700',
    neutral: 'bg-gray-100 text-gray-600',
  };
  const dateStr = new Date(session.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

  return (
    <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 flex items-center gap-3">
      <div className="text-2xl">{session.mood === 'fired-up' ? '🔥' : session.mood === 'calm' ? '🧘' : '🎯'}</div>
      <div className="flex-1 min-w-0">
        <div className="font-semibold text-gray-800 text-sm truncate">{session.gameType || 'Session'}</div>
        <div className="text-xs text-gray-400">{dateStr} · {session.duration || '?'} min</div>
      </div>
      <div className="flex flex-col items-end gap-1">
        {session.result && (
          <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${resultColors[session.result] || resultColors.neutral}`}>
            {session.result.toUpperCase()}
          </span>
        )}
        {session.rating && (
          <div className="flex">
            {[1,2,3,4,5].map(i => (
              <Star key={i} className={`w-3 h-3 ${i <= session.rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-200'}`} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function TipOfDay({ onNavigate }) {
  const tips = [
    { emoji: '🎯', text: 'Hit 10 consecutive dinks cross-court in your next warmup — no misses.', category: 'Dinking' },
    { emoji: '🦘', text: 'Practice your split step every time you play today — even in warmup.', category: 'Movement' },
    { emoji: '🪂', text: 'Before each game, hit 20 third shot drops. Consistency is your friend.', category: 'Third Shot' },
    { emoji: '🧠', text: 'Play your first 3 points with zero emotion — pure focus on placement.', category: 'Mental Game' },
    { emoji: '👟', text: 'Aim every volley at your opponent\'s feet today — watch the errors pile up.', category: 'Volleys' },
    { emoji: '💡', text: 'Dink cross-court 80% of the time — it goes over the lowest part of the net.', category: 'Strategy' },
    { emoji: '🤲', text: 'Rate your grip 3/10 during dink rallies. Squeeze only when attacking.', category: 'Dinking' },
  ];
  const tip = tips[new Date().getDate() % tips.length];

  return (
    <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
      <div className="flex items-center gap-2 mb-2">
        <Zap className="w-4 h-4 text-amber-600" />
        <span className="text-amber-700 font-semibold text-xs uppercase tracking-wider">Drill of the Day</span>
      </div>
      <div className="flex gap-3">
        <span className="text-2xl">{tip.emoji}</span>
        <div>
          <p className="text-gray-700 text-sm font-medium">{tip.text}</p>
          <button
            onClick={() => onNavigate('tips')}
            className="text-amber-600 text-xs font-semibold mt-1 flex items-center gap-1"
          >
            See all {tip.category} tips <ChevronRight className="w-3 h-3" />
          </button>
        </div>
      </div>
    </div>
  );
}
