import { useState } from 'react';
import { Target, CheckCircle2, ChevronDown, Sparkles } from 'lucide-react';
import { intentionTemplates, moodOptions, gameTypes, skillFocusOptions } from '../data/intentionTemplates';

export default function Intentions({ onSave, todayIntention }) {
  const [form, setForm] = useState(todayIntention || {
    focus: '',
    avoid: '',
    energy: '',
    partner: '',
    mood: '',
    gameType: '',
    skillFocus: [],
    affirmation: '',
  });
  const [saved, setSaved] = useState(!!todayIntention);
  const [showAffirmations, setShowAffirmations] = useState(false);

  const affirmations = [
    "I play with soft hands and a clear mind.",
    "Every shot is a new opportunity — I let go of the last one.",
    "I move with purpose and confidence on this court.",
    "I trust my preparation and enjoy every rally.",
    "I communicate openly with my partner and we play as one.",
    "I'm patient in the dink rally and decisive on my attack.",
    "I welcome the tough moments — they make me sharper.",
    "I play to learn and grow, not just to win.",
  ];

  const handleSkillToggle = (skill) => {
    setForm(prev => ({
      ...prev,
      skillFocus: prev.skillFocus.includes(skill)
        ? prev.skillFocus.filter(s => s !== skill)
        : prev.skillFocus.length < 3
          ? [...prev.skillFocus, skill]
          : prev.skillFocus,
    }));
  };

  const handleSave = () => {
    if (!form.focus && !form.mood) return;
    onSave({ ...form, date: new Date().toISOString(), id: Date.now() });
    setSaved(true);
  };

  const handleEdit = () => setSaved(false);

  if (saved) {
    return (
      <div className="animate-fade-in space-y-6 pb-8">
        <div className="text-center py-8">
          <div className="w-20 h-20 bg-pickle-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <CheckCircle2 className="w-10 h-10 text-pickle-600" />
          </div>
          <h2 className="text-xl font-bold text-gray-800 mb-1">Intentions Set! 🎯</h2>
          <p className="text-gray-500 text-sm">You're mentally ready to play. Now go dominate the court.</p>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 space-y-4">
          <h3 className="font-bold text-gray-700 text-sm uppercase tracking-wider">Today's Game Plan</h3>
          {form.mood && (
            <Row label="Mindset" value={`${moodOptions.find(m => m.value === form.mood)?.emoji} ${moodOptions.find(m => m.value === form.mood)?.label}`} />
          )}
          {form.gameType && <Row label="Game Type" value={form.gameType} />}
          {form.skillFocus.length > 0 && <Row label="Skill Focus" value={form.skillFocus.join(' · ')} />}
          {form.focus && <Row label="Focus On" value={form.focus} />}
          {form.avoid && <Row label="Avoid" value={form.avoid} />}
          {form.energy && <Row label="Energy" value={form.energy} />}
          {form.partner && <Row label="Partner" value={form.partner} />}
          {form.affirmation && (
            <div className="bg-pickle-50 rounded-xl p-3 border border-pickle-200">
              <p className="text-pickle-700 text-sm italic">"{form.affirmation}"</p>
            </div>
          )}
        </div>

        <button
          onClick={handleEdit}
          className="w-full border-2 border-pickle-400 text-pickle-700 font-semibold py-3 rounded-2xl text-sm active:scale-95 transition-transform"
        >
          Edit Intentions
        </button>
      </div>
    );
  }

  return (
    <div className="animate-fade-in space-y-5 pb-8">
      <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-3xl p-5 text-white shadow-xl">
        <div className="flex items-center gap-2 mb-2">
          <Target className="w-5 h-5" />
          <h2 className="font-bold text-lg">Pre-Game Intentions</h2>
        </div>
        <p className="text-blue-100 text-sm">Set your mental game before stepping on the court. Players who set intentions improve 3x faster.</p>
      </div>

      {/* Mood */}
      <Section title="How are you feeling today?" icon="🌡️">
        <div className="grid grid-cols-3 gap-2">
          {moodOptions.map(mood => (
            <button
              key={mood.value}
              onClick={() => setForm(prev => ({ ...prev, mood: mood.value }))}
              className={`flex flex-col items-center p-3 rounded-xl border-2 transition-all text-sm
                ${form.mood === mood.value
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-200 bg-white text-gray-600'}`}
            >
              <span className="text-xl mb-1">{mood.emoji}</span>
              <span className="font-medium text-xs">{mood.label}</span>
            </button>
          ))}
        </div>
      </Section>

      {/* Game Type */}
      <Section title="What type of game?" icon="🏟️">
        <div className="relative">
          <select
            value={form.gameType}
            onChange={e => setForm(prev => ({ ...prev, gameType: e.target.value }))}
            className="w-full appearance-none bg-white border-2 border-gray-200 rounded-xl px-4 py-3 text-gray-700 text-sm pr-10 focus:border-blue-400 focus:outline-none"
          >
            <option value="">Select game type...</option>
            {gameTypes.map(t => <option key={t} value={t}>{t}</option>)}
          </select>
          <ChevronDown className="absolute right-3 top-3.5 w-4 h-4 text-gray-400 pointer-events-none" />
        </div>
      </Section>

      {/* Skill Focus */}
      <Section title="Skill focus (pick up to 3)" icon="🎯">
        <div className="flex flex-wrap gap-2">
          {skillFocusOptions.map(skill => (
            <button
              key={skill}
              onClick={() => handleSkillToggle(skill)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium border-2 transition-all
                ${form.skillFocus.includes(skill)
                  ? 'border-blue-500 bg-blue-500 text-white'
                  : 'border-gray-200 bg-white text-gray-600'}`}
            >
              {skill}
            </button>
          ))}
        </div>
        {form.skillFocus.length === 3 && (
          <p className="text-xs text-blue-600 mt-2">Max 3 skills selected — focus is your superpower!</p>
        )}
      </Section>

      {/* Intention Templates */}
      {intentionTemplates.map(template => (
        <Section key={template.id} title={template.label} icon="✍️">
          <textarea
            value={form[template.id]}
            onChange={e => setForm(prev => ({ ...prev, [template.id]: e.target.value }))}
            placeholder={template.placeholder}
            rows={2}
            className="w-full bg-white border-2 border-gray-200 rounded-xl px-4 py-3 text-gray-700 text-sm focus:border-blue-400 focus:outline-none resize-none"
          />
        </Section>
      ))}

      {/* Affirmation */}
      <Section title="Choose your affirmation" icon="✨">
        <button
          onClick={() => setShowAffirmations(!showAffirmations)}
          className="w-full text-left bg-blue-50 border-2 border-blue-200 rounded-xl px-4 py-3 text-blue-700 text-sm font-medium flex items-center gap-2 mb-3"
        >
          <Sparkles className="w-4 h-4" />
          {form.affirmation ? `"${form.affirmation.substring(0, 40)}..."` : 'Pick a power statement'}
          <ChevronDown className={`ml-auto w-4 h-4 transition-transform ${showAffirmations ? 'rotate-180' : ''}`} />
        </button>
        {showAffirmations && (
          <div className="space-y-2">
            {affirmations.map((a, i) => (
              <button
                key={i}
                onClick={() => { setForm(prev => ({ ...prev, affirmation: a })); setShowAffirmations(false); }}
                className={`w-full text-left px-4 py-3 rounded-xl text-sm border-2 transition-all
                  ${form.affirmation === a
                    ? 'border-blue-500 bg-blue-50 text-blue-700 font-medium'
                    : 'border-gray-100 bg-white text-gray-600'}`}
              >
                "{a}"
              </button>
            ))}
          </div>
        )}
      </Section>

      <button
        onClick={handleSave}
        disabled={!form.focus && !form.mood}
        className="w-full bg-gradient-to-r from-blue-500 to-blue-600 text-white font-bold py-4 rounded-2xl text-base shadow-lg active:scale-95 transition-all disabled:opacity-40 disabled:scale-100"
      >
        Lock In My Intentions 🎯
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

function Row({ label, value }) {
  return (
    <div className="flex gap-3">
      <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider w-20 pt-0.5 shrink-0">{label}</span>
      <span className="text-sm text-gray-700">{value}</span>
    </div>
  );
}
