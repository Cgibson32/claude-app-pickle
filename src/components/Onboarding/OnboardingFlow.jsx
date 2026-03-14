import { useState } from 'react';
import { ChevronRight, ChevronLeft, Check } from 'lucide-react';
import {
  EXPERIENCE_LEVELS,
  PLAY_FREQUENCIES,
  STRUGGLE_OPTIONS,
  TECHNICAL_WEAKNESSES,
  MENTAL_WEAKNESSES,
  GOAL_OPTIONS,
  PLAYER_TYPE_OPTIONS,
  DOUBLES_SINGLES_OPTIONS,
} from '../../data/onboardingData';

const TOTAL_STEPS = 10;

export default function OnboardingFlow({ onComplete }) {
  const [step, setStep] = useState(0);
  const [profile, setProfile] = useState({
    name: '',
    level: '',
    frequency: '',
    struggles: [],
    technicalWeaknesses: [],
    mentalWeaknesses: [],
    goals: [],
    playerType: '',
    format: '',
    frustrations: '',
  });

  const progress = ((step) / TOTAL_STEPS) * 100;

  const next = () => setStep(s => Math.min(s + 1, TOTAL_STEPS));
  const back = () => setStep(s => Math.max(s - 1, 0));

  const updateProfile = (key, value) => setProfile(p => ({ ...p, [key]: value }));
  const toggleArrayItem = (key, id) => {
    setProfile(p => {
      const arr = p[key];
      return { ...p, [key]: arr.includes(id) ? arr.filter(x => x !== id) : [...arr, id] };
    });
  };

  const handleComplete = () => {
    onComplete(profile);
  };

  return (
    <div className="min-h-screen bg-base-bg flex flex-col" style={{ backgroundColor: '#0a0a0a' }}>
      {/* Progress bar */}
      {step > 0 && step < TOTAL_STEPS && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, zIndex: 50 }}>
          <div className="progress-bar" style={{ borderRadius: 0, height: 3 }}>
            <div className="progress-fill" style={{ width: `${progress}%` }} />
          </div>
        </div>
      )}

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {step === 0 && <WelcomeStep onNext={next} />}
        {step === 1 && <MissionStep onNext={next} onBack={back} />}
        {step === 2 && <NameStep profile={profile} onChange={updateProfile} onNext={next} onBack={back} />}
        {step === 3 && (
          <SelectionStep
            title="What's your level?"
            subtitle="Be honest — this helps us personalize your coaching. Every level has a unique growth path."
            options={EXPERIENCE_LEVELS}
            selected={[profile.level]}
            onSelect={(id) => updateProfile('level', id)}
            onNext={next}
            onBack={back}
            singleSelect
          />
        )}
        {step === 4 && (
          <SelectionStep
            title="How often do you play?"
            subtitle="Whether it's once a month or every day, we'll match your rhythm."
            options={PLAY_FREQUENCIES}
            selected={[profile.frequency]}
            onSelect={(id) => updateProfile('frequency', id)}
            onNext={next}
            onBack={back}
            singleSelect
          />
        )}
        {step === 5 && (
          <SelectionStep
            title="Where do you struggle most?"
            subtitle="Everyone has struggles — naming them is the first step to overcoming them."
            options={STRUGGLE_OPTIONS}
            selected={profile.struggles}
            onSelect={(id) => toggleArrayItem('struggles', id)}
            onNext={next}
            onBack={back}
            multiSelect
          />
        )}
        {step === 6 && (
          <SelectionStep
            title="Technical weaknesses?"
            subtitle="The shots that break down under pressure. We'll help you rebuild them with confidence."
            options={TECHNICAL_WEAKNESSES}
            selected={profile.technicalWeaknesses}
            onSelect={(id) => toggleArrayItem('technicalWeaknesses', id)}
            onNext={next}
            onBack={back}
            multiSelect
          />
        )}
        {step === 7 && (
          <SelectionStep
            title="Mental game challenges?"
            subtitle="The mental side wins or loses most matches. This is where the real breakthroughs happen."
            options={MENTAL_WEAKNESSES}
            selected={profile.mentalWeaknesses}
            onSelect={(id) => toggleArrayItem('mentalWeaknesses', id)}
            onNext={next}
            onBack={back}
            multiSelect
          />
        )}
        {step === 8 && (
          <SelectionStep
            title="What are your goals?"
            subtitle="Your goals shape everything — your daily intentions, your coaching, and your growth plan."
            options={GOAL_OPTIONS}
            selected={profile.goals}
            onSelect={(id) => toggleArrayItem('goals', id)}
            onNext={next}
            onBack={back}
            multiSelect
          />
        )}
        {step === 9 && (
          <PlayerTypeStep
            profile={profile}
            updateProfile={updateProfile}
            onNext={next}
            onBack={back}
          />
        )}
        {step === TOTAL_STEPS && (
          <SummaryStep profile={profile} onComplete={handleComplete} onBack={back} />
        )}
      </div>
    </div>
  );
}

