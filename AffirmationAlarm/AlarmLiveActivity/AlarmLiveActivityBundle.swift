import SwiftUI
import WidgetKit

/// Widget Extension entry point. The bundle's `body` lists every widget
/// the extension provides — currently just the alarm Live Activity.
@main
struct AlarmLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        AlarmLiveActivityWidget()
        RingingLiveActivityWidget()
    }
}
