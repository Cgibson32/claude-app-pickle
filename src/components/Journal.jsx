import { useState } from 'react';
import { Save, Star, PlusCircle, ChevronDown, Trash2, BookOpen } from 'lucide-react';
import { gameTypes } from '../data/intentionTemplates';

const resultOptions = [
  { value: 'win', label: 'Won', emoji: '🏆', color: 'border-green-500 bg-green-50 text-green-700' },
  { value: 'loss', label: 'Lost', emoji: '📉', color: 'border-red-400 bg-red-50 text-red-700' },
  { value: 'neutral', label: 'Practice / Fun', emoji: '🎮', color: 'border-gray-400 bg-gray-50 text-gray-700' },
];

const prompts = [
  "What did I do really well today?",
  "What was my biggest challenge or mistake?",
  "Did I execute my intentions? What happened?",
  "What shot or skill do I want to improve next time?",
  "What did I learn about my opponent(s)?",
  "How was my footwork and movement today?",
  "Rate your mental game — did you stay composed?",
  "What drill or technique will you practice before next time?",
];

export default function Journal({ sessions, onSave, onDelete, todayIntention }) {
  const [view, setView] = useState('log'); // 'log' | 'history'
  const [form, setForm] = useState({
    date: new Date().toISOString().split('T')[0],
    gameType: todayIntention?.gameType || '',
    duration: '',
    score: '',
    result: '',
    rating: 0,
    highlights: '',
    challenges: '',
    notes: '',
    intentionReview: '',
    winStreak: '',
    mood: todayIntention?.mood || '',
  });
  const [submitted, setSubmitted] = useState(false);
  const [activePrompt, setActivePrompt] = useState(null);
  const [deleteConfirm, setDeleteConfirm] = useState(null);

  const handleStarClick = (rating) => setForm(prev => ({ ...prev, rating }));

  const handleSubmit = () => {
    if (!form.highlights && !form.notes) return;
    const entry = { ...form, id: Date.now() };
    onSave(entry);
    setSubmitted(true);
  };

  const handleNew = () => {
    setForm({
      date: new Date().toISOString().split('T')[0],
      gameType: '',
      duration: '',
      score: '',
      result: '',
      rating: 0,
      highlights: '',
      challenges: '',
      notes: '',
      intentionReview: '',
      mood: '',
    });
    setSubmitted(false);
    setView('log');
  };

  const sorted = [...sessions].sort((a, b) => new Date(b.date) - new Date(a.date));

  if (view === 'history') {
    return (
      <div className="animate-fade-in space-y-4 pb-8">
        <div className="flex items-center gap-3">
          <button
            onClick={() => setView('log')}
            className="text-pickle-600 font-semibold text-sm"
          >← Back</button>
          <h2 className="font-bold text-gray-800 text-lg">Session History</h2>
        </div>

        {sorted.length === 0 && (
          <div className="text-center py-12 text-gray-400">
            <BookOpen className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>No sessions logged yet.<br />Play your first game and journal it!</p>
          </div>
        )}

        {sorted.map(session => (
          <HistoryCard
            key={session.id}
            session={session}
            onDelete={() => setDeleteConfirm(session.id)}
            confirmDelete={deleteConfirm === session.id}
            onConfirmDelete={() => { onDelete(session.id); setDeleteConfirm(null); }}
            onCancelDelete={() => setDeleteConfirm(null)}
          />
        ))}
      </div>
    );
  }

  if (submitted) {
    return (
      <div className="animate-fade-in space-y-6 pb-8 text-center">
        <div className="py-8">
          <div className="text-6xl mb-4">📓</div>
          <h2 className="text-xl font-bold text-gray-800 mb-2">Session Logged!</h2>
          <p className="text-gray-500 text-sm">Great work reflecting on your game. Every journal entry brings you closer to the next level.</p>
        </div>
        <div className="space-y-3">
          <button
            onClick={handleNew}
            className="w-full bg-pickle-500 text-white font-bold py-3.5 rounded-2xl shadow-md active:scale-95 transition-transform"
          >
            Log Another Session
          </button>
          <button
            onClick={() => { setView('history'); setSubmitted(false); }}
            className="w-full border-2 border-gray-200 text-gray-600 font-semibold py-3 rounded-2xl text-sm"
          >
            View Session History
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="animate-fade-in space-y-5 pb-8">
      <div className="bg-gradient-to-br from-pickle-500 to-pickle-700 rounded-3xl p-5 text-white shadow-xl">
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <BookOpen className="w-5 h-5" />
              <h2 className="font-bold text-lg">Game Journal</h2>
            </div>
            <p className="text-pickle-100 text-sm">Reflect on your game — champions review to improve.</p>
          </div>
          {sessions.length > 0 && (
            <button
              onClick={() => setView('history')}
              className="bg-white/20 text-white text-xs font-semibold px-3 py-1.5 rounded-full"
            >
              History ({sessions.length})
            </button>
          )}
        </div>
      </div>

      {/* Intention Review (if today's intentions were set) */}
      {todayIntention && (
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4">
          <p className="text-blue-700 text-xs font-semibold uppercase tracking-wider mb-2">Today's Intention Recap</p>
          {todayIntention.focus && <p className="text-blue-800 text-sm">🎯 Focus: {todayIntention.focus}</p>}
          {todayIntention.avoid && <p className="text-blue-800 text-sm">🚫 Avoid: {todayIntention.avoid}</p>}
        </div>
      )}

      {/* Game Details */}
      <Section title="Game Details" icon="📋">
        <div className="grid grid-cols-2 gap-3 mb-3">
          <div>
            <label className="text-xs font-medium text-gray-500 mb-1 block">Date</label>
            <input
              type="date"
              value={form.date}
              onChange={e => setForm(prev => ({ ...prev, date: e.target.value }))}
              className="w-full border-2 border-gray-200 rounded-xl px-3 py-2.5 text-sm text-gray-700 focus:border-pickle-400 focus:outline-none"
            />
          </div>
          <div>
            <label className="text-xs font-medium text-gray-500 mb-1 block">Duration (min)</label>
            <input
              type="number"
              placeholder="60"
              value={form.duration}
              onChange={e => setForm(prev => ({ ...prev, duration: e.target.value }))}
              className="w-full border-2 border-gray-200 rounded-xl px-3 py-2.5 text-sm text-gray-700 focus:border-pickle-400 focus:outline-none"
            />
          </div>
        </div>

        <div className="mb-3">
          <label className="text-xs font-medium text-gray-500 mb-1 block">Game Type</label>
          <div className="relative">
            <select
              value={form.gameType}
              onChange={e => setForm(prev => ({ ...prev, gameType: e.target.value }))}
              className="w-full appearance-none bg-white border-2 border-gray-200 rounded-xl px-4 py-2.5 text-sm text-gray-700 pr-8 focus:border-pickle-400 focus:outline-none"
            >
              <option value="">Select game type...</option>
              {gameTypes.map(t => <option key={t} value={t}>{t}</option>)}
            </select>
            <ChevronDown className="absolute right-3 top-3 w-4 h-4 text-gray-400 pointer-events-none" />
          </div>
        </div>

        <div>
          <label className="text-xs font-medium text-gray-500 mb-1 block">Score (optional)</label>
          <input
            placeholder="e.g., 11-7, 11-9"
            value={form.score}
            onChange={e => setForm(prev => ({ ...prev, score: e.target.value }))}
            className="w-full border-2 border-gray-200 rounded-xl px-3 py-2.5 text-sm text-gray-700 focus:border-pickle-400 focus:outline-none"
          />
        </div>
      </Section>

      {/* Result */}
      <Section title="Result" icon="🏆">
        <div className="grid grid-cols-3 gap-2">
          {resultOptions.map(opt => (
            <button
              key={opt.value}
              onClick={() => setForm(prev => ({ ...prev, result: opt.value }))}
              className={`flex flex-col items-center p-3 rounded-xl border-2 transition-all
                ${form.result === opt.value ? opt.color : 'border-gray-200 bg-white text-gray-500'}`}
            >
              <span className="text-xl mb-1">{opt.emoji}</span>
              <span className="text-xs font-semibold">{opt.label}</span>
            </button>
          ))}
        </div>
      </Section>

      {/* Self Rating */}
      <Section title="Rate Your Performance" icon="⭐">
        <div className="flex items-center gap-1 justify-center py-2">
          {[1, 2, 3, 4, 5].map(i => (
            <button
              key={i}
              onClick={() => handleStarClick(i)}
              className="p-1 active:scale-125 transition-transform"
            >
              <Star className={`w-8 h-8 ${i <= form.rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}`} />
            </button>
          ))}
        </div>
        {form.rating > 0 && (
          <p className="text-center text-sm text-gray-500">
            {form.rating === 1 ? 'Rough day — but you showed up!' :
             form.rating === 2 ? 'Struggled, but there were moments.' :
             form.rating === 3 ? 'Decent session — room to grow.' :
             form.rating === 4 ? 'Solid game — execution was sharp!' :
             'You were on fire! Peak performance! 🔥'}
          </p>
        )}
      </Section>

      {/* Reflection Prompts */}
      <Section title="Reflection Journal" icon="📝">
        <p className="text-xs text-gray-400 mb-3">Use these prompts or write freely — honest reflection is your fastest path to improvement.</p>
        <div className="flex flex-wrap gap-2 mb-3">
          {prompts.slice(0, 4).map((p, i) => (
            <button
              key={i}
              onClick={() => {
                setActivePrompt(p);
                setForm(prev => ({
                  ...prev,
                  notes: prev.notes ? `${prev.notes}\n\n${p}\n` : `${p}\n`
                }));
              }}
              className="bg-pickle-50 border border-pickle-200 text-pickle-700 text-xs px-3 py-1.5 rounded-full font-medium"
            >
              + {p.substring(0, 28)}...
            </button>
          ))}
        </div>

        <div className="space-y-3">
          <textarea
            placeholder="✨ Highlights — What went well? Any key moments?"
            value={form.highlights}
            onChange={e => setForm(prev => ({ ...prev, highlights: e.target.value }))}
            rows={3}
            className="w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700 focus:border-pickle-400 focus:outline-none resize-none"
          />
          <textarea
            placeholder="🔧 Challenges — What needs work? Any patterns you noticed?"
            value={form.challenges}
            onChange={e => setForm(prev => ({ ...prev, challenges: e.target.value }))}
            rows={3}
            className="w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700 focus:border-pickle-400 focus:outline-none resize-none"
          />
          <textarea
            placeholder="📋 More notes, stats, opponent observations..."
            value={form.notes}
            onChange={e => setForm(prev => ({ ...prev, notes: e.target.value }))}
            rows={3}
            className="w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700 focus:border-pickle-400 focus:outline-none resize-none"
          />
        </div>
      </Section>

      {/* Intention Review */}
      {todayIntention && (
        <Section title="Did you execute your intentions?" icon="🎯">
          <textarea
            placeholder="Reflect on your pre-game intentions. What worked? What didn't?"
            value={form.intentionReview}
            onChange={e => setForm(prev => ({ ...prev, intentionReview: e.target.value }))}
            rows={3}
            className="w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm text-gray-700 focus:border-pickle-400 focus:outline-none resize-none"
          />
        </Section>
      )}

      <button
        onClick={handleSubmit}
        disabled={!form.highlights && !form.notes && !form.challenges}
        className="w-full bg-gradient-to-r from-pickle-500 to-pickle-600 text-white font-bold py-4 rounded-2xl text-base shadow-lg flex items-center justify-center gap-2 active:scale-95 transition-all disabled:opacity-40 disabled:scale-100"
      >
        <Save className="w-5 h-5" /> Save Journal Entry
      </button>
    </div>
  );
}

function Section({ title, icon, children }) {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
      <h3 className="font-semibold text-gray-700 text-sm mb-3 flex items-center gap-2">
        <span>{icon}</span> {title}
      </h3>
      {children}
    </div>
  );
}

