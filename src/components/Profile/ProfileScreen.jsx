import { useState } from 'react';
import { ChevronRight, Edit3, Check, Shield, Bell, Trash2 } from 'lucide-react';
import {
  EXPERIENCE_LEVELS,
  STRUGGLE_OPTIONS,
  MENTAL_WEAKNESSES,
  PLAYER_TYPE_OPTIONS,
} from '../../data/onboardingData';
import { useAppState, useAppActions } from '../../context/AppContext';

export default function ProfileScreen({ onNavigate, onResetOnboarding }) {
  const { profile, sessions } = useAppState();
  const { patchProfile } = useAppActions();
  const [editing, setEditing] = useState(false);
  const [editedProfile, setEditedProfile] = useState(profile || {});
  const [showReset, setShowReset] = useState(false);

  const level = EXPERIENCE_LEVELS.find(l => l.id === profile?.level);
  const playerType = PLAYER_TYPE_OPTIONS.find(t => t.id === profile?.playerType);
  const totalSessions = sessions?.length || 0;

  const handleSave = () => {
    patchProfile(editedProfile);
    setEditing(false);
  };

  const toggleItem = (key, id) => {
    setEditedProfile(p => {
      const arr = p[key] || [];
      return { ...p, [key]: arr.includes(id) ? arr.filter(x => x !== id) : [...arr, id] };
    });
  };

  return (
    <div style={{ padding: '20px 20px 100px' }} className="animate-fade-in">
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <div>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Account</div>
          <h1 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', letterSpacing: '-0.02em' }}>
            My Profile
          </h1>
        </div>
        <button
          onClick={() => editing ? handleSave() : setEditing(true)}
          style={{
            background: editing ? 'rgba(200,241,53,0.1)' : '#141414',
            border: editing ? '1px solid rgba(200,241,53,0.4)' : '1px solid #2a2a2a',
            borderRadius: 12, padding: '8px 14px',
            display: 'flex', alignItems: 'center', gap: 6,
            color: editing ? '#c8f135' : '#a0a0a0', fontSize: '0.8rem', fontWeight: 600,
            cursor: 'pointer',
          }}
        >
          {editing ? <><Check size={14} /> Save</> : <><Edit3 size={14} /> Edit</>}
        </button>
      </div>

      {/* Avatar Card */}
      <div style={{
        background: 'linear-gradient(135deg, #141414, #1a1a0e)',
        border: '1px solid rgba(200,241,53,0.2)', borderRadius: 24,
        padding: '24px', marginBottom: 20, textAlign: 'center',
      }}>
        <div style={{
          width: 72, height: 72, borderRadius: '50%',
          background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          margin: '0 auto 12px', fontSize: '2rem',
          boxShadow: '0 0 20px rgba(200,241,53,0.3)',
        }}>
          🏓
        </div>

        {editing ? (
          <input
            value={editedProfile.name || ''}
            onChange={e => setEditedProfile(p => ({ ...p, name: e.target.value }))}
            style={{
              background: '#1e1e1e', border: '1px solid #333', borderRadius: 10,
              padding: '8px 14px', color: '#f5f5f5', fontSize: '1rem', fontWeight: 700,
              textAlign: 'center', outline: 'none', width: '100%', maxWidth: 200,
            }}
          />
        ) : (
          <h2 style={{ color: '#f5f5f5', fontWeight: 800, fontSize: '1.3rem', margin: '0 0 6px' }}>
            {profile?.name || 'Pickleball Player'}
          </h2>
        )}

        <div style={{ display: 'flex', justifyContent: 'center', gap: 12, marginTop: 12 }}>
          {level && (
            <span style={{
              background: 'rgba(200,241,53,0.1)', border: '1px solid rgba(200,241,53,0.25)',
              color: '#c8f135', borderRadius: 20, padding: '4px 12px', fontSize: '0.75rem', fontWeight: 700,
            }}>
              {level.emoji} {level.label}
            </span>
          )}
          {playerType && (
            <span style={{
              background: 'rgba(168,85,247,0.1)', border: '1px solid rgba(168,85,247,0.25)',
              color: '#a855f7', borderRadius: 20, padding: '4px 12px', fontSize: '0.75rem', fontWeight: 700,
            }}>
              {playerType.emoji} {playerType.label.split(' ').slice(1, 3).join(' ')}
            </span>
          )}
        </div>

        <div style={{ display: 'flex', justifyContent: 'center', gap: 24, marginTop: 16, paddingTop: 16, borderTop: '1px solid #2a2a2a' }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ color: '#c8f135', fontWeight: 900, fontSize: '1.5rem' }}>{totalSessions}</div>
            <div className="label-xs" style={{ color: '#555' }}>Sessions</div>
          </div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ color: '#f97316', fontWeight: 900, fontSize: '1.5rem' }}>
              {sessions?.filter(s => s.wentWell).length || 0}
            </div>
            <div className="label-xs" style={{ color: '#555' }}>Reflections</div>
          </div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ color: '#a855f7', fontWeight: 900, fontSize: '1.5rem' }}>
              {profile?.struggles?.length || 0}
            </div>
            <div className="label-xs" style={{ color: '#555' }}>Focus Areas</div>
          </div>
        </div>
      </div>

      {/* Level & Frequency */}
      {editing ? (
        <>
          <EditSection title="Experience Level">
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {EXPERIENCE_LEVELS.map(l => (
                <ToggleRow
                  key={l.id}
                  label={`${l.emoji} ${l.label}`}
                  sub={l.dupr}
                  selected={editedProfile.level === l.id}
                  onToggle={() => setEditedProfile(p => ({ ...p, level: l.id }))}
                  single
                />
              ))}
            </div>
          </EditSection>

          <EditSection title="Focus Areas (struggles)">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {STRUGGLE_OPTIONS.map(s => (
                <TagToggle
                  key={s.id}
                  label={`${s.emoji} ${s.label}`}
                  selected={(editedProfile.struggles || []).includes(s.id)}
                  onToggle={() => toggleItem('struggles', s.id)}
                />
              ))}
            </div>
          </EditSection>

          <EditSection title="Mental Weaknesses">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {MENTAL_WEAKNESSES.map(m => (
                <TagToggle
                  key={m.id}
                  label={`${m.emoji} ${m.label}`}
                  selected={(editedProfile.mentalWeaknesses || []).includes(m.id)}
                  onToggle={() => toggleItem('mentalWeaknesses', m.id)}
                  color="#3b82f6"
                />
              ))}
            </div>
          </EditSection>
        </>
      ) : (
        <>
          {/* Read-only profile sections */}
          <ProfileSection title="Focus Skills">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {(profile?.struggles || []).map(id => {
                const item = STRUGGLE_OPTIONS.find(s => s.id === id);
                return item ? (
                  <span key={id} style={{
                    background: 'rgba(200,241,53,0.08)', border: '1px solid rgba(200,241,53,0.2)',
                    color: '#c8f135', borderRadius: 20, padding: '4px 12px', fontSize: '0.75rem', fontWeight: 600,
                  }}>
                    {item.emoji} {item.label}
                  </span>
                ) : null;
              })}
              {(!profile?.struggles?.length) && (
                <p style={{ color: '#555', fontSize: '0.8rem' }}>No focus skills set — edit profile to add</p>
              )}
            </div>
          </ProfileSection>

          <ProfileSection title="Mental Priorities">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {(profile?.mentalWeaknesses || []).map(id => {
                const item = MENTAL_WEAKNESSES.find(m => m.id === id);
                return item ? (
                  <span key={id} style={{
                    background: 'rgba(59,130,246,0.08)', border: '1px solid rgba(59,130,246,0.2)',
                    color: '#60a5fa', borderRadius: 20, padding: '4px 12px', fontSize: '0.75rem', fontWeight: 600,
                  }}>
                    {item.emoji} {item.label}
                  </span>
                ) : null;
              })}
              {(!profile?.mentalWeaknesses?.length) && (
                <p style={{ color: '#555', fontSize: '0.8rem' }}>No mental priorities set — edit profile to add</p>
              )}
            </div>
          </ProfileSection>
        </>
      )}

      {/* Settings */}
      <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 20, overflow: 'hidden', marginBottom: 16 }}>
        <div className="label-xs" style={{ color: '#555', padding: '14px 16px 8px' }}>App Settings</div>
        {[
          { icon: <Shield size={16} color="#3b82f6" />, label: 'Subscription', sub: 'Free tier active', onClick: () => onNavigate('paywall') },
          { icon: <Bell size={16} color="#a855f7" />, label: 'Notifications', sub: 'Daily reminders' },
        ].map((item, i) => (
          <button
            key={i}
            onClick={item.onClick}
            style={{
              width: '100%', background: 'none', border: 'none', borderTop: i > 0 ? '1px solid #1e1e1e' : 'none',
              padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer',
            }}
          >
            <div style={{ width: 32, height: 32, borderRadius: 10, background: '#1e1e1e', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {item.icon}
            </div>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div style={{ color: '#f5f5f5', fontSize: '0.875rem', fontWeight: 600 }}>{item.label}</div>
              <div style={{ color: '#555', fontSize: '0.75rem' }}>{item.sub}</div>
            </div>
            <ChevronRight size={14} color="#444" />
          </button>
        ))}
      </div>

      {/* Upgrade CTA */}
      <button
        onClick={() => onNavigate('paywall')}
        className="press-scale"
        style={{
          width: '100%', background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          color: '#0a0a0a', border: 'none', borderRadius: 18,
          padding: '18px', fontWeight: 800, fontSize: '0.95rem', cursor: 'pointer', marginBottom: 16,
        }}
      >
        ⚡ Upgrade to PicklePro Premium
      </button>

      {/* Reset */}
      <div style={{ textAlign: 'center' }}>
        <button
          onClick={() => setShowReset(!showReset)}
          style={{ background: 'none', border: 'none', color: '#444', fontSize: '0.75rem', cursor: 'pointer' }}
        >
          {showReset ? 'Cancel' : 'Reset onboarding'}
        </button>
        {showReset && (
          <div style={{ marginTop: 12 }}>
            <p style={{ color: '#555', fontSize: '0.75rem', marginBottom: 10 }}>
              This will reset your profile and onboarding. Sessions are preserved.
            </p>
            <button
              onClick={onResetOnboarding}
              style={{
                background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
                color: '#ef4444', borderRadius: 12, padding: '10px 20px',
                fontSize: '0.8rem', fontWeight: 600, cursor: 'pointer',
                display: 'flex', alignItems: 'center', gap: 6, margin: '0 auto',
              }}
            >
              <Trash2 size={14} /> Reset Profile
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function ProfileSection({ title, children }) {
  return (
    <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px', marginBottom: 12 }}>
      <div className="label-xs" style={{ color: '#555', marginBottom: 12 }}>{title}</div>
      {children}
    </div>
  );
}

function EditSection({ title, children }) {
  return (
    <div style={{ background: '#141414', border: '1px solid rgba(200,241,53,0.2)', borderRadius: 18, padding: '16px', marginBottom: 12 }}>
      <div className="label-xs" style={{ color: '#c8f135', marginBottom: 12 }}>{title}</div>
      {children}
    </div>
  );
}

function ToggleRow({ label, sub, selected, onToggle }) {
  return (
    <button
      onClick={onToggle}
      style={{
        background: selected ? 'rgba(200,241,53,0.08)' : '#1e1e1e',
        border: selected ? '1px solid rgba(200,241,53,0.3)' : '1px solid #333',
        borderRadius: 12, padding: '12px 14px',
        display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', width: '100%', textAlign: 'left',
      }}
    >
      <div style={{
        width: 18, height: 18, borderRadius: '50%', flexShrink: 0,
        background: selected ? '#c8f135' : '#2a2a2a',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {selected && <Check size={10} color="#0a0a0a" />}
      </div>
      <div>
        <div style={{ color: selected ? '#c8f135' : '#a0a0a0', fontSize: '0.875rem', fontWeight: 600 }}>{label}</div>
        {sub && <div style={{ color: '#555', fontSize: '0.7rem' }}>DUPR {sub}</div>}
      </div>
    </button>
  );
}

function TagToggle({ label, selected, onToggle, color = '#c8f135' }) {
  return (
    <button
      onClick={onToggle}
      style={{
        background: selected ? `${color}12` : '#1e1e1e',
        border: selected ? `1px solid ${color}40` : '1px solid #333',
        color: selected ? color : '#666',
        borderRadius: 20, padding: '6px 12px', fontSize: '0.75rem', fontWeight: 600, cursor: 'pointer',
        transition: 'all 0.15s',
      }}
    >
      {label}
    </button>
  );
}
