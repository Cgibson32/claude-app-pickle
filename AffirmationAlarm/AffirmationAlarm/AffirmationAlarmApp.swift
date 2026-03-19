import SwiftUI

@main
struct AffirmationAlarmApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.1, green: 0.1, blue: 0.18))
        }
    }
}
