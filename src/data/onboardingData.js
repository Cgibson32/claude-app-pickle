export const EXPERIENCE_LEVELS = [
  {
    id: 'beginner',
    label: 'Beginner',
    description: 'Learning the rules, building basic skills',
    dupr: '2.0 – 3.0',
  },
  {
    id: 'intermediate',
    label: 'Intermediate',
    description: 'Consistent rallies, developing strategy',
    dupr: '3.0 – 3.75',
  },
  {
    id: 'advanced',
    label: 'Advanced',
    description: 'Strong fundamentals, competitive mindset',
    dupr: '3.75 – 4.5',
  },
  {
    id: 'competitive',
    label: 'Competitive',
    description: 'Tournament-level, always optimizing',
    dupr: '4.5+',
  },
];

export const PLAY_FREQUENCIES = [
  { id: 'rarely', label: 'Once a month or less', description: 'Every session counts' },
  { id: 'weekly', label: '1–2 times a week', description: 'Building a foundation' },
  { id: 'frequent', label: '3–4 times a week', description: 'Serious training' },
  { id: 'daily', label: 'Almost every day', description: 'Competitor\'s schedule' },
];

export const STRUGGLE_OPTIONS = [
  { id: 'patience', label: 'Staying Patient', description: 'Waiting for the right ball' },
  { id: 'thirds', label: 'Third Shot Drops', description: 'The most important shot' },
  { id: 'dinking', label: 'Dink Consistency', description: 'Winning at the kitchen' },
  { id: 'pressure', label: 'Playing Under Pressure', description: 'Performing when it counts' },
  { id: 'communication', label: 'Partner Communication', description: 'Playing as one unit' },
  { id: 'frustration', label: 'Managing Frustration', description: 'Emotional control' },
  { id: 'consistency', label: 'Overall Consistency', description: 'Reducing unforced errors' },
  { id: 'positioning', label: 'Court Positioning', description: 'Right place, right time' },
  { id: 'resets', label: 'Resets & Defense', description: 'Neutralizing attacks' },
  { id: 'confidence', label: 'Confidence Under Pressure', description: 'Trusting yourself' },
  { id: 'speedup', label: 'When to Speed Up', description: 'Timing your attacks' },
  { id: 'transition', label: 'Transition Zone', description: 'Moving to the kitchen' },
];

export const TECHNICAL_WEAKNESSES = [
  { id: 'third-shot', label: 'Third Shot Drop', description: 'The bridge from serve to net' },
  { id: 'dink-xc', label: 'Cross-Court Dinking', description: 'Angles and placement' },
  { id: 'backhand', label: 'Backhand Shots', description: 'Strength on the weak side' },
  { id: 'overhead', label: 'Overheads / Smashes', description: 'Putting away high balls' },
  { id: 'serve', label: 'Serve Consistency', description: 'Starting the point strong' },
  { id: 'return', label: 'Return of Serve', description: 'Deep, neutralizing returns' },
  { id: 'volley', label: 'Volley Mechanics', description: 'Clean hands at the net' },
  { id: 'footwork', label: 'Footwork & Movement', description: 'Getting to the ball in balance' },
  { id: 'reset', label: 'Reset Shots', description: 'Taking pace off under pressure' },
  { id: 'lob', label: 'Lob Defense', description: 'Recovering when pushed back' },
  { id: 'speedup-tech', label: 'Speed-Up Technique', description: 'Quick hands, shot selection' },
  { id: 'kitchen-control', label: 'Kitchen Line Control', description: 'Owning the net' },
];

export const MENTAL_WEAKNESSES = [
  { id: 'frustration', label: 'Frustration Control', description: 'Keeping composure after errors' },
  { id: 'pressure', label: 'High-Pressure Moments', description: 'Performing on game point' },
  { id: 'mistakes', label: 'Bouncing Back from Errors', description: 'Short memory, next ball' },
  { id: 'patience-mental', label: 'Patience in Rallies', description: 'Waiting for your opportunity' },
  { id: 'confidence-mental', label: 'Confidence & Self-Belief', description: 'Trusting the work' },
  { id: 'focus', label: 'Staying Focused', description: 'Present point after point' },
  { id: 'partner', label: 'Partner Chemistry', description: 'Building trust on court' },
  { id: 'identity', label: 'Negative Self-Talk', description: 'Replacing criticism with coaching' },
  { id: 'process', label: 'Score Obsession', description: 'Shifting to growth focus' },
  { id: 'communication', label: 'On-Court Communication', description: 'Expressing strategy under stress' },
];

export const GOAL_OPTIONS = [
  { id: 'compete', label: 'Compete in tournaments', description: 'Test yourself against the best' },
  { id: 'improve', label: 'Consistently improve', description: 'Measurable growth' },
  { id: 'enjoy', label: 'Enjoy the game more', description: 'Play with purpose' },
  { id: 'mental', label: 'Build mental toughness', description: 'The edge most players lack' },
  { id: 'social', label: 'Play with confidence', description: 'Own any court you step on' },
  { id: 'health', label: 'Stay active and healthy', description: 'Performance and wellness' },
  { id: 'partner', label: 'Become a great partner', description: 'The player everyone wants' },
  { id: 'coach', label: 'Reach advanced level', description: 'Push your ceiling higher' },
];

export const PLAYER_TYPE_OPTIONS = [
  { id: 'patient', label: 'The Patient Builder', description: 'Calm, consistent, wins through strategy' },
  { id: 'aggressive', label: 'The Aggressive Attacker', description: 'Seizes opportunities, high intensity' },
  { id: 'all-around', label: 'The All-Around Player', description: 'Reads the game, adapts to anything' },
  { id: 'teammate', label: 'The Elite Teammate', description: 'Communicates, supports, elevates partners' },
];

export const DOUBLES_SINGLES_OPTIONS = [
  { id: 'doubles', label: 'Doubles', description: 'Team play' },
  { id: 'singles', label: 'Singles', description: 'One-on-one' },
  { id: 'both', label: 'Both', description: 'All formats' },
];
