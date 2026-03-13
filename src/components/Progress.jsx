import { TrendingUp, Award, Target, Calendar, BarChart2, Zap } from 'lucide-react';

export default function Progress({ sessions, intentions }) {
  const totalGames = sessions.length;
  const wins = sessions.filter(s => s.result === 'win').length;
  const losses = sessions.filter(s => s.result === 'loss').length;
  const winRate = totalGames > 0 ? Math.round((wins / totalGames) * 100) : 0;

  const avgRating = sessions.length > 0
    ? (sessions.reduce((acc, s) => acc + (s.rating || 0), 0) / sessions.filter(s => s.rating > 0).length || 0).toFixed(1)
    : 0;

  // Win rate over last 5 games
  const last5 = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 5);
  const last5WinRate = last5.length > 0 ? Math.round((last5.filter(s => s.result === 'win').length / last5.length) * 100) : 0;

  // Skill focus frequency
  const skillCount = {};
  sessions.forEach(s => {
    if (s.skillFocus) s.skillFocus.forEach(skill => {
      skillCount[skill] = (skillCount[skill] || 0) + 1;
    });
  });
  intentions.forEach(i => {
    if (i.skillFocus) i.skillFocus.forEach(skill => {
      skillCount[skill] = (skillCount[skill] || 0) + 1;
    });
  });
  const topSkills = Object.entries(skillCount)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  // Rating trend (last 10 sessions with ratings)
  const ratedSessions = [...sessions]
    .filter(s => s.rating > 0)
    .sort((a, b) => new Date(a.date) - new Date(b.date))
    .slice(-10);

  // Monthly game count
  const gamesByMonth = {};
  sessions.forEach(s => {
    const month = new Date(s.date).toLocaleDateString('en-US', { month: 'short', year: '2-digit' });
    gamesByMonth[month] = (gamesByMonth[month] || 0) + 1;
  });
  const months = Object.entries(gamesByMonth).slice(-6);

  // Streak
  let streak = 0;
  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));
  for (let i = 0; i < sorted.length; i++) {
    const diff = (new Date() - new Date(sorted[i].date)) / (1000 * 60 * 60 * 24);
    if (i === 0 && diff > 2) break;
    streak++;
  }

  const badges = [
    { id: 'first', emoji: '🎉', label: 'First Session', earned: totalGames >= 1, desc: 'Log your first game' },
    { id: 'five', emoji: '⚡', label: 'On a Roll', earned: totalGames >= 5, desc: 'Log 5 sessions' },
    { id: 'ten', emoji: '🔥', label: 'Dedicated', earned: totalGames >= 10, desc: 'Log 10 sessions' },
    { id: 'winstreak', emoji: '🏆', label: 'Winner', earned: wins >= 3, desc: 'Win 3 games' },
    { id: 'intend', emoji: '🎯', label: 'Intentional', earned: intentions.length >= 3, desc: 'Set 3 pre-game intentions' },
    { id: 'reflect', emoji: '🧘', label: 'Reflector', earned: sessions.filter(s => s.highlights || s.challenges).length >= 5, desc: 'Journal 5 detailed sessions' },
    { id: 'perfectrating', emoji: '⭐', label: 'Peak Performance', earned: sessions.some(s => s.rating === 5), desc: 'Rate a session 5 stars' },
    { id: 'champion', emoji: '👑', label: 'Champion', earned: wins >= 10, desc: 'Win 10 games' },
  ];

  if (totalGames === 0) {
    return (
      <div className="animate-fade-in text-center py-12 space-y-4">
        <div className="text-6xl">📈</div>
        <h2 className="text-xl font-bold text-gray-700">Your Progress Awaits</h2>
        <p className="text-gray-500 text-sm px-8">Start logging games to see your stats, trends, and achievements here.</p>
        <div className="bg-pickle-50 border border-pickle-200 rounded-2xl p-4 text-left mx-2">
          <p className="text-pickle-700 font-semibold text-sm mb-2">What you'll track:</p>
          <ul className="text-sm text-pickle-600 space-y-1">
            <li>✅ Win rate over time</li>
            <li>✅ Performance ratings trend</li>
            <li>✅ Top practiced skills</li>
            <li>✅ Monthly game frequency</li>
            <li>✅ Achievement badges</li>
          </ul>
        </div>
      </div>
    );
  }

  return (
    <div className="animate-fade-in space-y-5 pb-8">
      {/* Header */}
      <div className="bg-gradient-to-br from-purple-500 to-purple-700 rounded-3xl p-5 text-white shadow-xl">
        <div className="flex items-center gap-2 mb-1">
          <TrendingUp className="w-5 h-5" />
          <h2 className="font-bold text-lg">My Progress</h2>
        </div>
        <p className="text-purple-100 text-sm">{totalGames} session{totalGames !== 1 ? 's' : ''} logged — keep going!</p>
      </div>

      {/* Key Stats */}
      <div className="grid grid-cols-3 gap-3">
        <MiniStat label="Win Rate" value={`${winRate}%`} sub={`${wins}W / ${losses}L`} color="text-green-600" bg="bg-green-50" />
        <MiniStat label="Avg Rating" value={avgRating || '—'} sub="out of 5 stars" color="text-yellow-600" bg="bg-yellow-50" />
        <MiniStat label="Streak" value={streak} sub="sessions" color="text-orange-600" bg="bg-orange-50" />
      </div>

      {/* Last 5 Games */}
      {last5.length >= 2 && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
          <h3 className="font-semibold text-gray-700 text-sm mb-3 flex items-center gap-2">
            <BarChart2 className="w-4 h-4 text-gray-500" /> Recent Form (Last 5)
          </h3>
          <div className="flex gap-2 mb-3">
            {last5.map(s => (
              <div
                key={s.id}
                className={`flex-1 h-10 rounded-xl flex items-center justify-center text-xs font-bold
                  ${s.result === 'win' ? 'bg-green-500 text-white' :
                    s.result === 'loss' ? 'bg-red-400 text-white' :
                    'bg-gray-200 text-gray-600'}`}
              >
                {s.result === 'win' ? 'W' : s.result === 'loss' ? 'L' : '-'}
              </div>
            ))}
            {Array.from({ length: Math.max(0, 5 - last5.length) }).map((_, i) => (
              <div key={`empty-${i}`} className="flex-1 h-10 rounded-xl bg-gray-100" />
            ))}
          </div>
          <div className="text-center">
            <span className={`text-sm font-bold ${last5WinRate >= 60 ? 'text-green-600' : last5WinRate >= 40 ? 'text-yellow-600' : 'text-red-500'}`}>
              {last5WinRate}% win rate in last {last5.length} games
            </span>
            <p className="text-xs text-gray-400 mt-0.5">
              {last5WinRate >= 60 ? 'Excellent recent form! 🔥' :
               last5WinRate >= 40 ? 'Building momentum — keep going!' :
               'Time to refocus — review your intentions!'}
            </p>
          </div>
        </div>
      )}

      {/* Rating Trend */}
      {ratedSessions.length >= 2 && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
          <h3 className="font-semibold text-gray-700 text-sm mb-3 flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-gray-500" /> Performance Trend
          </h3>
          <div className="flex items-end gap-2 h-20">
            {ratedSessions.map((s, i) => {
              const height = (s.rating / 5) * 100;
              return (
                <div key={s.id} className="flex-1 flex flex-col items-center gap-1">
                  <div
                    className="w-full rounded-t-lg transition-all bg-gradient-to-t from-purple-500 to-purple-300"
                    style={{ height: `${height}%`, minHeight: '4px' }}
                  />
                  <span className="text-xs text-gray-400">{s.rating}</span>
                </div>
              );
            })}
          </div>
          <div className="text-xs text-gray-400 text-center mt-1">Rating per session (last {ratedSessions.length})</div>
          {ratedSessions.length >= 3 && (() => {
            const first3Avg = ratedSessions.slice(0, 3).reduce((a, s) => a + s.rating, 0) / 3;
            const last3Avg = ratedSessions.slice(-3).reduce((a, s) => a + s.rating, 0) / 3;
            const trend = last3Avg - first3Avg;
            return (
              <div className={`mt-2 text-center text-sm font-semibold ${trend > 0 ? 'text-green-600' : trend < 0 ? 'text-red-500' : 'text-gray-500'}`}>
                {trend > 0 ? `📈 Improving! +${trend.toFixed(1)} avg rating` :
                 trend < 0 ? `📉 Slight dip — reflect and refocus` :
                 '➡️ Consistent performance'}
              </div>
            );
          })()}
        </div>
      )}

      {/* Monthly Activity */}
      {months.length > 0 && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
          <h3 className="font-semibold text-gray-700 text-sm mb-3 flex items-center gap-2">
            <Calendar className="w-4 h-4 text-gray-500" /> Monthly Activity
          </h3>
          <div className="flex items-end gap-2 h-16">
            {months.map(([month, count]) => {
              const maxCount = Math.max(...months.map(([, c]) => c));
              const height = maxCount > 0 ? (count / maxCount) * 100 : 0;
              return (
                <div key={month} className="flex-1 flex flex-col items-center gap-1">
                  <span className="text-xs text-gray-600 font-semibold">{count}</span>
                  <div
                    className="w-full rounded-t-lg bg-gradient-to-t from-pickle-500 to-pickle-300"
                    style={{ height: `${height}%`, minHeight: '4px' }}
                  />
                  <span className="text-xs text-gray-400">{month.split(' ')[0]}</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Top Skills Practiced */}
      {topSkills.length > 0 && (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
          <h3 className="font-semibold text-gray-700 text-sm mb-3 flex items-center gap-2">
            <Zap className="w-4 h-4 text-gray-500" /> Top Skills You're Working On
          </h3>
          <div className="space-y-2">
            {topSkills.map(([skill, count]) => {
              const maxCount = topSkills[0][1];
              const pct = Math.round((count / maxCount) * 100);
              return (
                <div key={skill}>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-gray-700 font-medium">{skill}</span>
                    <span className="text-gray-400">{count}x</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-pickle-400 to-pickle-600 rounded-full transition-all"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
          <p className="text-xs text-gray-400 mt-3">Based on your intentions and journal entries</p>
        </div>
      )}

      {/* Achievements */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
        <h3 className="font-semibold text-gray-700 text-sm mb-3 flex items-center gap-2">
          <Award className="w-4 h-4 text-gray-500" /> Achievements
        </h3>
        <div className="grid grid-cols-4 gap-3">
          {badges.map(badge => (
            <div
              key={badge.id}
              className={`flex flex-col items-center text-center p-2 rounded-xl transition-all
                ${badge.earned ? 'opacity-100' : 'opacity-30 grayscale'}`}
            >
              <div className={`text-2xl mb-1 ${badge.earned ? 'animate-bounce-slow' : ''}`}>
                {badge.emoji}
              </div>
              <span className="text-xs font-semibold text-gray-700 leading-tight">{badge.label}</span>
              {badge.earned && (
                <span className="text-xs text-pickle-600 mt-0.5">✓ Earned</span>
              )}
            </div>
          ))}
        </div>
        <p className="text-xs text-gray-400 text-center mt-3">
          {badges.filter(b => b.earned).length}/{badges.length} badges earned
        </p>
      </div>

      {/* Insights */}
      <div className="bg-gradient-to-br from-pickle-50 to-pickle-100 border border-pickle-200 rounded-2xl p-4">
        <h3 className="font-bold text-pickle-800 text-sm mb-3">💡 Your Personalized Insights</h3>
        <div className="space-y-2">
          {winRate < 40 && <Insight text="Your win rate is building — focus on consistency over aggression. Set clear intentions before each game." />}
          {winRate >= 40 && winRate < 60 && <Insight text="Solid win rate! Push to 60%+ by working on your weakest shot — check your journals to identify it." />}
          {winRate >= 60 && <Insight text="Exceptional win rate! Time to seek tougher competition to keep growing." />}
          {totalGames < 5 && <Insight text="Early in your journey — log every session with detailed notes. Patterns will emerge quickly." />}
          {topSkills.length > 0 && <Insight text={`You keep working on "${topSkills[0][0]}" — great focus! Targeted practice beats general hitting sessions every time.`} />}
          {intentions.length === 0 && <Insight text="Start setting pre-game intentions! Players who set intentions before games improve measurably faster." />}
          {parseFloat(avgRating) >= 4 && <Insight text="Your self-ratings are high — you're playing with confidence. Stay consistent!" />}
        </div>
      </div>
    </div>
  );
}

function MiniStat({ label, value, sub, color, bg }) {
  return (
    <div className={`${bg} rounded-2xl p-3 text-center`}>
      <div className={`text-xl font-bold ${color}`}>{value}</div>
      <div className="text-xs text-gray-600 font-semibold">{label}</div>
      <div className="text-xs text-gray-400">{sub}</div>
    </div>
  );
}

function Insight({ text }) {
  return (
    <div className="flex gap-2 items-start">
      <span className="text-pickle-500 mt-0.5">→</span>
      <p className="text-sm text-pickle-800">{text}</p>
    </div>
  );
}
