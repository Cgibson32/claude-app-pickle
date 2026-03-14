export const EXPERIENCE_LEVELS = [
  {
    id: 'beginner',
    label: 'Beginner',
    description: 'Learning the rules, building basic skills — every champion started here',
    dupr: '2.0 – 3.0',
    emoji: '🌱',
  },
  {
    id: 'intermediate',
    label: 'Intermediate',
    description: 'Consistent rallies, developing strategy — the growth zone',
    dupr: '3.0 – 3.75',
    emoji: '📈',
  },
  {
    id: 'advanced',
    label: 'Advanced',
    description: 'Strong fundamentals, competitive mindset — refining the details',
    dupr: '3.75 – 4.5',
    emoji: '⚡',
  },
  {
    id: 'competitive',
    label: 'Competitive',
    description: 'Tournament-level, always optimizing — chasing mastery',
    dupr: '4.5+',
    emoji: '🏆',
  },
];

export const PLAY_FREQUENCIES = [
  { id: 'rarely', label: 'Once a month or less', description: 'Every session counts even more', emoji: '🌙' },
  { id: 'weekly', label: '1–2 times a week', description: 'Building a solid foundation', emoji: '📅' },
  { id: 'frequent', label: '3–4 times a week', description: 'Serious about growth', emoji: '🔥' },
  { id: 'daily', label: 'Almost every day', description: 'The dedication of a competitor', emoji: '⚡' },
];

export const STRUGGLE_OPTIONS = [
  { id: 'patience', label: 'Staying Patient', description: 'Waiting for the right ball instead of forcing', emoji: '⏳' },
  { id: 'thirds', label: 'Third Shot Drops', description: 'The most important shot in the game', emoji: '🎯' },
  { id: 'dinking', label: 'Dink Consistency', description: 'Winning the battle at the kitchen', emoji: '🏓' },
  { id: 'pressure', label: 'Playing Under Pressure', description: 'Performing when the score is tight', emoji: '😤' },
  { id: 'communication', label: 'Partner Communication', description: 'Being on the same page as your partner', emoji: '🤝' },
  { id: 'frustration', label: 'Managing Frustration', description: 'Keeping emotions from hijacking your game', emoji: '🌊' },
  { id: 'consistency', label: 'Overall Consistency', description: 'Reducing unforced errors', emoji: '📊' },
  { id: 'positioning', label: 'Court Positioning', description: 'Being in the right place at the right time', emoji: '📍' },
  { id: 'resets', label: 'Resets & Defense', description: 'Turning defense into neutral', emoji: '🛡️' },
  { id: 'confidence', label: 'Confidence Under Pressure', description: 'Trusting yourself in big moments', emoji: '💪' },
  { id: 'speedup', label: 'When to Speed Up', description: 'Picking the right moment to attack', emoji: '⚡' },
  { id: 'transition', label: 'Transition Zone', description: 'Moving from baseline to kitchen efficiently', emoji: '🚶' },
];

export const TECHNICAL_WEAKNESSES = [
  { id: 'third-shot', label: 'Third Shot Drop', description: 'The bridge from serve to net', emoji: '🎯' },
  { id: 'dink-xc', label: 'Cross-Court Dinking', description: 'Angles and placement at the kitchen', emoji: '↗️' },
  { id: 'backhand', label: 'Backhand Shots', description: 'Strength and accuracy on the weak side', emoji: '🤚' },
  { id: 'overhead', label: 'Overheads / Smashes', description: 'Putting away high balls', emoji: '🔨' },
  { id: 'serve', label: 'Serve Consistency', description: 'Starting the point strong', emoji: '🎾' },
  { id: 'return', label: 'Return of Serve', description: 'Neutralizing with a deep return', emoji: '↩️' },
  { id: 'volley', label: 'Volley Mechanics', description: 'Clean hands at the net', emoji: '✋' },
  { id: 'footwork', label: 'Footwork & Movement', description: 'Getting to the ball in balance', emoji: '👟' },
  { id: 'reset', label: 'Reset Shots', description: 'Taking pace off under pressure', emoji: '🔄' },
  { id: 'lob', label: 'Lob Defense', description: 'Recovering when pushed back', emoji: '☁️' },
  { id: 'speedup-tech', label: 'Speed-Up Technique', description: 'Quick hands and shot selection', emoji: '⚡' },
  { id: 'kitchen-control', label: 'Kitchen Line Control', description: 'Owning the most important real estate', emoji: '🏠' },
];