function WelcomeStep({ onNext }) {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-6 text-center animate-fade-in">
      {/* Ball */}
      <div className="mb-8" style={{ animation: 'float 3s ease-in-out infinite' }}>
        <div
          style={{
            width: 100, height: 100, borderRadius: '50%',
            background: 'linear-gradient(135deg, #c8f135, #a8d820)',
            boxShadow: '0 0 40px rgba(200,241,53,0.5), 0 0 80px rgba(200,241,53,0.2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 48,
          }}
        >
          🏓
        </div>
      </div>

      <h1 style={{ fontSize: '2.5rem', fontWeight: 900, letterSpacing: '-0.03em', color: '#f5f5f5', marginBottom: 8 }}>
        Pickle<span style={{ color: '#c8f135' }}>Pro</span>
      </h1>
      <p style={{ color: '#a0a0a0', fontSize: '1rem', marginBottom: 12, lineHeight: 1.6, maxWidth: 300 }}>
        The app that helps you grow — not just as a player,<br />
        <span style={{ color: '#f5f5f5', fontWeight: 600 }}>but as a competitor, teammate, and student of the game.</span>
      </p>
      <p style={{ color: '#666', fontSize: '0.85rem', marginBottom: 40, lineHeight: 1.6, maxWidth: 280 }}>
        Built for players who believe improvement is a daily practice, not just a scoreboard result.
      </p>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, width: '100%', maxWidth: 320, marginBottom: 40 }}>
        {[
          { icon: '🎯', text: 'Daily intentions that sharpen your focus' },
          { icon: '🧠', text: 'Mental performance tools used by top athletes' },
          { icon: '📓', text: 'Reflection journaling that compounds into growth' },
          { icon: '⚡', text: 'AI-powered coaching insights' },
          { icon: '🏆', text: 'Process-oriented progression that actually works' },
        ].map((item, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left' }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#c8f135', flexShrink: 0 }} />
            <span style={{ color: '#a0a0a0', fontSize: '0.875rem' }}>{item.icon} {item.text}</span>
          </div>
        ))}
      </div>

      <button
        onClick={onNext}
        className="press-scale"
        style={{
          background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          color: '#0a0a0a',
          border: 'none',
          borderRadius: 16,
          padding: '18px 48px',
          fontSize: '1rem',
          fontWeight: 800,
          letterSpacing: '0.01em',
          cursor: 'pointer',
          width: '100%',
          maxWidth: 320,
        }}
      >
        Begin My Journey
      </button>
      <p style={{ color: '#555', fontSize: '0.75rem', marginTop: 16 }}>
        Takes 2 minutes · Free to start · No credit card required
      </p>
    </div>
  );
}

