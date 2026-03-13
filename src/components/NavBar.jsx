import { Home, BookOpen, Target, Lightbulb, TrendingUp } from 'lucide-react';

const navItems = [
  { id: 'home', label: 'Home', icon: Home },
  { id: 'intentions', label: 'Intent', icon: Target },
  { id: 'journal', label: 'Journal', icon: BookOpen },
  { id: 'tips', label: 'Tips', icon: Lightbulb },
  { id: 'progress', label: 'Progress', icon: TrendingUp },
];

export default function NavBar({ active, onNavigate }) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 shadow-lg z-50">
      <div className="max-w-lg mx-auto flex">
        {navItems.map(({ id, label, icon: Icon }) => {
          const isActive = active === id;
          return (
            <button
              key={id}
              onClick={() => onNavigate(id)}
              className={`flex-1 flex flex-col items-center justify-center py-2.5 gap-0.5 transition-all active:scale-95
                ${isActive ? 'text-pickle-600' : 'text-gray-400'}`}
            >
              <div className={`p-1.5 rounded-xl transition-all ${isActive ? 'bg-pickle-50' : ''}`}>
                <Icon className={`w-5 h-5 ${isActive ? 'text-pickle-600' : 'text-gray-400'}`} />
              </div>
              <span className={`text-xs font-medium ${isActive ? 'text-pickle-600' : 'text-gray-400'}`}>
                {label}
              </span>
              {isActive && (
                <div className="w-1 h-1 rounded-full bg-pickle-500" />
              )}
            </button>
          );
        })}
      </div>
    </nav>
  );
}
