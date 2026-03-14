import { Home, BookOpen, Target, Brain, TrendingUp, User } from 'lucide-react';

const NAV_ITEMS = [
  { id: 'home', label: 'Home', icon: Home },
  { id: 'skills', label: 'Skills', icon: Target },
  { id: 'journal', label: 'Journal', icon: BookOpen },
  { id: 'mental', label: 'Mental', icon: Brain },
  { id: 'progress', label: 'Progress', icon: TrendingUp },
];

export default function NavBar({ active, onNavigate }) {
  return (
    <nav style={{
      position: 'fixed', bottom: 0, left: 0, right: 0, zIndex: 50,
      background: 'rgba(10,10,10,0.95)',
      backdropFilter: 'blur(20px)',
      WebkitBackdropFilter: 'blur(20px)',
      borderTop: '1px solid #1e1e1e',
    }}>
      <div style={{
        maxWidth: 480, margin: '0 auto',
        display: 'flex', alignItems: 'stretch',
        paddingBottom: 'env(safe-area-inset-bottom, 8px)',
      }}>
        {NAV_ITEMS.map((navItem) => {
          const { id, label } = navItem;
          const NavIcon = navItem.icon;
          const isActive = active === id;
          return (
            <button
              key={id}
              onClick={() => onNavigate(id)}
              style={{
                flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
                justifyContent: 'center', padding: '10px 4px 6px',
                background: 'none', border: 'none', cursor: 'pointer',
                transition: 'all 0.15s ease',
                gap: 3,
              }}
            >
              <div style={{
                width: 36, height: 28, borderRadius: 10,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: isActive ? 'rgba(200,241,53,0.12)' : 'transparent',
                transition: 'all 0.2s',
              }}>
                <NavIcon
                  size={18}
                  color={isActive ? '#c8f135' : '#444'}
                  strokeWidth={isActive ? 2.5 : 2}
                />
              </div>
              <span style={{
                fontSize: '0.62rem', fontWeight: isActive ? 700 : 500,
                color: isActive ? '#c8f135' : '#444',
                letterSpacing: isActive ? '0.02em' : '0',
                transition: 'all 0.15s',
              }}>
                {label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