function MissionStep({ onNext, onBack }) {
  return (
    <div className="min-h-screen flex flex-col px-6 py-16 animate-slide-up" style={{ maxWidth: 480, margin: '0 auto' }}>
      <BackButton onBack={onBack} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 32 }}>
        <div>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 12 }}>The PicklePro Philosophy</div>
          <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2, marginBottom: 16 }}>
            Shift from results<br />
            <span style={{ color: '#c8f135' }}>to process.</span>
          </h2>
          <p style={{ color: '#a0a0a0', fontSize: '0.95rem', lineHeight: 1.7 }}>
            Most players obsess over the scoreboard. The players who improve fastest focus on <em style={{ color: '#f5f5f5' }}>how</em> they play — the patience, the communication, the emotional control, the daily habits.
          </p>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {[
            { icon: '🌱', title: 'Skill over score', text: 'Focus on the craft. The results follow.' },
            { icon: '🧘', title: 'Mind over frustration', text: 'Patience, composure, and emotional intelligence.' },
            { icon: '🤝', title: 'Team over ego', text: 'Communication, trust, and making your partner better.' },
            { icon: '😄', title: 'Joy over pressure', text: 'Love the process. Growth becomes effortless.' },
          ].map((item, i) => (
            <div key={i} style={{
              background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16,
              padding: '14px 16px', display: 'flex', alignItems: 'flex-start', gap: 14,
            }}>
              <span style={{ fontSize: '1.25rem', marginTop: 2 }}>{item.icon}</span>
              <div>
                <div style={{ color: '#f5f5f5', fontSize: '0.875rem', fontWeight: 700, marginBottom: 2 }}>{item.title}</div>
                <div style={{ color: '#888', fontSize: '0.8rem', lineHeight: 1.5 }}>{item.text}</div>
              </div>
            </div>
          ))}
        </div>

        <blockquote style={{
          borderLeft: '3px solid #c8f135', paddingLeft: 16,
          color: '#c8f135', fontSize: '0.95rem', fontStyle: 'italic',
          lineHeight: 1.6,
        }}>
          &ldquo;The players who improve most learn to enjoy repetition. Growth is easier when you love the work.&rdquo;
        </blockquote>

        <NextButton onClick={onNext} label="I'm In — Let's Go" />
      </div>
    </div>
  );
}

function NameStep({ profile, onChange, onNext, onBack }) {
  const canContinue = profile.name.trim().length >= 2;
  return (
    <div className="min-h-screen flex flex-col px-6 py-16 animate-slide-up" style={{ maxWidth: 480, margin: '0 auto' }}>
      <BackButton onBack={onBack} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 32 }}>
        <div>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 12 }}>Step 1 of 8</div>
          <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2 }}>
            What should we<br />call you?
          </h2>
          <p style={{ color: '#888', fontSize: '0.875rem', marginTop: 8 }}>
            Your coach needs a name to keep things personal.
          </p>
        </div>

        <div>
          <input
            type="text"
            value={profile.name}
            onChange={e => onChange('name', e.target.value)}
            placeholder="Your first name"
            style={{
              width: '100%', background: '#141414', border: '1px solid #333',
              borderRadius: 16, padding: '18px 20px', color: '#f5f5f5',
              fontSize: '1.1rem', outline: 'none',
              transition: 'border-color 0.2s',
            }}
            onFocus={e => e.target.style.borderColor = '#c8f135'}
            onBlur={e => e.target.style.borderColor = '#333'}
            autoFocus
          />
          {profile.name.trim().length >= 2 && (
            <p style={{ color: '#a0a0a0', fontSize: '0.875rem', marginTop: 12, paddingLeft: 4, lineHeight: 1.5 }}>
              Welcome to PicklePro, <span style={{ color: '#c8f135', fontWeight: 700 }}>{profile.name}</span>. Your growth journey starts right now.
            </p>
          )}
        </div>

        <NextButton onClick={onNext} disabled={!canContinue} label="Continue" />
      </div>
    </div>
  );
}

