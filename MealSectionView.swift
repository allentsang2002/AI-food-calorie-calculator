import SwiftUI

// Meal section view with tech styling
struct MealSectionView: View {
    let mealType: String
    let items: [[(String, [String: Any])]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mealType)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    ForEach(item, id: \.0) { food, nutrients in
                        HStack {
                            Text("• \(food.capitalized)")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(nutrients["calories"] ?? 0) kcal")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
    }
}
    