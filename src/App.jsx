import { useState, useEffect } from 'react';
import './index.css';
import { useLocalStorage } from './hooks/useLocalStorage';
import NavBar from './components/NavBar';
import Dashboard from './components/Dashboard';
import Intentions from './components/Intentions';
import Journal from './components/Journal';
import Tips from './components/Tips';
import Progress from './components/Progress';

export default function App() {
  const [activeTab, setActiveTab] = useState('home');
  const [sessions, setSessions] = useLocalStorage('pickle_sessions', []);
  const [intentions, setIntentions] = useLocalStorage('pickle_intentions', []);

  // Get today's intention
  const today = new Date().toISOString().split('T')[0];
  const todayIntention = intentions.find(i => i.date && i.date.startsWith(today));

  const handleSaveIntention = (intention) => {
    setIntentions(prev => {
      const filtered = prev.filter(i => !i.date || !i.date.startsWith(today));
      return [intention, ...filtered];
    });
  };

  const handleSaveSession = (session) => {
    setSessions(prev => [session, ...prev]);
  };

  const handleDeleteSession = (id) => {
    setSessions(prev => prev.filter(s => s.id !== id));
  };

  const navigate = (tab) => {
    setActiveTab(tab);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'home':
        return (
          <Dashboard
            sessions={sessions}
            onNavigate={navigate}
          />
        );
      case 'intentions':
        return (
          <Intentions
            todayIntention={todayIntention}
            onSave={handleSaveIntention}
          />
        );
      case 'journal':
        return (
          <Journal
            sessions={sessions}
            onSave={handleSaveSession}
            onDelete={handleDeleteSession}
            todayIntention={todayIntention}
          />
        );
      case 'tips':
        return <Tips />;
      case 'progress':
        return (
          <Progress
            sessions={sessions}
            intentions={intentions}
          />
        );
      default:
        return null;
    }
  };

  const pageTitles = {
    home: null,
    intentions: 'Pre-Game Intentions',
    journal: 'Game Journal',
    tips: 'Tips & Tricks',
    progress: 'My Progress',
  };

  return (
    <div className="min-h-screen bg-pickle-50">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white/90 backdrop-blur-sm border-b border-gray-100 shadow-sm">
        <div className="max-w-lg mx-auto px-4 py-3 flex items-center gap-3">
          <span className="text-xl">🥒</span>
          <div>
            <span className="font-bold text-gray-800 text-base">PicklePro</span>
            {pageTitles[activeTab] && (
              <span className="text-gray-400 text-sm"> · {pageTitles[activeTab]}</span>
            )}
          </div>
          {todayIntention && activeTab !== 'intentions' && (
            <div className="ml-auto flex items-center gap-1 bg-blue-50 border border-blue-200 px-2.5 py-1 rounded-full">
              <span className="text-blue-600 text-xs font-semibold">🎯 Set</span>
            </div>
          )}
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-lg mx-auto px-4 pt-4 pb-24">
        {renderContent()}
      </main>

      {/* Bottom Navigation */}
      <div className="max-w-lg mx-auto">
        <NavBar active={activeTab} onNavigate={navigate} />
      </div>
    </div>
  );
}
