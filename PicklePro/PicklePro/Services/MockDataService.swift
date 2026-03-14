import Foundation

struct MockDataService {

    // MARK: - Skills

    static let skills: [Skill] = [
        Skill(
            id: UUID(), category: .thirdShotDrops, title: "Third Shot Drops",
            explanation: "The third shot drop is one of the most important shots in pickleball. After the serve and return, the serving team hits a soft, arcing shot that lands in the opponent's kitchen. This neutralizes the returning team's advantage and allows the serving team to move to the net.",
            coachingTips: [
                "Use a continental grip with soft hands",
                "Bend your knees and get under the ball",
                "Follow through toward your target, not upward",
                "Aim for the middle of the kitchen to reduce angles",
                "Practice from different positions on the court"
            ],
            mentalCues: [
                "Soft hands, quiet mind",
                "Let the paddle do the work",
                "Patience starts with the third shot"
            ],
            commonMistakes: [
                "Hitting too hard — this is a touch shot, not a power shot",
                "Standing too upright — bend those knees",
                "Rushing to the net before the drop lands",
                "Aiming too close to the net"
            ],
            practiceIdeas: [
                "Drop 50 balls from the baseline to the kitchen",
                "Practice with a partner — alternate drops and volleys",
                "Use targets in the kitchen to improve accuracy",
                "Practice drops off both forehand and backhand"
            ],
            icon: "arrow.down.right.circle.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .resets, title: "Resets",
            explanation: "A reset is a defensive shot designed to slow down the pace of play when you're under attack. Instead of trying to match your opponent's power, you absorb the energy and redirect the ball softly into the kitchen. Resets turn defense into neutral or offensive positions.",
            coachingTips: [
                "Keep your paddle out front and ready",
                "Absorb the ball — don't swing at it",
                "Use a short, compact motion",
                "Aim crosscourt for the safest reset angle",
                "Stay balanced and centered"
            ],
            mentalCues: [
                "Absorb, don't react",
                "Soft hands save points",
                "Stay calm in the fire"
            ],
            commonMistakes: [
                "Swinging too hard at a fast ball",
                "Resetting too high — keep it low over the net",
                "Panic-hitting instead of purposeful redirecting",
                "Not being ready with paddle position"
            ],
            practiceIdeas: [
                "Have a partner fire balls at you while you reset",
                "Practice resets from different heights",
                "Work on resetting to specific kitchen zones",
                "Drill transition zone resets moving forward"
            ],
            icon: "arrow.counterclockwise.circle.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .dinkPatterns, title: "Dink Patterns",
            explanation: "Dinking is the art of the soft game at the kitchen line. Strategic dink patterns move your opponents, create openings, and set up attacking opportunities. The best dinkers are patient, precise, and use patterns to control the rally.",
            coachingTips: [
                "Cross-court dinks are safest — the net is lower and the angle is longer",
                "Change direction to move opponents laterally",
                "Use inside-out and inside-in dinks to create angles",
                "Mix height and depth to keep opponents guessing",
                "Stay low with bent knees throughout the dink rally"
            ],
            mentalCues: [
                "Build the point like a chess match",
                "Enjoy the rhythm of the rally",
                "Patience is your weapon"
            ],
            commonMistakes: [
                "Dinking too high — attackable balls",
                "Standing too upright at the kitchen",
                "Being predictable with direction",
                "Losing patience and speeding up too early"
            ],
            practiceIdeas: [
                "Cross-court dink rallies — aim for 20+ in a row",
                "Pattern drill: 2 cross-court, 1 down the line",
                "Target practice with cones in the kitchen",
                "Dink rallies with movement drills"
            ],
            icon: "arrow.left.arrow.right.circle.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .tracking, title: "Tracking the Ball",
            explanation: "Tracking means keeping your eyes on the ball from your opponent's paddle to yours. Great tracking improves reaction time, shot quality, and decision-making. Most players watch the ball inconsistently, which leads to late reactions and poor contact.",
            coachingTips: [
                "Watch the ball leave your opponent's paddle",
                "Track it all the way to your paddle face",
                "Focus on the ball, not where you want to hit it",
                "Use quiet eyes — minimize head movement",
                "Read your opponent's body position for early cues"
            ],
            mentalCues: [
                "See the ball, be the ball",
                "Eyes on contact",
                "Watch it in, send it out"
            ],
            commonMistakes: [
                "Looking up before making contact",
                "Watching the opponent instead of the ball",
                "Moving before reading the shot",
                "Anticipating instead of reacting"
            ],
            practiceIdeas: [
                "Practice calling out ball color or logo as it approaches",
                "Slow-motion dink rallies focusing only on tracking",
                "Close your eyes briefly then track — builds focus",
                "Have partner hit varied shots while you narrate trajectory"
            ],
            icon: "eye.circle.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .speedUpTiming, title: "Speed-Up Timing",
            explanation: "Knowing when to speed up the ball is a critical skill. The best players choose their speed-up moments strategically — attacking when the ball is high, their opponent is off-balance, or after creating an opening with patient dinking.",
            coachingTips: [
                "Speed up when the ball is above the net",
                "Attack the opponent's weaker side or body",
                "Use a compact swing — don't telegraph",
                "Speed up after moving your opponent with dinks",
                "Aim at the hip or shoulder — hardest to defend"
            ],
            mentalCues: [
                "Wait for the right ball",
                "Patient setup, decisive finish",
                "Quality over quantity"
            ],
            commonMistakes: [
                "Speeding up every ball regardless of height",
                "Telegraphing with a big backswing",
                "Attacking from a defensive position",
                "Forcing speed-ups instead of earning them"
            ],
            practiceIdeas: [
                "Dink rally and speed up only when ball is above net",
                "Practice speed-ups to the body target",
                "Drill: 5 dinks then find the right ball to attack",
                "Reaction drills — have partner speed up at you"
            ],
            icon: "bolt.circle.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .courtPositioning, title: "Court Positioning",
            explanation: "Proper court positioning keeps you and your partner in the strongest possible formation. Moving together, covering the middle, and understanding when to be at the kitchen vs. baseline are fundamental to consistent play.",
            coachingTips: [
                "Move together as a unit with your partner",
                "Stay connected — imagine a rope between you",
                "Get to the kitchen line as soon as possible",
                "Cover the middle when in doubt",
                "Stack when it creates favorable matchups"
            ],
            mentalCues: [
                "Move together, win together",
                "The net is your friend",
                "Smart positions create easy shots"
            ],
            commonMistakes: [
                "Leaving the middle exposed",
                "One player at the net, one at the baseline",
                "Not moving laterally with the ball",
                "Standing too close to the kitchen line"
            ],
            practiceIdeas: [
                "Shadow drill — move with partner without a ball",
                "Practice kitchen-line positioning after serves",
                "Drill transition movements from baseline to net",
                "Film your matches and review positioning"
            ],
            icon: "square.grid.2x2.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .transitionZone, title: "Transition Zone",
            explanation: "The transition zone is the area between the baseline and the kitchen line. This is often called 'no man's land' because it's the most difficult area to play from. Learning to move through it patiently is essential.",
            coachingTips: [
                "Don't rush through — move in stages",
                "Split step when your opponent is about to hit",
                "Be ready to reset or drop from this zone",
                "Move forward only when you have time",
                "Keep your paddle up and in front"
            ],
            mentalCues: [
                "Earn your way to the net",
                "Patience through the transition",
                "One good shot at a time forward"
            ],
            commonMistakes: [
                "Sprinting to the net without stopping",
                "Hitting offensive shots from this vulnerable zone",
                "Forgetting the split step",
                "Not being patient enough to earn the net position"
            ],
            practiceIdeas: [
                "Drop and move drill — hit a drop, take 2 steps, split step",
                "Practice volleys from mid-court",
                "Transition drill with partner feeding balls",
                "Work on split step timing"
            ],
            icon: "arrow.right.circle.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .returns, title: "Returns",
            explanation: "A deep, consistent return of serve is one of the most underrated shots in pickleball. A good return pushes the serving team back, gives you time to approach the net, and starts the point on your terms.",
            coachingTips: [
                "Aim deep — past the service line",
                "Hit with moderate pace and good depth",
                "Use slice to keep the ball low",
                "Return to the backhand when possible",
                "Immediately move forward after your return"
            ],
            mentalCues: [
                "Deep return, quick approach",
                "Set the tone for the point",
                "Consistency over power"
            ],
            commonMistakes: [
                "Hitting returns too short",
                "Going for too much power and missing",
                "Not moving forward after the return",
                "Standing too far back on the return"
            ],
            practiceIdeas: [
                "Target practice — aim for the last 3 feet of the court",
                "Practice slice returns for variety",
                "Return and rush drill — return deep and sprint to the net",
                "Practice returns from both sides"
            ],
            icon: "arrow.uturn.backward.circle.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .serves, title: "Serves",
            explanation: "While pickleball serves are underhand and relatively simple, a well-placed serve can start the point in your favor. Consistency is paramount, but adding depth, spin, and placement variety can pressure your opponent.",
            coachingTips: [
                "Prioritize consistency — never miss your serve",
                "Aim deep to push the returner back",
                "Mix up placement — forehand, backhand, body",
                "Use topspin or slice for variety",
                "Develop a reliable pre-serve routine"
            ],
            mentalCues: [
                "Start each point with intention",
                "Serve with purpose, not just to start the rally",
                "Consistency is confidence"
            ],
            commonMistakes: [
                "Trying to hit aces instead of being consistent",
                "No variation in placement",
                "Rushing the serve without a routine",
                "Serving too short"
            ],
            practiceIdeas: [
                "50 serves in a row — focus on depth",
                "Target practice — cones in different zones",
                "Practice serves under simulated pressure",
                "Develop and rehearse your serve routine"
            ],
            icon: "figure.pickleball",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .defense, title: "Defense",
            explanation: "Defense in pickleball means being able to absorb and redirect fast shots while staying in the point. Great defenders stay balanced, keep their paddle ready, and turn their opponent's attacks into neutral or defensive positions.",
            coachingTips: [
                "Keep your paddle up and in front of your body",
                "Stay on the balls of your feet — ready to move",
                "Block hard shots rather than swinging",
                "Aim resets at the opponent's kitchen",
                "Stay low and balanced"
            ],
            mentalCues: [
                "Calm in the storm",
                "Defense wins championships",
                "Absorb and redirect"
            ],
            commonMistakes: [
                "Swinging at hard shots instead of blocking",
                "Paddle too low and not ready",
                "Backing up instead of holding ground",
                "Trying to counter-attack every ball"
            ],
            practiceIdeas: [
                "Block volleys drill — partner feeds hard shots",
                "Defense-to-offense transition drill",
                "Practice low blocks to the kitchen",
                "Rapid-fire defense drill — continuous attacks to defend"
            ],
            icon: "shield.fill",
            isSaved: false
        ),
        Skill(
            id: UUID(), category: .partnerCommunication, title: "Partner Communication",
            explanation: "Great doubles teams communicate constantly. Whether it's calling 'mine' or 'yours,' encouraging after mistakes, or discussing strategy between points, communication builds trust, reduces errors, and creates team chemistry.",
            coachingTips: [
                "Call 'mine' or 'yours' early and clearly",
                "Communicate before the point about strategy",
                "Encourage your partner after every point",
                "Discuss who covers the middle",
                "Use hand signals for serving strategy"
            ],
            mentalCues: [
                "We're in this together",
                "Encourage first, strategize second",
                "Communication is a competitive advantage"
            ],
            commonMistakes: [
                "Staying silent during points",
                "Only talking after bad points",
                "Showing frustration with body language",
                "Not discussing middle ball coverage"
            ],
            practiceIdeas: [
                "Practice calling every ball — mine/yours",
                "Role-play positive communication after mistakes",
                "Before each game, discuss 2 strategic priorities",
                "Practice hand signals for different formations"
            ],
            icon: "bubble.left.and.bubble.right.fill",
            isSaved: false
        ),
    ]

