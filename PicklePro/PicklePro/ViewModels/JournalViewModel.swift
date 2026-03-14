import Foundation
import SwiftUI

class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var currentEntry: JournalEntry
    @Published var isEditing: Bool = false
    @Published var currentStep: Int = 0

    let totalSteps = 7

    init() {
        self.currentEntry = JournalEntry(
            id: UUID(),
            date: Date(),
            mood: .focused,
            energyLevel: 3,
            whatWentWell: "",
            patienceBreakdown: "",
            skillNeedingWork: "",
            communicationRating: 3,
            emotionsDescription: "",
            improvementGoal: "",
            overallSessionRating: 3,
            playType: .recreational,
            tags: []
        )
        loadEntries()
    }

    func saveEntry() {
        entries.insert(currentEntry, at: 0)
        saveEntries()
        resetEntry()
    }

    func resetEntry() {
        currentEntry = JournalEntry(
            id: UUID(),
            date: Date(),
            mood: .focused,
            energyLevel: 3,
            whatWentWell: "",
            patienceBreakdown: "",
            skillNeedingWork: "",
            communicationRating: 3,
            emotionsDescription: "",
            improvementGoal: "",
            overallSessionRating: 3,
            playType: .recreational,
            tags: []
        )
        currentStep = 0
        isEditing = false
    }

    func nextStep() {
        withAnimation(.easeInOut) {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    func previousStep() {
        withAnimation(.easeInOut) {
            currentStep = max(currentStep - 1, 0)
        }
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "journalEntries")
        }
    }

    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "journalEntries"),
           let saved = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            entries = saved
        } else {
            entries = [JournalEntry.example]
        }
    }
}