function SelectionStep({ title, subtitle, options, selected, onSelect, onNext, onBack, multiSelect }) {
  const canContinue = selected.length > 0;
  return (
    <div className="min-h-screen flex flex-col px-6 pt-16 pb-8 animate-slide-up" style={{ maxWidth: 480, margin: '0 auto' }}>
      <BackButton onBack={onBack} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 24 }}>
        <div>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 12 }}>
            {multiSelect ? 'Select all that apply' : 'Choose one'}
          </div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2 }}>{title}</h2>
          <p style={{ color: '#888', fontSize: '0.875rem', marginTop: 8, lineHeight: 1.5 }}>{subtitle}</p>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: options.length > 6 ? '1fr 1fr' : '1fr', gap: 10 }}>
          {options.map(opt => {
            const isSelected = selected.includes(opt.id);
            return (
              <button
                key={opt.id}
                onClick={() => onSelect(opt.id)}
                className="press-scale"
                style={{
                  background: isSelected ? 'rgba(200,241,53,0.1)' : '#141414',
                  border: isSelected ? '1.5px solid #c8f135' : '1px solid #2a2a2a',
                  borderRadius: 14,
                  padding: options.length > 6 ? '12px 14px' : '14px 16px',
                  display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer',
                  textAlign: 'left', width: '100%',
                  transition: 'all 0.2s',
                }}
              >
                <span style={{ fontSize: options.length > 6 ? '1.1rem' : '1.5rem', flexShrink: 0 }}>{opt.emoji}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{
                    color: isSelected ? '#c8f135' : '#f5f5f5',
                    fontWeight: 600, fontSize: options.length > 6 ? '0.8rem' : '0.9rem',
                    lineHeight: 1.3,
                  }}>{opt.label}</div>
                  {opt.description && (
                    <div style={{ color: '#666', fontSize: '0.75rem', marginTop: 2, lineHeight: 1.4 }}>{opt.description}</div>
                  )}
                  {opt.dupr && (
                    <div style={{ color: '#555', fontSize: '0.7rem', marginTop: 2 }}>DUPR {opt.dupr}</div>
                  )}
                </div>
                {isSelected && (
                  <div style={{
                    width: 20, height: 20, borderRadius: '50%',
                    background: '#c8f135', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>
                    <Check size={12} color="#0a0a0a" />
                  </div>
                )}
              </button>
            );
          })}
        </div>

        <NextButton onClick={onNext} disabled={!canContinue} label="Continue" />
      </div>
    </div>
  );
}

function PlayerTypeStep({ profile, updateProfile, onNext, onBack }) {
  return (
    <div className="min-h-screen flex flex-col px-6 pt-16 pb-8 animate-slide-up" style={{ maxWidth: 480, margin: '0 auto' }}>
      <BackButton onBack={onBack} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 24 }}>
        <div>
          <div className="label-xs" style={{ color: '#c8f135', marginBottom: 12 }}>Your Identity</div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2 }}>
            What kind of player<br />do you want to become?
          </h2>
          <p style={{ color: '#888', fontSize: '0.875rem', marginTop: 8, lineHeight: 1.5 }}>
            This shapes your coaching style and daily intentions. There&apos;s no wrong answer — only your answer.
          </p>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {PLAYER_TYPE_OPTIONS.map(opt => {
            const isSelected = profile.playerType === opt.id;
            return (
              <button
                key={opt.id}
                onClick={() => updateProfile('playerType', opt.id)}
                className="press-scale"
                style={{
                  background: isSelected ? 'rgba(200,241,53,0.1)' : '#141414',
                  border: isSelected ? '1.5px solid #c8f135' : '1px solid #2a2a2a',
                  borderRadius: 16, padding: '16px 18px',
                  display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer',
                  textAlign: 'left', width: '100%', transition: 'all 0.2s',
                }}
              >
                <span style={{ fontSize: '1.75rem' }}>{opt.emoji}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ color: isSelected ? '#c8f135' : '#f5f5f5', fontWeight: 700, fontSize: '0.95rem' }}>{opt.label}</div>
                  <div style={{ color: '#888', fontSize: '0.8rem', marginTop: 3, lineHeight: 1.4 }}>{opt.description}</div>
                </div>
                {isSelected && <Check size={18} color="#c8f135" />}
              </button>
            );
          })}
        </div>

        <div>
          <p style={{ color: '#888', fontSize: '0.8rem', marginBottom: 10 }}>Singles, doubles, or both?</p>
          <div style={{ display: 'flex', gap: 10 }}>
            {DOUBLES_SINGLES_OPTIONS.map(opt => {
              const isSelected = profile.format === opt.id;
              return (
                <button
                  key={opt.id}
                  onClick={() => updateProfile('format', opt.id)}
                  className="press-scale"
                  style={{
                    flex: 1, background: isSelected ? 'rgba(200,241,53,0.1)' : '#141414',
                    border: isSelected ? '1.5px solid #c8f135' : '1px solid #2a2a2a',
                    borderRadius: 14, padding: '12px 8px', cursor: 'pointer',
                    textAlign: 'center', transition: 'all 0.2s',
                  }}
                >
                  <div style={{ fontSize: '1.25rem', marginBottom: 4 }}>{opt.emoji}</div>
                  <div style={{ color: isSelected ? '#c8f135' : '#f5f5f5', fontWeight: 600, fontSize: '0.8rem' }}>{opt.label}</div>
                </button>
              );
            })}
          </div>
        </div>

        <NextButton onClick={onNext} disabled={!profile.playerType || !profile.format} label="Almost Done" />
      </div>
    </div>
  );
}