    // MARK: - Mental Lessons

    static let mentalLessons: [MentalLesson] = [
        MentalLesson(
            id: UUID(), category: .confidence, title: "Building Unshakeable Confidence",
            content: "Confidence in pickleball isn't about never making mistakes. It's about trusting your preparation, your training, and your ability to execute under pressure. True confidence comes from process — knowing you've put in the work and focusing on what you can control.\n\nConfident players don't play to avoid mistakes. They play to execute their game plan. They trust their shots, commit to their decisions, and let go of results they can't control.\n\nThe most important thing to understand about confidence is that it's built through repetition, not through winning. Every time you practice a skill with intention, you're depositing into your confidence bank. Withdrawals happen in competition — but the balance grows through consistent, focused practice.",
            keyTakeaways: [
                "Confidence is built through process, not results",
                "Trust your preparation on the court",
                "Commit fully to every shot decision",
                "Focus on what you can control",
                "Confident players play freely and decisively"
            ],
            exercises: [
                "Before each session, write down 3 things you've improved",
                "After each game, identify 2 shots you executed well",
                "Practice your weakest shot until it becomes a strength",
                "Visualize confident play for 2 minutes before matches"
            ],
            icon: "star.fill",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .patience, title: "The Power of Patience",
            content: "Patience is arguably the most important mental skill in pickleball. The best players understand that points are built, not won in a single shot. They let rallies develop, wait for the right ball, and never force opportunities that aren't there.\n\nPatience means trusting the process within each point. It means dinking one more time when you want to speed up. It means hitting one more drop when you want to drive. It means staying disciplined even when you feel the urge to take a risky shot.\n\nThe paradox of patience is that the more patient you are, the more opportunities you create. Opponents make mistakes when they feel the pressure of a patient, disciplined opponent who won't give them free points.",
            keyTakeaways: [
                "Points are built, not won in a single shot",
                "Patience creates more opportunities than aggression",
                "Trust the rally — the right ball will come",
                "Disciplined patience puts pressure on opponents",
                "One more dink is often the winning strategy"
            ],
            exercises: [
                "Play a game where you dink 5 times before any speed-up",
                "Practice counting dinks in a rally — aim for 10+",
                "After each point, rate your patience from 1-5",
                "Set a goal: zero rushed speed-ups this session"
            ],
            icon: "hourglass",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .frustrationControl, title: "Managing Frustration on Court",
            content: "Every player gets frustrated. The difference between good players and great players is how quickly they release frustration and return to the present moment. Frustration is a signal — it tells you something matters to you. But holding onto it poisons your next shot, your next game, and your partner's confidence.\n\nThe key is to acknowledge frustration without letting it drive your decisions. Feel it, name it, and let it go. Then refocus on the next point with a clear mind.\n\nDevelop a reset routine: take a breath, touch your paddle strings, and say a cue word that brings you back to the present. The best players have a 3-second reset that clears their emotional slate.",
            keyTakeaways: [
                "Frustration is natural — holding onto it is the problem",
                "Develop a 3-second reset routine",
                "Never let the last point affect the next one",
                "Your body language affects your partner",
                "Release frustration physically — exhale, shake it off"
            ],
            exercises: [
                "Create a personal reset cue (word, breath, gesture)",
                "Practice intentional breathing between every point",
                "After a mistake, immediately say 'next' and move on",
                "Film yourself and review your body language after errors"
            ],
            icon: "wind",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .partnerChemistry, title: "Building Partner Chemistry",
            content: "In doubles pickleball, your relationship with your partner is as important as your individual skill. Great teams aren't just two good players — they're two players who trust each other, communicate well, and elevate each other's games.\n\nThe foundation of partner chemistry is encouragement. Every touch, every fist bump, every 'nice shot' builds connection and confidence. When your partner misses, your response matters more than the miss itself.\n\nAdapt to your partner's style rather than expecting them to adapt to yours. If your partner likes to speed up, be ready to cover. If they prefer to dink, be patient with them. The best partners make adjustments, not demands.",
            keyTakeaways: [
                "Encouragement is the foundation of great partnerships",
                "Adapt to your partner — don't demand they adapt to you",
                "Communication before, during, and after points",
                "Your reaction to partner mistakes matters most",
                "Great teams trust each other and cover for each other"
            ],
            exercises: [
                "Give your partner a fist bump after every single point",
                "Before each game, agree on one strategic focus together",
                "Practice giving only positive feedback for an entire session",
                "Discuss strengths — play to each other's game"
            ],
            icon: "person.2.fill",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .focusUnderPressure, title: "Performing Under Pressure",
            content: "Pressure is a privilege — it means the moment matters. The best pickleball players don't try to eliminate pressure; they learn to perform with it. They channel nervous energy into focused intensity.\n\nThe secret to pressure performance is narrowing your focus. Don't think about the score, the crowd, or the outcome. Think about one thing: executing the next shot with quality. Process focus eliminates pressure because you're not thinking about what could go wrong.\n\nDevelop a pre-point routine that anchors you in the present. Touch your paddle, set your feet, take a breath, and play. This routine becomes automatic under pressure and gives your mind something concrete to focus on.",
            keyTakeaways: [
                "Pressure means the moment matters — embrace it",
                "Narrow your focus to the next shot only",
                "Process focus eliminates outcome anxiety",
                "Develop an automatic pre-point routine",
                "Nervous energy can become focused intensity"
            ],
            exercises: [
                "Practice with simulated pressure — play points from 9-9",
                "Create and rehearse your pre-point routine",
                "Practice deep breathing during changeovers",
                "Visualize pressure situations and see yourself executing"
            ],
            icon: "scope",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .bouncingBack, title: "Bouncing Back from Mistakes",
            content: "Mistakes are inevitable in pickleball. Even the best players in the world make errors every game. What separates elite players from the rest is their ability to bounce back immediately.\n\nThe key insight is that your response to a mistake is more important than the mistake itself. A missed drop shot is one point. But if that miss leads to frustration that affects your next three points, it's now four points.\n\nDevelop the '1-point memory' mindset. After each point — good or bad — reset completely. The next point is a fresh start with no memory of what just happened.",
            keyTakeaways: [
                "Your response to mistakes matters more than the mistakes",
                "Develop a '1-point memory' mindset",
                "Every point is a fresh start",
                "Mistakes are data, not failures",
                "The best players have the shortest memories"
            ],
            exercises: [
                "After every error, take one breath and physically reset",
                "Track how many points it takes you to recover after errors",
                "Practice the phrase: 'That's data, not failure'",
                "Set a goal: recover within 1 point of any mistake"
            ],
            icon: "arrow.counterclockwise",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .communication, title: "Effective On-Court Communication",
            content: "Communication in pickleball doubles goes far beyond calling 'mine' or 'yours.' It's about creating a shared language, maintaining emotional connection, and building strategic alignment throughout the match.\n\nGreat communicators talk before the point (strategy), during the point (calls), and after the point (encouragement or adjustment). They use body language, verbal cues, and emotional intelligence to keep the partnership strong.\n\nThe most important communication is encouragement after mistakes. When your partner misses, what they need most is support, not instruction. Save tactical discussions for between games.",
            keyTakeaways: [
                "Communicate before, during, and after every point",
                "Encouragement after mistakes builds trust",
                "Save instruction for between games",
                "Use clear, early ball calls",
                "Body language is communication too"
            ],
            exercises: [
                "Practice calling every ball clearly and early",
                "Give encouragement after every error your partner makes",
                "Discuss strategy before every game starts",
                "Check in with your partner during changeovers"
            ],
            icon: "bubble.left.and.bubble.right.fill",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .selfTalk, title: "Identity and Self-Talk",
            content: "The way you talk to yourself on the court directly affects your performance. Negative self-talk ('I always miss that shot') reinforces failure patterns. Positive, process-oriented self-talk ('Stay low, soft hands') reinforces execution patterns.\n\nYour identity as a player matters too. If you see yourself as 'someone who chokes under pressure,' you'll find ways to confirm that belief. If you see yourself as 'someone who competes hard and stays focused,' you'll find ways to confirm that instead.\n\nChoose an identity statement: 'I am a patient, disciplined player who trusts the process.' Repeat it. Believe it. Play it.",
            keyTakeaways: [
                "Self-talk directly affects performance",
                "Replace negative talk with process cues",
                "Your identity shapes your behavior",
                "Choose who you want to be as a player",
                "Repeat your identity statement daily"
            ],
            exercises: [
                "Write your player identity statement",
                "Notice negative self-talk and replace it with a process cue",
                "Say your identity statement before every session",
                "Track self-talk patterns in your journal"
            ],
            icon: "brain.head.profile",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .discipline, title: "The Discipline to Improve",
            content: "Discipline in pickleball isn't about punishment or forcing yourself to grind. It's about consistently showing up, practicing with intention, and committing to the process even when progress feels slow.\n\nThe most disciplined players don't rely on motivation — they rely on habits. They practice the same skills regularly, journal consistently, and approach every session with a plan.\n\nDiscipline compounds. Each day you show up with intention, you're building something. The players who improve fastest aren't the most talented — they're the most consistent.",
            keyTakeaways: [
                "Discipline is about consistency, not intensity",
                "Build habits instead of relying on motivation",
                "Show up with a plan every session",
                "Small daily improvements compound dramatically",
                "Consistency beats talent over time"
            ],
            exercises: [
                "Set a weekly practice schedule and stick to it",
                "Start each session with a specific skill focus",
                "Journal after every play session — no exceptions",
                "Track your consistency streak and protect it"
            ],
            icon: "checkmark.shield.fill",
            isSaved: false
        ),
        MentalLesson(
            id: UUID(), category: .processMindset, title: "Embracing the Process",
            content: "The process mindset is the foundation of everything PicklePro teaches. It means shifting your focus from outcomes (winning, losing, scores) to process (execution, improvement, intention).\n\nWhen you focus on results, you create anxiety about the future and frustration about the past. When you focus on process, you stay present, play freely, and paradoxically perform better.\n\nThe process is simple: set an intention, play with focus, reflect honestly, and adjust. Every day. The outcomes you want will come as a natural byproduct of committing to this process.\n\nThe beauty of process focus is that you're always succeeding. Did you play with intention today? Success. Did you reflect honestly? Success. Did you learn something? Success. The process never fails you.",
            keyTakeaways: [
                "Focus on process, not outcomes",
                "Process focus reduces anxiety and improves performance",
                "Set intentions before you play",
                "Reflect honestly after you play",
                "You succeed every day you commit to the process"
            ],
            exercises: [
                "Before every session, write one process goal (not outcome goal)",
                "During play, focus only on execution — ignore the score",
                "After play, evaluate how well you stuck to your intention",
                "Replace 'I need to win' with 'I need to execute'"
            ],
            icon: "gearshape.2.fill",
            isSaved: false
        ),
    ]

