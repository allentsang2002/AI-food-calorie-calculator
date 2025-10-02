import SwiftUI
import PhotosUI

// First tab: Image analysis view
struct ImageAnalysisView: View {
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
                // Header with gradient effect
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Nutrition Analyzer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .background(titleGradient)
                        .mask(Text("Food Nutrition Analyzer")
                            .font(.largeTitle)
                            .fontWeight(.bold))
                    
                    Text("Upload food images for nutritional analysis")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                
                // Image selection area with tech-inspired design
                VStack(spacing: 16) {
                    Text(nutritionData.imagePathText)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    
                    // Image display area with hover effect
                    ZStack {
                        if let image = nutritionData.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 280)
                                .cornerRadius(16)
                                .shadow(color: .cyan.opacity(0.2), radius: 10, x: 0, y: 5)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                                .frame(height: 280)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(LinearGradient(
                                            gradient: Gradient(colors: [.cyan.opacity(0.5), .blue.opacity(0.5)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ), lineWidth: 1.5)
                                )
                                .overlay(
                                    VStack(spacing: 12) {
                                        // Gradient on icon
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 48))
                                            .background(titleGradient)
                                            .mask(Image(systemName: "photo.on.rectangle.angled")
                                                .font(.system(size: 48)))
                                        
                                        Text("Select an image to begin analysis")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                    }
                                )
                        }
                    }
                    
                    // Select image button with animation
                    Button(action: { 
                        withAnimation(.easeInOut) {
                            nutritionData.showingImagePicker = true 
                        }
                    }) {
                        Text("Select Image")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(
                                gradient: Gradient(colors: [.cyan, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            .font(.headline)
                    }
                }
                
                // Analysis button with loading state
                Button(action: {
                    withAnimation(.easeInOut) {
                        nutritionData.analyzeImage()
                    }
                }) {
                    if nutritionData.isAnalyzing {
                        ProgressView("Analyzing...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Analyze Image")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .font(.headline)
                    }
                }
                .background(nutritionData.isAnalyzing ? 
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan.opacity(0.7), .blue.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) : 
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .teal]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 5)
                .disabled(nutritionData.isAnalyzing || nutritionData.selectedImage == nil)
                
                // Analysis results with tech-inspired background
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Analysis Results")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.cyan)
                    }
                    
                    TextEditor(text: $nutritionData.analysisResults)
                        .frame(height: 220)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .shadow(color: .black.opacity(0.05), radius: 5)
                        )
                        .cornerRadius(12)
                        .disabled(true)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                }
                
                // Meal type selection and add button
                if !nutritionData.lastAnalyzed.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add to Daily Tracking")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 16) {
                            Picker("Meal type", selection: $nutritionData.selectedMealType) {
                                ForEach(nutritionData.mealTypes, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity)
                            
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    nutritionData.addToDailyTrack()
                                }
                            }) {
                                Text("Add")
                                    .padding()
                                    .background(LinearGradient(
                                        gradient: Gradient(colors: [.cyan, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(radius: 3)
                                    .font(.headline)
                            }
                        }
                    }
                }
                
                // Reset button
                Button(action: {
                    withAnimation(.easeInOut) {
                        nutritionData.resetAnalysis()
                    }
                }) {
                    Text("Reset Analysis")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .font(.headline)
                }
            }
            .padding()
        }
        .navigationTitle("Image Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $nutritionData.showingImagePicker, selection: $nutritionData.imageSelection)
        .onChange(of: nutritionData.imageSelection) { _ in
            Task {
                await nutritionData.handleImageSelection()
            }
        }
    }
}
    