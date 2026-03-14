import { ChevronRight } from 'lucide-react';
import { MENTAL_CATEGORIES } from '../../data/mentalGameData';

export default function MentalGameLibrary({ onSelectCategory }) {
  return (
    <div style={{ padding: '20px 20px 100px' }} className="animate-fade-in">
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <div className="label-xs" style={{ color: '#3b82f6', marginBottom: 8 }}>Mental Performance</div>
        <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em', marginBottom: 8 }}>
          Mental Game
        </h1>
        <p style={{ color: '#666', fontSize: '0.875rem', lineHeight: 1.6 }}>
          The mental side wins or loses most matches. Train your mind like you train your shots.
        </p>
      </div>

      {/* Featured Quote */}
      <div style={{
        background: 'linear-gradient(135deg, #0f0f1a, #141428)',
        border: '1px solid rgba(59,130,246,0.25)', borderRadius: 24,
        padding: '22px', marginBottom: 24,
      }}>
        <div style={{ fontSize: '0.75rem', fontWeight: 800, color: '#3b82f6', letterSpacing: '0.05em', marginBottom: 12 }}>MND</div>
        <p style={{ color: '#f5f5f5', fontSize: '1rem', fontWeight: 700, lineHeight: 1.5, margin: '0 0 8px' }}>
          "Your mindset is part of your shot selection."
        </p>
        <p style={{ color: '#555', fontSize: '0.8rem', margin: 0 }}>
          The mental and technical game are inseparable.
        </p>
      </div>

      {/* Categories */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {MENTAL_CATEGORIES.map(cat => (
          <MentalCard key={cat.id} category={cat} onClick={() => onSelectCategory(cat.id)} />
        ))}
      </div>
    </div>
  );
}

function MentalCard({ category, onClick }) {
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
        <div style={{
          width: 52, height: 52, borderRadius: 16, flexShrink: 0,
          background: category.colorDim, border: `1px solid ${category.color}30`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 800, color: category.color, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            {category.name.slice(0, 3)}
          </span>
        </div>
        <div style={{ flex: 1 }}>
          <h3 style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.95rem', margin: '0 0 4px' }}>
            {category.name}
          </h3>
          <p style={{ color: category.color, fontSize: '0.78rem', fontStyle: 'italic', margin: '0 0 8px', fontWeight: 500 }}>
            {category.tagline}
          </p>
          <p style={{ color: '#666', fontSize: '0.78rem', lineHeight: 1.5, margin: 0 }}>
            {category.intro.slice(0, 80)}...
          </p>
          <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
            {category.lessons.slice(0, 2).map((l, i) => (
              <span key={i} style={{
                background: '#1e1e1e', border: '1px solid #2a2a2a', color: '#555',
                borderRadius: 20, padding: '2px 8px', fontSize: '0.65rem',
              }}>
                {l.title.slice(0, 22)}{l.title.length > 22 ? '…' : ''}
              </span>
            ))}
            <span style={{
              background: '#1e1e1e', border: '1px solid #2a2a2a', color: '#555',
              borderRadius: 20, padding: '2px 8px', fontSize: '0.65rem',
            }}>
              +{category.lessons.length} lessons
            </span>
          </div>
        </div>
        <ChevronRight size={16} color="#444" style={{ flexShrink: 0, marginTop: 4 }} />
      </div>
    </button>
  );
}