    // MARK: - AI Coach Insights

    static let coachInsights: [AICoachInsight] = [
        AICoachInsight(
            id: UUID(), date: Date(), type: .dailyCoaching,
            title: "Your Third Shot Drop is Improving",
            content: "Based on your recent journal entries, you've been consistently focusing on third shot drops. Your patience score has increased 15% this week. Keep focusing on soft hands and getting under the ball. Today's focus: try hitting drops to the middle of the kitchen to reduce your opponents' angles.",
            actionItems: [
                "Practice 20 drops before your next session",
                "Focus on follow-through toward target",
                "Rate your drops 1-5 after each game"
            ],
            isRead: false
        ),
        AICoachInsight(
            id: UUID(), date: Date(), type: .mentalPattern,
            title: "Frustration Pattern Detected",
            content: "I've noticed you tend to get frustrated after losing leads. This has appeared in 3 of your last 5 journal entries. Let's work on developing a stronger reset routine. Remember: the score doesn't change how you execute your next shot.",
            actionItems: [
                "Create a 3-second reset routine",
                "Practice breathing between points",
                "Say 'next point' after every error"
            ],
            isRead: false
        ),
        AICoachInsight(
            id: UUID(), date: Date(), type: .encouragement,
            title: "7-Day Streak! You're Building Momentum",
            content: "You've journaled for 7 days in a row. This consistency is exactly what builds long-term improvement. Players who journal regularly improve 2x faster because they're learning from every session. Keep it up!",
            actionItems: [
                "Celebrate this milestone",
                "Set a goal for 14 days",
                "Share your streak with a playing partner"
            ],
            isRead: true
        ),
    ]

    // MARK: - Inspirational Quotes

    static let quotes: [String] = [
        "Patience creates opportunity.",
        "Your mindset is part of your shot selection.",
        "Play with purpose today.",
        "Compete hard. Stay loose.",
        "Growth compounds.",
        "Enjoy building the point.",
        "Play free today.",
        "Enjoy the rally. The lesson is inside it.",
        "Growth is easier when you love the work.",
        "Play with intention. Play with joy.",
        "The players who improve most learn to enjoy repetition.",
        "Trust the process. The results will follow.",
        "One good shot at a time.",
        "The best shot is the one you commit to.",
        "Soft hands, quiet mind.",
        "Every rep is a deposit in your confidence bank.",
        "Discipline is choosing between what you want now and what you want most.",
        "The court is your classroom today.",
        "Progress is rarely linear. Trust it anyway.",
        "Your best pickleball is played with freedom and focus.",
    ]
}
