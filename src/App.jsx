import { useState, useEffect } from 'react';
import './index.css';

import { AppProvider, useAppState, useAppActions } from './context/AppContext';
import { initNative } from './services/NativeService';

// Components
import OnboardingFlow from './components/Onboarding/OnboardingFlow';
import HomeScreen from './components/Home/HomeScreen';
import SkillLibrary from './components/Skills/SkillLibrary';
import SkillDetail from './components/Skills/SkillDetail';
import MentalGameLibrary from './components/MentalGame/MentalGameLibrary';
import MentalGameDetail from './components/MentalGame/MentalGameDetail';
import JournalScreen from './components/Journal/JournalScreen';
import AICoachScreen from './components/AICoach/AICoachScreen';
import ProgressDashboard from './components/Progress/ProgressDashboard';
import ProfileScreen from './components/Profile/ProfileScreen';
import PaywallScreen from './components/Subscription/PaywallScreen';
import NavBar from './components/shared/NavBar';

const APP_TABS = ['home', 'skills', 'journal', 'mental', 'progress'];

// Inner shell — has access to AppContext
function AppShell() {
  const { profile, sessions, intentions, savedSkills } = useAppState();
  const { saveProfile, clearProfile, saveSession, deleteSession, toggleSavedSkill } = useAppActions();

  // Initialize native plugins (status bar, splash screen, keyboard) on mount
  useEffect(() => { initNative(); }, []);

  // Local UI state — purely navigational, not persisted
  const [activeTab, setActiveTab] = useState('home');
  const [activeSkill, setActiveSkill] = useState(null);
  const [activeMentalCategory, setActiveMentalCategory] = useState(null);
  const [journalMode, setJournalMode] = useState(null);
  const [showProfile, setShowProfile] = useState(false);
  const [showPaywall, setShowPaywall] = useState(false);
  const [showCoach, setShowCoach] = useState(false);

  // Onboarding gate
  if (!profile) {
    return (
      <OnboardingFlow
        onComplete={(p) => saveProfile(p)}
      />
    );
  }

  const handleNavigate = (tab, options = {}) => {
    setShowProfile(false);
    setShowPaywall(false);
    setShowCoach(false);
    setActiveSkill(null);
    setActiveMentalCategory(null);
    setJournalMode(null);

    if (tab === 'paywall') { setShowPaywall(true); return; }
    if (tab === 'profile') { setShowProfile(true); return; }
    if (tab === 'coach') { setShowCoach(true); return; }

    if (tab === 'journal' && options.mode) {
      setJournalMode(options.mode);
      setActiveTab('journal');
      return;
    }

    if (APP_TABS.includes(tab)) setActiveTab(tab);
  };

  // Full-screen overlays
  if (showPaywall) {
    return (
      <FullScreenWrapper>
        <PaywallScreen
          onBack={() => setShowPaywall(false)}
          onSubscribe={() => setShowPaywall(false)}
        />
      </FullScreenWrapper>
    );
  }

  if (showProfile) {
    return (
      <FullScreenWrapper>
        <BackHeader onBack={() => setShowProfile(false)} label="Close" />
        <ProfileScreen
          onNavigate={handleNavigate}
          onResetOnboarding={() => { clearProfile(); setShowProfile(false); }}
        />
      </FullScreenWrapper>
    );
  }

  if (showCoach) {
    return (
      <FullScreenWrapper>
        <BackHeader onBack={() => setShowCoach(false)} label="Back" />
        <AICoachScreen onNavigate={handleNavigate} />
      </FullScreenWrapper>
    );
  }

  // Drill-down views
  if (activeTab === 'skills' && activeSkill) {
    return (
      <FullScreenWrapper>
        <SkillDetail
          skillId={activeSkill}
          onBack={() => setActiveSkill(null)}
          savedSkills={savedSkills}
          onToggleSave={toggleSavedSkill}
        />
      </FullScreenWrapper>
    );
  }

  if (activeTab === 'mental' && activeMentalCategory) {
    return (
      <FullScreenWrapper>
        <MentalGameDetail
          categoryId={activeMentalCategory}
          onBack={() => setActiveMentalCategory(null)}
        />
      </FullScreenWrapper>
    );
  }

  const renderTab = () => {
    switch (activeTab) {
      case 'home':
        return (
          <HomeScreen
            profile={profile}
            sessions={sessions}
            intentions={intentions}
            onNavigate={handleNavigate}
          />
        );
      case 'skills':
        return (
          <SkillLibrary
            onSelectSkill={(id) => setActiveSkill(id)}
            savedSkills={savedSkills}
          />
        );
      case 'journal':
        return (
          <JournalScreen
            sessions={sessions}
            onSave={saveSession}
            onDelete={deleteSession}
            initialMode={journalMode}
          />
        );
      case 'mental':
        return (
          <MentalGameLibrary
            onSelectCategory={(id) => setActiveMentalCategory(id)}
          />
        );
      case 'progress':
        return (
          <ProgressDashboard
            sessions={sessions}
            intentions={intentions}
          />
        );
      default:
        return null;
    }
  };

  return (
    <div style={{ background: '#0a0a0a', minHeight: '100vh', maxWidth: 480, margin: '0 auto', position: 'relative' }}>
      {/* Header */}
      <header style={{
        position: 'sticky', top: 0, zIndex: 40,
        background: 'rgba(10,10,10,0.96)',
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
        borderBottom: '1px solid #1a1a1a',
        padding: '12px 20px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{
            width: 28, height: 28, borderRadius: 8,
            background: 'linear-gradient(135deg, #c8f135, #a8d820)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.9rem',
          }}>
            🏓
          </div>
          <span style={{ fontWeight: 900, fontSize: '1rem', color: '#f5f5f5', letterSpacing: '-0.01em' }}>
            Pickle<span style={{ color: '#c8f135' }}>Pro</span>
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <button
            onClick={() => setShowCoach(true)}
            style={{
              background: 'rgba(168,85,247,0.1)', border: '1px solid rgba(168,85,247,0.3)',
              borderRadius: 20, padding: '5px 12px',
              display: 'flex', alignItems: 'center', gap: 5,
              color: '#a855f7', fontSize: '0.72rem', fontWeight: 700, cursor: 'pointer',
            }}
          >
            🤖 AI Coach
          </button>
          <button
            onClick={() => setShowProfile(true)}
            style={{
              width: 30, height: 30, borderRadius: '50%',
              background: 'linear-gradient(135deg, #c8f135, #a8d820)',
              border: 'none', cursor: 'pointer', fontSize: '0.8rem',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
          >
            👤
          </button>
        </div>
      </header>

      {/* Content */}
      <main>{renderTab()}</main>

      {/* Bottom Nav */}
      <NavBar active={activeTab} onNavigate={(tab) => {
        setActiveSkill(null);
        setActiveMentalCategory(null);
        setJournalMode(null);
        setActiveTab(tab);
      }} />
    </div>
  );
}

export default function App() {
  return (
    <AppProvider>
      <AppShell />
    </AppProvider>
  );
}

function FullScreenWrapper({ children }) {
  return (
    <div style={{
      background: '#0a0a0a', minHeight: '100vh',
      maxWidth: 480, margin: '0 auto', overflowY: 'auto',
    }}>
      {children}
    </div>
  );
}

function BackHeader({ onBack, label }) {
  return (
    <div style={{
      padding: '16px 20px', borderBottom: '1px solid #1a1a1a',
      display: 'flex', alignItems: 'center',
    }}>
      <button
        onClick={onBack}
        style={{
          background: 'none', border: 'none', color: '#666',
          display: 'flex', alignItems: 'center', gap: 6,
          cursor: 'pointer', fontSize: '0.875rem', padding: 0,
        }}
      >
        ← {label}
      </button>
    </div>
  );
}