function SummaryStep({ profile, onComplete, onBack }) {
  const levelData = EXPERIENCE_LEVELS.find(l => l.id === profile.level);
  const topStruggles = profile.struggles.slice(0, 3);
  const topMentalWeaknesses = profile.mentalWeaknesses.slice(0, 2);
  const topGoals = profile.goals.slice(0, 2);
  const playerType = PLAYER_TYPE_OPTIONS.find(p => p.id === profile.playerType);

  // Personalized coaching promise based on selections
  const getCoachingPromise = () => {
    const promises = [];
    if (profile.struggles.includes('patience') || profile.mentalWeaknesses.includes('patience-mental')) {
      promises.push('building patience into every rally');
    }
    if (profile.struggles.includes('frustration') || profile.mentalWeaknesses.includes('frustration')) {
      promises.push('turning frustration into focus');
    }
    if (profile.struggles.includes('communication') || profile.mentalWeaknesses.includes('communication')) {
      promises.push('strengthening your on-court communication');
    }
    if (profile.goals.includes('compete')) {
      promises.push('preparing you for competitive play');
    }
    if (profile.goals.includes('mental')) {
      promises.push('developing an unshakeable mental game');
    }
    if (promises.length === 0) promises.push('helping you grow every single session');
    return promises.slice(0, 2).join(' and ');
  };

  return (
    <div className="min-h-screen flex flex-col px-6 pt-16 pb-8 animate-slide-up" style={{ maxWidth: 480, margin: '0 auto' }}>
      <BackButton onBack={onBack} />

      <div style={{ textAlign: 'center', marginBottom: 32 }}>
        <div style={{
          width: 80, height: 80, borderRadius: '50%',
          background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: '2rem', margin: '0 auto 16px',
          boxShadow: '0 0 40px rgba(200,241,53,0.4)',
        }}>
          🏓
        </div>
        <div className="label-xs" style={{ color: '#c8f135', marginBottom: 8 }}>Your Journey Begins</div>
        <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: '#f5f5f5', lineHeight: 1.2 }}>
          {profile.name ? `${profile.name}, you're` : "You're"} ready.
        </h2>
        <p style={{ color: '#888', fontSize: '0.875rem', marginTop: 8, lineHeight: 1.5 }}>
          Your personalized coaching plan is set. We&apos;ll focus on {getCoachingPromise()}.
        </p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 32 }}>
        {levelData && (
          <SummaryCard
            icon={levelData.emoji}
            label="Level"
            value={levelData.label}
            sub={levelData.dupr}
          />
        )}

        {playerType && (
          <SummaryCard
            icon={playerType.emoji}
            label="Player Identity"
            value={playerType.label}
          />
        )}

        {topStruggles.length > 0 && (
          <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16, padding: '14px 16px' }}>
            <div className="label-xs" style={{ color: '#666', marginBottom: 10 }}>Growth Areas</div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {topStruggles.map(id => {
                const item = STRUGGLE_OPTIONS.find(s => s.id === id);
                return item ? (
                  <span key={id} style={{
                    background: 'rgba(200,241,53,0.1)', border: '1px solid rgba(200,241,53,0.3)',
                    color: '#c8f135', borderRadius: 20, padding: '4px 12px', fontSize: '0.75rem', fontWeight: 600,
                  }}>
                    {item.emoji} {item.label}
                  </span>
                ) : null;
              })}
            </div>
          </div>
        )}

        {topMentalWeaknesses.length > 0 && (
          <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16, padding: '14px 16px' }}>
            <div className="label-xs" style={{ color: '#666', marginBottom: 10 }}>Mindset Priorities</div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {topMentalWeaknesses.map(id => {
                const item = MENTAL_WEAKNESSES.find(m => m.id === id);
                return item ? (
                  <span key={id} style={{
                    background: 'rgba(59,130,246,0.1)', border: '1px solid rgba(59,130,246,0.3)',
                    color: '#60a5fa', borderRadius: 20, padding: '4px 12px', fontSize: '0.75rem', fontWeight: 600,
                  }}>
                    {item.emoji} {item.label}
                  </span>
                ) : null;
              })}
            </div>
          </div>
        )}

        {topGoals.length > 0 && (
          <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16, padding: '14px 16px' }}>
            <div className="label-xs" style={{ color: '#666', marginBottom: 10 }}>Your Goals</div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {topGoals.map(id => {
                const item = GOAL_OPTIONS.find(g => g.id === id);
                return item ? (
                  <span key={id} style={{
                    background: 'rgba(168,85,247,0.1)', border: '1px solid rgba(168,85,247,0.3)',
                    color: '#c084fc', borderRadius: 20, padding: '4px 12px', fontSize: '0.75rem', fontWeight: 600,
                  }}>
                    {item.emoji} {item.label}
                  </span>
                ) : null;
              })}
            </div>
          </div>
        )}

        <div style={{
          background: 'rgba(200,241,53,0.06)', border: '1px solid rgba(200,241,53,0.2)',
          borderRadius: 16, padding: '16px',
        }}>
          <p style={{ color: '#a0a0a0', fontSize: '0.875rem', lineHeight: 1.7, margin: 0 }}>
            &ldquo;Every session from here forward is a deposit in your growth. Stay process-focused. Stay patient.{' '}
            <span style={{ color: '#c8f135' }}>Play with intention. Play with joy.</span>&rdquo;
          </p>
        </div>
      </div>

      <button
        onClick={onComplete}
        className="press-scale"
        style={{
          background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          color: '#0a0a0a', border: 'none', borderRadius: 16,
          padding: '18px 24px', fontSize: '1rem', fontWeight: 800,
          cursor: 'pointer', width: '100%', letterSpacing: '0.01em',
        }}
      >
        Start My PicklePro Journey
      </button>
      <p style={{ color: '#555', fontSize: '0.75rem', textAlign: 'center', marginTop: 12 }}>
        You can update your profile anytime
      </p>
    </div>
  );
}

