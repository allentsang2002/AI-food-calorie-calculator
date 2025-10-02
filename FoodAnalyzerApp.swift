import SwiftUI

// Main app entry
@main
struct FoodAnalyzerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .accentColor(.cyan)
        }
    }
}
    