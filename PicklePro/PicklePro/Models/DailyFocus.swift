import Foundation

struct DailyFocus: Identifiable, Codable {
    let id: UUID
    let date: Date
    var performanceIntention: String
    var mentalIntention: String
    var joyIntention: String
    var skillFocus: String
    var inspirationalMessage: String
    var isCompleted: Bool

    static let example = DailyFocus(
        id: UUID(),
        date: Date(),
        performanceIntention: "Third Shot Drops",
        mentalIntention: "Let the rally breathe",
        joyIntention: "Enjoy the rhythm of building points",
        skillFocus: "Focus on soft hands at the kitchen line",
        inspirationalMessage: "Patience creates opportunity.",
        isCompleted: false
    )
}

struct IntentionOption: Identifiable {
    let id = UUID()
    let category: String
    let text: String
    let icon: String
}

let performanceIntentions = [
    IntentionOption(category: "Drops", text: "Execute consistent third shot drops", icon: "arrow.down.right"),
    IntentionOption(category: "Resets", text: "Stay calm and reset when attacked", icon: "arrow.counterclockwise"),
    IntentionOption(category: "Dinks", text: "Move opponents with dink patterns", icon: "arrow.left.arrow.right"),
    IntentionOption(category: "Positioning", text: "Move together with my partner", icon: "person.2.fill"),
    IntentionOption(category: "Speed-ups", text: "Choose smart moments to speed up", icon: "bolt.fill"),
    IntentionOption(category: "Defense", text: "Stay balanced and absorb attacks", icon: "shield.fill"),
    IntentionOption(category: "Returns", text: "Deep, consistent returns", icon: "arrow.uturn.backward"),
    IntentionOption(category: "Transition", text: "Work through the transition zone patiently", icon: "arrow.forward"),
]

let mentalIntentions = [
    IntentionOption(category: "Patience", text: "Let the rally breathe", icon: "wind"),
    IntentionOption(category: "Focus", text: "Stay present point by point", icon: "eye.fill"),
    IntentionOption(category: "Composure", text: "Release mistakes quickly", icon: "leaf.fill"),
    IntentionOption(category: "Confidence", text: "Trust my preparation", icon: "star.fill"),
    IntentionOption(category: "Communication", text: "Encourage my partner consistently", icon: "bubble.left.fill"),
    IntentionOption(category: "Resilience", text: "Compete hard from start to finish", icon: "flame.fill"),
    IntentionOption(category: "Process", text: "Focus on execution, not the score", icon: "gearshape.fill"),
    IntentionOption(category: "Calm", text: "Breathe between points", icon: "heart.fill"),
]

let joyIntentions = [
    IntentionOption(category: "Play", text: "Play free today", icon: "figure.pickleball"),
    IntentionOption(category: "Rhythm", text: "Enjoy the rhythm of the rally", icon: "metronome.fill"),
    IntentionOption(category: "Connection", text: "Appreciate playing with others", icon: "person.2.fill"),
    IntentionOption(category: "Growth", text: "Growth is easier when you love the work", icon: "arrow.up.right"),
    IntentionOption(category: "Presence", text: "Stay loose and playful", icon: "face.smiling.fill"),
    IntentionOption(category: "Fun", text: "Compete hard. Stay loose.", icon: "trophy.fill"),
    IntentionOption(category: "Learning", text: "Enjoy learning something new today", icon: "lightbulb.fill"),
    IntentionOption(category: "Gratitude", text: "Be grateful for time on the court", icon: "sun.max.fill"),
]
