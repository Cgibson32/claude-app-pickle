import SwiftUI

struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [CoachMessage] = [
        CoachMessage(
            content: "Hey! I'm your PicklePro AI Coach. I've been analyzing your recent sessions and I have some thoughts. What would you like to work on today?",
            isFromCoach: true,
            timestamp: Date()
        )
    ]
    @State private var inputText: String = ""
    @State private var showSuggestions = true

    let suggestions = [
        "How can I improve my third shot drop?",
        "I keep getting frustrated during games",
        "Help me with partner communication",
        "What should I focus on today?",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        }
                        .onChange(of: messages.count) { _, _ in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Suggestions
                    if showSuggestions {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        sendMessage(suggestion)
                                        showSuggestions = false
                                    }) {
                                        Text(suggestion)
                                            .font(PickleProTypography.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(PickleProColors.surfaceLight)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 8)
                    }

                    // Input Bar
                    HStack(spacing: 12) {
                        TextField("Ask your coach...", text: $inputText)
                            .font(PickleProTypography.body)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(PickleProColors.cardBackground)
                            .cornerRadius(20)

                        Button(action: {
                            if !inputText.isEmpty {
                                sendMessage(inputText)
                                inputText = ""
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(
                                    inputText.isEmpty
                                        ? PickleProColors.textTertiary
                                        : PickleProColors.accent
                                )
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(PickleProColors.cardBackground.opacity(0.5))
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(PickleProColors.accent)
                }
            }
        }
    }

    private func sendMessage(_ text: String) {
        let userMessage = CoachMessage(content: text, isFromCoach: false, timestamp: Date())
        messages.append(userMessage)

        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let response = generateCoachResponse(for: text)
            let coachMessage = CoachMessage(content: response, isFromCoach: true, timestamp: Date())
            messages.append(coachMessage)
        }
    }

    private func generateCoachResponse(for input: String) -> String {
        let lowered = input.lowercased()
        if lowered.contains("third shot") || lowered.contains("drop") {
            return "Great question! Your third shot drop is all about soft hands and getting under the ball. Here's what I'd focus on:\n\n1. Bend your knees more — get low\n2. Use a continental grip\n3. Follow through toward your target, not upward\n4. Aim for the middle of the kitchen\n\nRemember: \"Soft hands, quiet mind.\" The third shot drop is as much mental as it is technical. Trust the touch."
        } else if lowered.contains("frustrat") || lowered.contains("angry") || lowered.contains("upset") {
            return "Frustration is completely normal — it means you care about improving. The key is developing a quick reset routine:\n\n1. Take one deep breath\n2. Touch your paddle strings\n3. Say \"next\" to yourself\n4. Set your feet for the next point\n\nRemember: your response to a mistake matters more than the mistake itself. The best players have the shortest memories."
        } else if lowered.contains("partner") || lowered.contains("communication") {
            return "Partner communication is a competitive advantage! Here's how to level up:\n\n1. Call every ball clearly — \"mine\" or \"yours\"\n2. Encourage after every single point\n3. Discuss strategy before each game\n4. Use positive body language, especially after mistakes\n\n\"We're in this together\" should be your mindset. The best partnerships are built on trust and encouragement."
        } else if lowered.contains("focus") || lowered.contains("today") {
            return "Based on your recent sessions, I'd suggest focusing on patience today. Your dinking has been improving, but I've noticed you tend to speed up too early.\n\nToday's focus: \"Let the rally breathe.\"\n\nTry this: in your dink rallies, hit at least 5 dinks before considering a speed-up. Wait for a ball that's clearly above the net. Quality over quantity."
        } else {
            return "That's a great area to work on. Here's my advice: approach every session with one specific intention. Don't try to fix everything at once.\n\nPick one technical skill and one mental cue. Focus on those for the entire session. Improvement comes from intentional repetition, not scattered effort.\n\n\"Growth compounds. Trust the process.\""
        }
    }
}

struct ChatBubble: View {
    let message: CoachMessage

    var body: some View {
        HStack {
            if !message.isFromCoach { Spacer() }

            VStack(alignment: message.isFromCoach ? .leading : .trailing, spacing: 4) {
                if message.isFromCoach {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(PickleProColors.accent)
                        Text("Coach")
                            .font(PickleProTypography.captionBold)
                            .foregroundColor(PickleProColors.accent)
                    }
                }

                Text(message.content)
                    .font(PickleProTypography.callout)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        message.isFromCoach
                            ? PickleProColors.cardBackground
                            : PickleProColors.accent.opacity(0.2)
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                message.isFromCoach
                                    ? PickleProColors.accent.opacity(0.2)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.78, alignment: message.isFromCoach ? .leading : .trailing)

            if message.isFromCoach { Spacer() }
        }
    }
}
