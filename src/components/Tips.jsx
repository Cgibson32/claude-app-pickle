import { useState } from 'react';
import { Search, BookOpen, ChevronDown, ChevronUp, Star } from 'lucide-react';
import { tipsData, categories, levels } from '../data/tipsData';

export default function Tips() {
  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [selectedLevel, setSelectedLevel] = useState('All');
  const [expandedId, setExpandedId] = useState(null);
  const [savedTips, setSavedTips] = useState(() => {
    try { return JSON.parse(localStorage.getItem('savedTips') || '[]'); } catch { return []; }
  });
  const [showSaved, setShowSaved] = useState(false);

  const toggleSave = (id) => {
    const updated = savedTips.includes(id)
      ? savedTips.filter(t => t !== id)
      : [...savedTips, id];
    setSavedTips(updated);
    localStorage.setItem('savedTips', JSON.stringify(updated));
  };

  const filtered = tipsData.filter(tip => {
    const matchSearch = !search || tip.title.toLowerCase().includes(search.toLowerCase()) || tip.tip.toLowerCase().includes(search.toLowerCase()) || tip.tag.toLowerCase().includes(search.toLowerCase());
    const matchCat = selectedCategory === 'All' || tip.category === selectedCategory;
    const matchLevel = selectedLevel === 'All' || tip.level === selectedLevel;
    const matchSaved = !showSaved || savedTips.includes(tip.id);
    return matchSearch && matchCat && matchLevel && matchSaved;
  });

  const levelColors = {
    Beginner: 'bg-green-100 text-green-700 border-green-200',
    Intermediate: 'bg-yellow-100 text-yellow-700 border-yellow-200',
    Advanced: 'bg-red-100 text-red-700 border-red-200',
  };

  const categoryIcons = {
    Serve: '🎾',
    Dinking: '🤲',
    'Third Shot': '🪂',
    Movement: '🦘',
    'Mental Game': '🧠',
    Strategy: '♟️',
    Volleys: '👊',
    Fitness: '💪',
    Equipment: '🏓',
  };

  return (
    <div className="animate-fade-in space-y-4 pb-8">
      {/* Header */}
      <div className="bg-gradient-to-br from-amber-500 to-orange-500 rounded-3xl p-5 text-white shadow-xl">
        <div className="flex items-center gap-2 mb-1">
          <BookOpen className="w-5 h-5" />
          <h2 className="font-bold text-lg">Tips & Tricks</h2>
        </div>
        <p className="text-orange-100 text-sm">{tipsData.length} pro-level tips to level up your game</p>
        <div className="flex gap-2 mt-3">
          {levels.map(l => (
            <span key={l} className="bg-white/20 text-white text-xs px-2 py-1 rounded-full font-medium">{l}</span>
          ))}
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3.5 top-3 w-4 h-4 text-gray-400" />
        <input
          placeholder="Search tips, techniques, strategies..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="w-full bg-white border-2 border-gray-200 rounded-xl pl-10 pr-4 py-2.5 text-sm text-gray-700 focus:border-amber-400 focus:outline-none shadow-sm"
        />
      </div>

      {/* Filters */}
      <div className="space-y-2">
        <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
          {['All', ...categories].map(cat => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`shrink-0 px-3 py-1.5 rounded-full text-xs font-semibold border-2 transition-all
                ${selectedCategory === cat
                  ? 'border-amber-500 bg-amber-500 text-white'
                  : 'border-gray-200 bg-white text-gray-600'}`}
            >
              {cat !== 'All' && categoryIcons[cat]} {cat}
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          {['All', ...levels].map(lvl => (
            <button
              key={lvl}
              onClick={() => setSelectedLevel(lvl)}
              className={`px-3 py-1.5 rounded-full text-xs font-semibold border-2 transition-all
                ${selectedLevel === lvl
                  ? 'border-gray-600 bg-gray-700 text-white'
                  : 'border-gray-200 bg-white text-gray-600'}`}
            >
              {lvl}
            </button>
          ))}
          <button
            onClick={() => setShowSaved(!showSaved)}
            className={`ml-auto px-3 py-1.5 rounded-full text-xs font-semibold border-2 flex items-center gap-1 transition-all
              ${showSaved ? 'border-yellow-400 bg-yellow-400 text-white' : 'border-gray-200 bg-white text-gray-600'}`}
          >
            <Star className="w-3 h-3" /> Saved ({savedTips.length})
          </button>
        </div>
      </div>

      {/* Results count */}
      <p className="text-xs text-gray-400 px-1">
        {filtered.length} tip{filtered.length !== 1 ? 's' : ''} found
      </p>

      {/* Tips List */}
      <div className="space-y-3">
        {filtered.length === 0 && (
          <div className="text-center py-10 text-gray-400">
            <p className="text-4xl mb-3">🔍</p>
            <p>No tips match your filters.<br />Try broadening your search!</p>
          </div>
        )}
        {filtered.map(tip => (
          <TipCard
            key={tip.id}
            tip={tip}
            expanded={expandedId === tip.id}
            onToggle={() => setExpandedId(expandedId === tip.id ? null : tip.id)}
            saved={savedTips.includes(tip.id)}
            onToggleSave={() => toggleSave(tip.id)}
            levelColors={levelColors}
            categoryIcons={categoryIcons}
          />
        ))}
      </div>

      {/* Pro Learning Path */}
      <div className="bg-gradient-to-br from-pickle-50 to-pickle-100 border border-pickle-200 rounded-2xl p-4">
        <h3 className="font-bold text-pickle-800 text-sm mb-2">🎯 Suggested Learning Path</h3>
        <div className="space-y-2">
          {[
            { step: '1', text: 'Master the third shot drop', done: false },
            { step: '2', text: 'Develop consistent cross-court dinks', done: false },
            { step: '3', text: 'Learn the split step movement', done: false },
            { step: '4', text: 'Practice the speed-up from the dink', done: false },
            { step: '5', text: 'Study stacking strategy for doubles', done: false },
          ].map(item => (
            <div key={item.step} className="flex items-center gap-3">
              <div className="w-6 h-6 rounded-full bg-pickle-500 text-white text-xs flex items-center justify-center font-bold shrink-0">
                {item.step}
              </div>
              <span className="text-sm text-pickle-800">{item.text}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function TipCard({ tip, expanded, onToggle, saved, onToggleSave, levelColors, categoryIcons }) {
  return (
    <div className={`bg-white rounded-2xl shadow-sm border-2 overflow-hidden transition-all ${expanded ? 'border-amber-300' : 'border-gray-100'}`}>
      <div className="p-4 cursor-pointer" onClick={onToggle}>
        <div className="flex items-start gap-3">
          <span className="text-2xl shrink-0">{tip.emoji}</span>
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2 mb-1.5">
              <h3 className="font-bold text-gray-800 text-sm leading-tight">{tip.title}</h3>
              <button
                onClick={e => { e.stopPropagation(); onToggleSave(); }}
                className="shrink-0 active:scale-125 transition-transform"
              >
                <Star className={`w-5 h-5 ${saved ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}`} />
              </button>
            </div>
            <div className="flex flex-wrap items-center gap-1.5">
              <span className={`text-xs px-2 py-0.5 rounded-full border font-medium ${levelColors[tip.level]}`}>
                {tip.level}
              </span>
              <span className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                {categoryIcons[tip.category]} {tip.category}
              </span>
              <span className="text-xs bg-amber-50 text-amber-600 px-2 py-0.5 rounded-full">
                #{tip.tag}
              </span>
            </div>
          </div>
        </div>

        {!expanded && (
          <p className="text-xs text-gray-500 mt-2 ml-9 line-clamp-2">{tip.tip}</p>
        )}

        <div className="flex justify-end mt-1">
          {expanded
            ? <ChevronUp className="w-4 h-4 text-gray-400" />
            : <ChevronDown className="w-4 h-4 text-gray-400" />
          }
        </div>
      </div>

      {expanded && (
        <div className="px-4 pb-4 space-y-3 border-t border-gray-50 pt-3">
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1.5">The Tip</p>
            <p className="text-sm text-gray-700 leading-relaxed">{tip.tip}</p>
          </div>
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-3">
            <p className="text-xs font-semibold text-amber-700 uppercase tracking-wider mb-1">⭐ Pro Insight</p>
            <p className="text-sm text-amber-800 leading-relaxed">{tip.proTip}</p>
          </div>
        </div>
      )}
    </div>
  );
}