function SummaryCard({ icon, label, value, sub }) {
  return (
    <div style={{
      background: '#141414', border: '1px solid #2a2a2a', borderRadius: 16,
      padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <span style={{ fontSize: '1.5rem' }}>{icon}</span>
      <div>
        <div className="label-xs" style={{ color: '#555' }}>{label}</div>
        <div style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.95rem' }}>{value}</div>
        {sub && <div style={{ color: '#666', fontSize: '0.75rem', marginTop: 2 }}>DUPR {sub}</div>}
      </div>
    </div>
  );
}

function BackButton({ onBack }) {
  return (
    <button
      onClick={onBack}
      style={{
        background: 'none', border: 'none', color: '#666',
        display: 'flex', alignItems: 'center', gap: 6,
        cursor: 'pointer', padding: 0, marginBottom: 24, fontSize: '0.875rem',
      }}
    >
      <ChevronLeft size={18} /> Back
    </button>
  );
}

function NextButton({ onClick, disabled, label }) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className="press-scale"
      style={{
        background: disabled ? '#1e1e1e' : 'linear-gradient(135deg, #c8f135, #a8d820)',
        color: disabled ? '#555' : '#0a0a0a',
        border: disabled ? '1px solid #2a2a2a' : 'none',
        borderRadius: 16, padding: '18px 24px',
        fontSize: '1rem', fontWeight: 800, cursor: disabled ? 'not-allowed' : 'pointer',
        width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        transition: 'all 0.2s', marginTop: 8,
      }}
    >
      {label} {!disabled && <ChevronRight size={18} />}
    </button>
  );
}