function HistoryCard({ session, onDelete, confirmDelete, onConfirmDelete, onCancelDelete }) {
  const [expanded, setExpanded] = useState(false);
  const dateStr = new Date(session.date).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
  const resultBadge = {
    win: 'bg-green-100 text-green-700',
    loss: 'bg-red-100 text-red-700',
    neutral: 'bg-gray-100 text-gray-600',
  };

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div
        className="flex items-center gap-3 p-4 cursor-pointer"
        onClick={() => setExpanded(!expanded)}
      >
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <span className="font-semibold text-gray-800 text-sm">{session.gameType || 'Session'}</span>
            {session.result && (
              <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${resultBadge[session.result] || resultBadge.neutral}`}>
                {session.result.toUpperCase()}
              </span>
            )}
          </div>
          <div className="text-xs text-gray-400 flex items-center gap-2">
            <span>{dateStr}</span>
            {session.duration && <span>· {session.duration} min</span>}
            {session.score && <span>· {session.score}</span>}
          </div>
        </div>
        <div className="flex items-center gap-2">
          {session.rating > 0 && (
            <div className="flex">
              {[1,2,3,4,5].map(i => (
                <Star key={i} className={`w-3 h-3 ${i <= session.rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-200'}`} />
              ))}
            </div>
          )}
          <ChevronDown className={`w-4 h-4 text-gray-400 transition-transform ${expanded ? 'rotate-180' : ''}`} />
        </div>
      </div>

      {expanded && (
        <div className="px-4 pb-4 border-t border-gray-50 pt-3 space-y-3">
          {session.highlights && (
            <div>
              <p className="text-xs font-semibold text-green-600 uppercase tracking-wider mb-1">✨ Highlights</p>
              <p className="text-sm text-gray-600">{session.highlights}</p>
            </div>
          )}
          {session.challenges && (
            <div>
              <p className="text-xs font-semibold text-red-500 uppercase tracking-wider mb-1">🔧 Challenges</p>
              <p className="text-sm text-gray-600">{session.challenges}</p>
            </div>
          )}
          {session.notes && (
            <div>
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-1">📋 Notes</p>
              <p className="text-sm text-gray-600 whitespace-pre-line">{session.notes}</p>
            </div>
          )}
          {session.intentionReview && (
            <div>
              <p className="text-xs font-semibold text-blue-500 uppercase tracking-wider mb-1">🎯 Intention Review</p>
              <p className="text-sm text-gray-600">{session.intentionReview}</p>
            </div>
          )}
          {!confirmDelete ? (
            <button onClick={onDelete} className="text-red-400 text-xs flex items-center gap-1 mt-2">
              <Trash2 className="w-3 h-3" /> Delete entry
            </button>
          ) : (
            <div className="flex gap-2 mt-2">
              <button onClick={onConfirmDelete} className="bg-red-500 text-white text-xs px-3 py-1.5 rounded-lg font-semibold">Confirm Delete</button>
              <button onClick={onCancelDelete} className="bg-gray-100 text-gray-600 text-xs px-3 py-1.5 rounded-lg font-semibold">Cancel</button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
