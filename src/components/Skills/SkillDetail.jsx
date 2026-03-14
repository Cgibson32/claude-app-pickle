import { useState } from 'react';
import { ChevronLeft, Bookmark, BookmarkCheck, ChevronDown, ChevronUp } from 'lucide-react';
import { getSkillById } from '../../data/skillsData';

export default function SkillDetail({ skillId, onBack, savedSkills = [], onToggleSave }) {
  const skill = getSkillById(skillId);
  const [openSection, setOpenSection] = useState('tips');
  const isSaved = savedSkills.includes(skillId);

  if (!skill) return null;

  const sections = [
    { id: 'tips', label: 'Coaching Tips', content: skill.tips },
    { id: 'mental', label: 'Mental Cues', content: skill.mentalCues },
    { id: 'mistakes', label: 'Common Mistakes', content: skill.commonMistakes },
    { id: 'drills', label: 'Practice Drills', content: skill.drills },
  ];

  return (
    <div style={{ paddingBottom: 100 }} className="animate-slide-up">
      {/* Hero */}
      <div style={{
        background: 'linear-gradient(180deg, #141414 0%, #0a0a0a 100%)',
        padding: '16px 20px 24px', borderBottom: '1px solid #2a2a2a',
        position: 'sticky', top: 0, zIndex: 10,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <button onClick={onBack} className="press-scale" style={{
            background: '#1e1e1e', border: '1px solid #333', borderRadius: 12,
            padding: '8px 14px', display: 'flex', alignItems: 'center', gap: 6,
            color: '#a0a0a0', fontSize: '0.85rem', fontWeight: 600, cursor: 'pointer',
          }}>
            <ChevronLeft size={16} /> Back
          </button>
          <button onClick={() => onToggleSave(skillId)} className="press-scale" style={{
            background: isSaved ? 'rgba(200,241,53,0.1)' : '#1e1e1e',
            border: isSaved ? '1px solid rgba(200,241,53,0.4)' : '1px solid #333',
            borderRadius: 12, padding: '8px 14px', cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            {isSaved
              ? <BookmarkCheck size={16} color="#c8f135" />
              : <Bookmark size={16} color="#666" />
            }
            <span style={{ color: isSaved ? '#c8f135' : '#666', fontSize: '0.8rem', fontWeight: 600 }}>
              {isSaved ? 'Saved' : 'Save'}
            </span>
          </button>
        </div>
      </div>

      {/* Content */}
      <div style={{ padding: '24px 20px' }}>
        {/* Title */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20 }}>
          <div style={{
            width: 64, height: 64, borderRadius: 20,
            background: skill.colorDim, border: `1px solid ${skill.color}30`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <span style={{ fontSize: '0.8rem', fontWeight: 800, color: skill.color, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              {skill.name.slice(0, 3)}
            </span>
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
              <h1 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.4rem', margin: 0 }}>{skill.name}</h1>
            </div>
            <p style={{ color: skill.color, fontSize: '0.85rem', fontStyle: 'italic', fontWeight: 500, margin: 0 }}>
              {skill.tagline}
            </p>
            <span style={{
              background: `${skill.color}15`, color: skill.color, borderRadius: 20,
              padding: '2px 8px', fontSize: '0.65rem', fontWeight: 700, border: `1px solid ${skill.color}25`,
              display: 'inline-block', marginTop: 4,
            }}>
              {skill.level}
            </span>
          </div>
        </div>

        {/* Description */}
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18,
          padding: '18px', marginBottom: 16,
        }}>
          <p style={{ color: '#c0c0c0', fontSize: '0.9rem', lineHeight: 1.7, margin: 0 }}>
            {skill.description}
          </p>
        </div>

        {/* Why it matters */}
        <div style={{
          background: `${skill.color}08`, border: `1px solid ${skill.color}20`,
          borderRadius: 18, padding: '18px', marginBottom: 24,
        }}>
          <div className="label-xs" style={{ color: skill.color, marginBottom: 8 }}>Why This Matters</div>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.7, margin: 0 }}>
            {skill.whyItMatters}
          </p>
        </div>

        {/* Collapsible Sections */}
        {sections.map(section => (
          <CollapsibleSection
            key={section.id}
            label={section.label}
            isOpen={openSection === section.id}
            onToggle={() => setOpenSection(openSection === section.id ? null : section.id)}
            accent={skill.color}
          >
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10, paddingTop: 8 }}>
              {section.content.map((item, i) => (
                <div key={i} style={{
                  display: 'flex', alignItems: 'flex-start', gap: 12,
                  background: '#1e1e1e', border: '1px solid #2a2a2a', borderRadius: 12, padding: '12px 14px',
                }}>
                  <div style={{
                    width: 6, height: 6, borderRadius: '50%', background: skill.color,
                    flexShrink: 0, marginTop: 7,
                  }} />
                  <p style={{ color: '#c0c0c0', fontSize: '0.875rem', lineHeight: 1.6, margin: 0 }}>{item}</p>
                </div>
              ))}
            </div>
          </CollapsibleSection>
        ))}

        {/* Process Philosophy */}
        <div style={{
          background: 'linear-gradient(135deg, #141414, #1a1a0e)',
          border: '1px solid rgba(200,241,53,0.2)', borderRadius: 20,
          padding: '20px', marginTop: 8,
        }}>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 10 }}>Process Philosophy</div>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.7, margin: 0 }}>
            {skill.processPhilosophy}
          </p>
        </div>
      </div>
    </div>
  );
}

function CollapsibleSection({ label, isOpen, onToggle, children }) {
  return (
    <div style={{
      background: '#141414', border: `1px solid ${isOpen ? '#333' : '#2a2a2a'}`,
      borderRadius: 18, overflow: 'hidden', marginBottom: 10, transition: 'all 0.2s',
    }}>
      <button
        onClick={onToggle}
        style={{
          width: '100%', background: 'none', border: 'none', padding: '16px 18px',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          cursor: 'pointer',
        }}
      >
        <span style={{ color: '#f5f5f5', fontWeight: 600, fontSize: '0.9rem' }}>{label}</span>
        {isOpen
          ? <ChevronUp size={16} color="#555" />
          : <ChevronDown size={16} color="#555" />
        }
      </button>
      {isOpen && (
        <div style={{ padding: '0 18px 18px' }}>
          {children}
        </div>
      )}
    </div>
  );
}
