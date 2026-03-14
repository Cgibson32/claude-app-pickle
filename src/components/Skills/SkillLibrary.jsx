import { useState } from 'react';
import { ChevronRight, Search, X } from 'lucide-react';
import { SKILL_CATEGORIES } from '../../data/skillsData';

export default function SkillLibrary({ onSelectSkill, savedSkills = [] }) {
  const [search, setSearch] = useState('');

  const filtered = SKILL_CATEGORIES.filter(s =>
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    s.tagline.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div style={{ padding: '20px 20px 100px' }} className="animate-fade-in">
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Library</div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', marginBottom: 8 }}>
          Skill Library
        </h1>
        <p style={{ color: '#666', fontSize: '0.875rem' }}>
          Deep coaching on every area of your game
        </p>
      </div>

      {/* Search */}
      <div style={{
        background: '#141414', border: '1px solid #2a2a2a', borderRadius: 14,
        padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 10, marginBottom: 24,
      }}>
        <Search size={16} color="#555" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search skills..."
          style={{
            background: 'none', border: 'none', color: '#f5f5f5', fontSize: '0.9rem',
            flex: 1, outline: 'none',
          }}
        />
        {search && (
          <button onClick={() => setSearch('')} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
            <X size={14} color="#555" />
          </button>
        )}
      </div>

      {/* Grid */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {filtered.map(skill => (
          <SkillCard
            key={skill.id}
            skill={skill}
            isSaved={savedSkills.includes(skill.id)}
            onClick={() => onSelectSkill(skill.id)}
          />
        ))}
      </div>

      {filtered.length === 0 && (
        <div style={{ textAlign: 'center', padding: '60px 0', color: '#555' }}>
          <div style={{ fontSize: '1rem', marginBottom: 12, color: '#555' }}>No results</div>
          <p>No skills match your search</p>
        </div>
      )}
    </div>
  );
}

function SkillCard({ skill, onClick }) {
  return (
    <button
      onClick={onClick}
      className="press-scale"
      style={{
        background: '#141414', border: '1px solid #2a2a2a', borderRadius: 20,
        padding: '18px', textAlign: 'left', cursor: 'pointer', width: '100%',
        transition: 'all 0.2s',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
        {/* Icon */}
        <div style={{
          width: 52, height: 52, borderRadius: 16, flexShrink: 0,
          background: `${skill.colorDim}`,
          border: `1px solid ${skill.color}30`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 800, color: skill.color, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            {skill.name.slice(0, 3)}
          </span>
        </div>

        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
            <h3 style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.95rem', margin: 0 }}>{skill.name}</h3>
            <span style={{
              background: `${skill.color}15`, color: skill.color,
              borderRadius: 20, padding: '2px 8px', fontSize: '0.65rem', fontWeight: 700,
              border: `1px solid ${skill.color}25`,
            }}>
              {skill.level}
            </span>
          </div>
          <p style={{ color: '#666', fontSize: '0.8rem', fontStyle: 'italic', margin: '0 0 8px' }}>
            {skill.tagline}
          </p>
          <p style={{ color: '#a0a0a0', fontSize: '0.8rem', lineHeight: 1.5, margin: 0 }}>
            {skill.description.slice(0, 90)}...
          </p>
        </div>

        <ChevronRight size={16} color="#444" style={{ flexShrink: 0, marginTop: 4 }} />
      </div>

      {/* Tags */}
      <div style={{ display: 'flex', gap: 6, marginTop: 14, flexWrap: 'wrap' }}>
        {skill.tips.slice(0, 2).map((tip, i) => (
          <span key={i} style={{
            background: '#1e1e1e', border: '1px solid #333', color: '#666',
            borderRadius: 20, padding: '3px 10px', fontSize: '0.7rem',
          }}>
            {tip.slice(0, 30)}{tip.length > 30 ? '...' : ''}
          </span>
        ))}
      </div>
    </button>
  );
}