export const MENTAL_WEAKNESSES = [
  { id: 'frustration', label: 'Frustration Control', description: 'Keeping your cool after missed shots', emoji: '🌊' },
  { id: 'pressure', label: 'High-Pressure Moments', description: 'Performing when the game is on the line', emoji: '😬' },
  { id: 'mistakes', label: 'Bouncing Back from Errors', description: 'Short memory, next ball mentality', emoji: '🔆' },
  { id: 'patience-mental', label: 'Patience in Rallies', description: 'Waiting for your opportunity', emoji: '🧘' },
  { id: 'confidence-mental', label: 'Confidence & Self-Belief', description: 'Trusting the work you\'ve put in', emoji: '⚡' },
  { id: 'focus', label: 'Staying Focused', description: 'Being present point after point', emoji: '🔭' },
  { id: 'partner', label: 'Partner Chemistry', description: 'Building connection and trust on court', emoji: '💫' },
  { id: 'identity', label: 'Negative Self-Talk', description: 'Replacing criticism with coaching', emoji: '🪞' },
  { id: 'process', label: 'Score Obsession', description: 'Shifting focus from results to growth', emoji: '🌱' },
  { id: 'communication', label: 'On-Court Communication', description: 'Expressing strategy clearly under stress', emoji: '📢' },
];

export const GOAL_OPTIONS = [
  { id: 'compete', label: 'Compete in tournaments', description: 'Test yourself against the best', emoji: '🏆' },
  { id: 'improve', label: 'Consistently get better', description: 'Steady, measurable improvement', emoji: '📈' },
  { id: 'enjoy', label: 'Enjoy the game more', description: 'Fall deeper in love with pickleball', emoji: '😄' },
  { id: 'mental', label: 'Build a stronger mental game', description: 'The edge most players overlook', emoji: '🧠' },
  { id: 'social', label: 'Play with confidence socially', description: 'Feel comfortable on any court', emoji: '👥' },
  { id: 'health', label: 'Stay active and healthy', description: 'Use the game for your well-being', emoji: '💪' },
  { id: 'partner', label: 'Become a great partner', description: 'The player everyone wants to play with', emoji: '🤝' },
  { id: 'coach', label: 'Reach advanced skill level', description: 'Push your ceiling higher', emoji: '⚡' },
];

export const PLAYER_TYPE_OPTIONS = [
  { id: 'patient', label: 'The Patient Builder', description: 'Calm, consistent, wins through strategy and outlasting opponents', emoji: '🧘' },
  { id: 'aggressive', label: 'The Aggressive Attacker', description: 'Energetic, seizes opportunities, brings high intensity every point', emoji: '⚡' },
  { id: 'all-around', label: 'The All-Around Player', description: 'Flexible, reads the game, adapts to any situation or opponent', emoji: '🎯' },
  { id: 'teammate', label: 'The Elite Teammate', description: 'Communicates, supports, and elevates every partner they play with', emoji: '🤝' },
];

export const DOUBLES_SINGLES_OPTIONS = [
  { id: 'doubles', label: 'Doubles', description: 'Primary focus on team play', emoji: '👥' },
  { id: 'singles', label: 'Singles', description: 'One-on-one competition', emoji: '🎯' },
  { id: 'both', label: 'Both', description: 'Enjoy all formats', emoji: '⚡' },
];
