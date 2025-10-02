import SwiftUI

// Second tab: Nutrition summary view
struct NutritionSummaryView: View {
    @EnvironmentObject private var nutritionData: NutritionDataModel
    
    // Define gradient for tech feel
    private let titleGradient = LinearGradient(
        gradient: Gradient(colors: [.cyan, .blue]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with gradient
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nutrition Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .background(titleGradient)
                        .mask(Text("Nutrition Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold))
                    
                    Text("Track your daily nutritional intake")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                
                // Total nutrition intake cards with tech design
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Daily Nutrition Overview")
                            .font(.headline)
                        Image(systemName: "chart.pie.fill")
                            .foregroundColor(.cyan)
                    }
                    
                    if let total = nutritionData.dailyData["total"] as? [String: Double] {
                        // Animated cards for nutrition stats
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                NutritionStatCard(
                                    title: "Calories", 
                                    value: "\(Int(total["calories"]!))", 
                                    unit: "kcal", 
                                    color: Color(.systemRed), 
                                    icon: "flame.fill"
                                )
                                NutritionStatCard(
                                    title: "Protein", 
                                    value: "\(total["protein"]!.rounded(toPlaces: 1))", 
                                    unit: "g", 
                                    color: Color(.systemBlue), 
                                    icon: "atom"
                                )
                            }
                            
                            HStack(spacing: 16) {
                                NutritionStatCard(
                                    title: "Fat", 
                                    value: "\(total["fat"]!.rounded(toPlaces: 1))", 
                                    unit: "g", 
                                    color: Color(.systemOrange), 
                                    icon: "drop.fill"
                                )
                                NutritionStatCard(
                                    title: "Carbs", 
                                    value: "\(total["carbs"]!.rounded(toPlaces: 1))", 
                                    unit: "g", 
                                    color: Color(.systemGreen), 
                                    icon: "leaf.fill"
                                )
                            }
                        }
                    } else {
                        Text("No data available. Analyze food and add to tracking first.")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                
                // Meal breakdown section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Meal Breakdown")
                            .font(.headline)
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(.cyan)
                    }
                    
                    if let meals = nutritionData.dailyData["meals"] as? [String: [[(String, [String: Any])]]] {
                        VStack(spacing: 16) {
                            ForEach(nutritionData.mealTypes, id: \.self) { mealType in
                                if let items = meals[mealType], !items.isEmpty {
                                    MealSectionView(mealType: mealType, items: items)
                                        .transition(.opacity.combined(with: .scale))
                                }
                            }
                        }
                    }
                    
                    if nutritionData.dailySummary.isEmpty {
                        Text("No meal data recorded yet")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    // Save summary button
                    Button(action: {
                        withAnimation(.easeInOut) {
                            nutritionData.saveSummary()
                        }
                    }) {
                        Text("Save Summary Report")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .font(.headline)
                    }
                    .disabled(nutritionData.dailySummary.isEmpty)
                    
                    // Reset all data button
                    Button(action: {
                        withAnimation(.easeInOut) {
                            nutritionData.resetAllData()
                        }
                    }) {
                        Text("Reset Daily Tracking")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.secondary)
                            .cornerRadius(12)
                            .font(.headline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Nutrition Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}
    