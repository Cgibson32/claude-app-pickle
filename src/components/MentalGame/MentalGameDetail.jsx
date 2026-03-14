import { useState } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { getMentalCategoryById } from '../../data/mentalGameData';

export default function MentalGameDetail({ categoryId, onBack }) {
  const category = getMentalCategoryById(categoryId);
  const [activeLesson, setActiveLesson] = useState(0);

  if (!category) return null;

  const lesson = category.lessons[activeLesson];

  return (
    <div style={{ paddingBottom: 100 }} className="animate-slide-up">
      {/* Back bar */}
      <div style={{
        background: '#0a0a0a', padding: '16px 20px',
        borderBottom: '1px solid #2a2a2a', position: 'sticky', top: 0, zIndex: 10,
      }}>
        <button onClick={onBack} className="press-scale" style={{
          background: '#1e1e1e', border: '1px solid #333', borderRadius: 12,
          padding: '8px 14px', display: 'flex', alignItems: 'center', gap: 6,
          color: '#a0a0a0', fontSize: '0.85rem', fontWeight: 600, cursor: 'pointer',
        }}>
          <ChevronLeft size={16} /> Mental Game
        </button>
      </div>

      <div style={{ padding: '24px 20px' }}>
        {/* Title */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
          <div style={{
            width: 60, height: 60, borderRadius: 18,
            background: category.colorDim, border: `1px solid ${category.color}30`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '1.75rem', flexShrink: 0,
          }}>
            {category.emoji}
          </div>
          <div>
            <h1 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.4rem', margin: '0 0 4px' }}>
              {category.name}
            </h1>
            <p style={{ color: category.color, fontSize: '0.85rem', fontStyle: 'italic', margin: 0 }}>
              {category.tagline}
            </p>
          </div>
        </div>

        {/* Intro */}
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18,
          padding: '18px', marginBottom: 24,
        }}>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.7, margin: 0 }}>
            {category.intro}
          </p>
        </div>

        {/* Lesson Tabs */}
        <div className="label-xs" style={{ color: '#555', marginBottom: 12 }}>
          Lessons ({activeLesson + 1} of {category.lessons.length})
        </div>
        <div style={{ display: 'flex', gap: 6, marginBottom: 20, overflowX: 'auto', paddingBottom: 4 }}>
          {category.lessons.map((l, i) => (
            <button
              key={i}
              onClick={() => setActiveLesson(i)}
              style={{
                background: activeLesson === i ? `${category.color}15` : '#141414',
                border: activeLesson === i ? `1.5px solid ${category.color}50` : '1px solid #2a2a2a',
                color: activeLesson === i ? category.color : '#555',
                borderRadius: 20, padding: '6px 14px', fontSize: '0.75rem', fontWeight: 600,
                cursor: 'pointer', whiteSpace: 'nowrap', flexShrink: 0,
                transition: 'all 0.2s',
              }}
            >
              {i + 1}. {l.title.slice(0, 20)}{l.title.length > 20 ? '…' : ''}
            </button>
          ))}
        </div>

        {/* Active Lesson */}
        <div key={activeLesson} className="animate-scale-in" style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 22, overflow: 'hidden', marginBottom: 16,
        }}>
          <div style={{
            background: `${category.color}10`, borderBottom: `1px solid ${category.color}20`,
            padding: '18px 20px',
          }}>
            <div className="label-xs" style={{ color: category.color, marginBottom: 6 }}>
              Lesson {activeLesson + 1}
            </div>
            <h2 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.1rem', margin: 0, lineHeight: 1.3 }}>
              {lesson.title}
            </h2>
          </div>
          <div style={{ padding: '18px 20px' }}>
            <p style={{ color: '#c0c0c0', fontSize: '0.9rem', lineHeight: 1.75, margin: '0 0 20px' }}>
              {lesson.content}
            </p>
            <div style={{
              borderLeft: `3px solid ${category.color}`, paddingLeft: 16,
              fontStyle: 'italic', color: category.color, fontSize: '0.9rem', fontWeight: 600,
            }}>
              {lesson.quote}
            </div>
          </div>
        </div>

        {/* Lesson Nav */}
        <div style={{ display: 'flex', gap: 10, marginBottom: 28 }}>
          {activeLesson > 0 && (
            <button
              onClick={() => setActiveLesson(l => l - 1)}
              className="press-scale"
              style={{
                flex: 1, background: '#141414', border: '1px solid #2a2a2a', borderRadius: 14,
                padding: '14px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                color: '#a0a0a0', fontWeight: 600, fontSize: '0.85rem', cursor: 'pointer',
              }}
            >
              <ChevronLeft size={16} /> Previous
            </button>
          )}
          {activeLesson < category.lessons.length - 1 && (
            <button
              onClick={() => setActiveLesson(l => l + 1)}
              className="press-scale"
              style={{
                flex: 1, background: `${category.color}15`, border: `1px solid ${category.color}30`,
                borderRadius: 14, padding: '14px',
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                color: category.color, fontWeight: 700, fontSize: '0.85rem', cursor: 'pointer',
              }}
            >
              Next Lesson <ChevronRight size={16} />
            </button>
          )}
        </div>

        {/* Practice Prompts */}
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 20, padding: '18px', marginBottom: 16,
        }}>
          <div className="label-xs" style={{ color: '#555', marginBottom: 14 }}>Practice Prompts</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {category.practicePrompts.map((prompt, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                <div style={{
                  width: 22, height: 22, borderRadius: '50%',
                  background: `${category.color}15`, border: `1px solid ${category.color}30`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0, fontSize: '0.7rem', fontWeight: 700, color: category.color,
                }}>
                  {i + 1}
                </div>
                <p style={{ color: '#a0a0a0', fontSize: '0.85rem', lineHeight: 1.6, margin: 0 }}>{prompt}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Affirmations */}
        <div style={{
          background: `${category.color}08`, border: `1px solid ${category.color}20`,
          borderRadius: 20, padding: '18px',
        }}>
          <div className="label-xs" style={{ color: category.color, marginBottom: 14 }}>Daily Affirmations</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {category.affirmations.map((aff, i) => (
              <div key={i} style={{
                background: `${category.color}10`, border: `1px solid ${category.color}20`,
                borderRadius: 12, padding: '12px 14px',
              }}>
                <p style={{ color: '#f5f5f5', fontSize: '0.875rem', fontWeight: 600, margin: 0, lineHeight: 1.5 }}>
                  "{aff}"
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
