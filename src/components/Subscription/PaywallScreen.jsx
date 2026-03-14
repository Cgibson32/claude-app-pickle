import { useState } from 'react';
import { Check, ChevronLeft, Zap, Brain, Target, TrendingUp, BookOpen, Star, Sparkles } from 'lucide-react';

const PLANS = [
  {
    id: 'monthly',
    label: 'Monthly',
    price: '$9.99',
    period: 'per month',
    badge: null,
    priceNum: 9.99,
  },
  {
    id: 'annual',
    label: 'Annual',
    price: '$59.99',
    period: 'per year',
    badge: 'Save 50%',
    priceNum: 59.99,
    perMonth: '$5/mo',
  },
];

const FREE_FEATURES = [
  'Daily intention setting',
  'Basic journal (5 entries)',
  'Skill library preview',
  'Mental game intro',
];

const PREMIUM_FEATURES = [
  'Full AI coaching and personalized insights',
  'Unlimited journal entries and reflection',
  'Complete skill library with drills',
  'Full mental game library (9 pillars)',
  'Advanced progress analytics and trends',
  'Daily personalized coaching plans',
  'Saved lessons and bookmarks',
];

export default function PaywallScreen({ onBack, onSubscribe }) {
  const [selectedPlan, setSelectedPlan] = useState('annual');
  const [subscribed, setSubscribed] = useState(false);

  const handleSubscribe = () => {
    setSubscribed(true);
    setTimeout(() => {
      onSubscribe?.(selectedPlan);
    }, 1500);
  };

  if (subscribed) {
    return <SuccessScreen onBack={onBack} />;
  }

  return (
    <div style={{ minHeight: '100vh', background: '#0a0a0a', paddingBottom: 40 }} className="animate-fade-in">
      {/* Back */}
      <div style={{ padding: '20px 20px 0' }}>
        {onBack && (
          <button onClick={onBack} style={{
            background: 'none', border: 'none', color: '#666',
            display: 'flex', alignItems: 'center', gap: 6,
            cursor: 'pointer', fontSize: '0.875rem', padding: 0, marginBottom: 24,
          }}>
            <ChevronLeft size={16} /> Back
          </button>
        )}
      </div>

      {/* Hero */}
      <div style={{ padding: '0 20px', textAlign: 'center', marginBottom: 32 }}>
        <div style={{
          width: 72, height: 72, borderRadius: '50%',
          background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          margin: '0 auto 16px',
          boxShadow: '0 0 30px rgba(200,241,53,0.4)',
        }}>
          <span style={{ fontSize: '1.5rem', fontWeight: 900, color: '#0a0a0a' }}>PP</span>
        </div>
        <h1 style={{ fontSize: '2rem', fontWeight: 900, color: '#f5f5f5', letterSpacing: '-0.03em', marginBottom: 8 }}>
          Pickle<span style={{ color: '#c8f135' }}>Pro</span> Premium
        </h1>
        <p style={{ color: '#a0a0a0', fontSize: '0.95rem', lineHeight: 1.6, maxWidth: 280, margin: '0 auto' }}>
          The complete performance companion for players who are serious about improving.
        </p>
      </div>

      {/* Premium Features */}
      <div style={{ padding: '0 20px', marginBottom: 28 }}>
        <div style={{
          background: '#141414', border: '1px solid #2a2a2a', borderRadius: 24, overflow: 'hidden',
        }}>
          <div style={{
            background: 'linear-gradient(135deg, rgba(200,241,53,0.08), rgba(168,216,32,0.05))',
            borderBottom: '1px solid rgba(200,241,53,0.15)', padding: '16px 20px',
          }}>
            <div className="label-xs" style={{ color: '#c8f135' }}>Everything in Premium</div>
          </div>
          <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 12 }}>
            {PREMIUM_FEATURES.map((text, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 20, height: 20, borderRadius: '50%', flexShrink: 0,
                  background: 'rgba(200,241,53,0.15)', border: '1px solid rgba(200,241,53,0.3)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <Check size={10} color="#c8f135" />
                </div>
                <span style={{ color: '#c0c0c0', fontSize: '0.875rem' }}>{text}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Plans */}
      <div style={{ padding: '0 20px', marginBottom: 24 }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 14 }}>Choose your plan</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {PLANS.map(plan => (
            <button
              key={plan.id}
              onClick={() => setSelectedPlan(plan.id)}
              className="press-scale"
              style={{
                background: selectedPlan === plan.id ? 'rgba(200,241,53,0.08)' : '#141414',
                border: selectedPlan === plan.id ? '2px solid rgba(200,241,53,0.5)' : '1px solid #2a2a2a',
                borderRadius: 18, padding: '18px 20px',
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                cursor: 'pointer', textAlign: 'left', transition: 'all 0.2s',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 22, height: 22, borderRadius: '50%',
                  background: selectedPlan === plan.id ? '#c8f135' : '#2a2a2a',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  border: selectedPlan !== plan.id ? '1px solid #444' : 'none',
                }}>
                  {selectedPlan === plan.id && <Check size={12} color="#0a0a0a" />}
                </div>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ color: '#f5f5f5', fontWeight: 700, fontSize: '0.95rem' }}>{plan.label}</span>
                    {plan.badge && (
                      <span style={{
                        background: 'rgba(200,241,53,0.15)', border: '1px solid rgba(200,241,53,0.4)',
                        color: '#c8f135', borderRadius: 20, padding: '1px 8px', fontSize: '0.65rem', fontWeight: 800,
                      }}>
                        {plan.badge}
                      </span>
                    )}
                  </div>
                  {plan.perMonth && (
                    <div style={{ color: '#666', fontSize: '0.75rem', marginTop: 2 }}>{plan.perMonth} billed annually</div>
                  )}
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ color: selectedPlan === plan.id ? '#c8f135' : '#f5f5f5', fontWeight: 800, fontSize: '1.1rem' }}>
                  {plan.price}
                </div>
                <div style={{ color: '#555', fontSize: '0.7rem' }}>{plan.period}</div>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Free tier comparison */}
      <div style={{ padding: '0 20px', marginBottom: 28 }}>
        <div style={{ background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px 20px' }}>
          <div className="label-xs" style={{ color: '#555', marginBottom: 12 }}>Free tier includes</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {FREE_FEATURES.map((f, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={{ width: 16, height: 16, borderRadius: '50%', background: '#1e1e1e', border: '1px solid #333', flexShrink: 0 }} />
                <span style={{ color: '#666', fontSize: '0.8rem' }}>{f}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* CTA */}
      <div style={{ padding: '0 20px' }}>
        <button
          onClick={handleSubscribe}
          className="press-scale"
          style={{
            width: '100%', background: 'linear-gradient(135deg, #c8f135, #a8d820)',
            color: '#0a0a0a', border: 'none', borderRadius: 18,
            padding: '20px', fontWeight: 900, fontSize: '1rem', cursor: 'pointer',
            marginBottom: 12,
          }}
        >
          Start Premium — {PLANS.find(p => p.id === selectedPlan)?.price}
          {selectedPlan === 'annual' ? '/year' : '/month'}
        </button>
        <p style={{ textAlign: 'center', color: '#444', fontSize: '0.72rem', lineHeight: 1.6 }}>
          7-day free trial · Cancel anytime · Billed {selectedPlan === 'annual' ? 'annually' : 'monthly'}
        </p>

        {/* Trust signals */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 24, marginTop: 20 }}>
          {['Secure', 'Cancel anytime', 'Instant access'].map(label => (
            <div key={label} style={{ textAlign: 'center' }}>
              <div style={{ color: '#555', fontSize: '0.7rem', fontWeight: 600 }}>{label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Testimonials */}
      <div style={{ padding: '28px 20px 0' }}>
        <div className="label-xs" style={{ color: '#555', marginBottom: 14, textAlign: 'center' }}>
          What players say
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[
            {
              name: 'Sarah K.',
              level: '3.5 player',
              quote: 'My patience on the court has completely transformed. The daily intentions changed how I think about every rally.',
              stars: 5,
            },
            {
              name: 'Mike T.',
              level: 'Tournament player',
              quote: 'The mental game library alone is worth the subscription. I used to crumble under pressure. Not anymore.',
              stars: 5,
            },
            {
              name: 'Linda R.',
              level: 'Recreational player',
              quote: 'I play more joyfully now. I\'m less frustrated when I miss shots. PicklePro taught me to love the process.',
              stars: 5,
            },
          ].map((t, i) => (
            <div key={i} style={{
              background: '#141414', border: '1px solid #2a2a2a', borderRadius: 18, padding: '16px',
            }}>
              <div style={{ display: 'flex', gap: 4, marginBottom: 10 }}>
                {[1,2,3,4,5].map(n => (
                  <Star key={n} size={12} fill="#c8f135" color="#c8f135" />
                ))}
              </div>
              <p style={{ color: '#a0a0a0', fontSize: '0.85rem', lineHeight: 1.6, margin: '0 0 10px', fontStyle: 'italic' }}>
                "{t.quote}"
              </p>
              <div>
                <span style={{ color: '#f5f5f5', fontWeight: 600, fontSize: '0.8rem' }}>{t.name}</span>
                <span style={{ color: '#555', fontSize: '0.75rem' }}> · {t.level}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function SuccessScreen({ onBack }) {
  return (
    <div style={{
      minHeight: '100vh', background: '#0a0a0a',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      padding: '40px 24px', textAlign: 'center',
    }} className="animate-scale-in">
      <div style={{
        width: 100, height: 100, borderRadius: '50%',
        background: 'linear-gradient(135deg, #c8f135, #a8d820)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        marginBottom: 24,
        boxShadow: '0 0 60px rgba(200,241,53,0.5)',
      }}>
        <span style={{ fontSize: '2rem', fontWeight: 900, color: '#0a0a0a' }}>PP</span>
      </div>
      <h2 style={{ color: '#f5f5f5', fontWeight: 900, fontSize: '1.75rem', marginBottom: 12 }}>
        Welcome to Premium!
      </h2>
      <p style={{ color: '#a0a0a0', fontSize: '0.95rem', lineHeight: 1.7, marginBottom: 32, maxWidth: 280 }}>
        Your full PicklePro experience is now unlocked. Play with intention. Play with joy.
      </p>
      <button
        onClick={onBack}
        style={{
          background: 'linear-gradient(135deg, #c8f135, #a8d820)',
          color: '#0a0a0a', border: 'none', borderRadius: 16,
          padding: '16px 40px', fontWeight: 800, fontSize: '1rem', cursor: 'pointer',
        }}
      >
        Start Coaching →
      </button>
    </div>
  );
}
