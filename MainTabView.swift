import SwiftUI
import UIKit

// Main tab view containing two core functions
struct MainTabView: View {
    // Shared data model
    @StateObject private var nutritionData = NutritionDataModel()
    
    var body: some View {
        TabView {
            // First tab: Image analysis
            ImageAnalysisView()
                .environmentObject(nutritionData)
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text("Analyze Food")
                }
            
            // Second tab: Nutrition summary
            NutritionSummaryView()
                .environmentObject(nutritionData)
                .tabItem {
                    Image(systemName: "chart.bar.doc.horizontal")
                    Text("Nutrition Summary")
                }
        }
        .onAppear {
            // Configure navigation bar appearance
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = UIColor.systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.systemCyan]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
    