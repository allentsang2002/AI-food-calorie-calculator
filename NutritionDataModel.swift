import SwiftUI
import PhotosUI
import UIKit

// Data model - shared between views
class NutritionDataModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var imagePathText = "No image selected"
    @Published var analysisResults = ""
    @Published var isAnalyzing = false
    @Published var selectedMealType = "Breakfast"
    @Published var dailySummary = ""
    
    // API Configuration - Replace with your actual keys
    private let apiKey = "<your API KEY>"
    private let basicURL = "https://genai.hkbu.edu.hk/api/v0/rest"
    private let modelName = "gpt-4.1"
    private let apiVersion = "2024-12-01-preview"
    private let appId = "<your APP ID>"
    private let appKey = "<your APP KEY>"
    
    // Daily nutrition data structure
    @Published var dailyData: [String: Any] = [
        "total": [
            "calories": 0.0,
            "protein": 0.0, 
            "fat": 0.0, 
            "carbs": 0.0, 
            "fiber": 0.0
        ],
        "meals": [
            "Breakfast": [],
            "Lunch": [],
            "Dinner": [],
            "Snack": [],
            "Dessert": [],
            "Afternoon Tea": []
        ]
    ]
    
    // Last analysis results
    @Published var lastAnalyzed: [(food: String, nutrients: [String: Any])] = []
    
    // Meal types
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert", "Afternoon Tea"]
    
    // Image picker related
    @Published var imageSelection: PhotosPickerItem?
    @Published var showingImagePicker = false
}

// Extension methods for NutritionDataModel
extension NutritionDataModel {
    // Handle selected image
    func handleImageSelection() async {
        guard let selection = imageSelection else { return }
        
        if let data = try? await selection.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            selectedImage = uiImage
            imagePathText = "Image selected - tap analyze to proceed"
            analysisResults = ""
        } else {
            imagePathText = "Unable to load image"
        }
    }
    
    // Encode image to Base64
    private func encodeImage(_ image: UIImage) -> (String, String)? {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            return nil
        }
        let base64String = imageData.base64EncodedString()
        return (base64String, "image/jpeg")
    }
    
    // Analyze image
    func analyzeImage() {
        guard let image = selectedImage else {
            showAlert(title: "Error", message: "Please select an image first")
            return
        }
        
        isAnalyzing = true
        analysisResults = "Analyzing image...\n\n🔍 Identifying food items"
        
        // Encode image
        guard let (base64Image, mediaType) = encodeImage(image) else {
            analysisResults = "❌ Image encoding failed"
            isAnalyzing = false
            return
        }
        
        // Prepare API request
        let urlString = "\(basicURL)/deployments/\(modelName)/chat/completions?api-version=\(apiVersion)"
        guard let url = URL(string: urlString) else {
            analysisResults = "❌ Invalid URL"
            isAnalyzing = false
            return
        }
        
        // Build request body
        let message = "List 1-3 main foods in this image, preferring composite dishes like fried rice as single items. Separate with commas. Exclude 'and', 'etc' or additional descriptions."
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": message],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:\(mediaType);base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.7,
            "top_p": 1,
            "stream": false
        ]
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            analysisResults = "❌ Failed to construct request body"
            isAnalyzing = false
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(apiKey, forHTTPHeaderField: "api-key")
        request.httpBody = jsonData
        
        // Send request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                
                if let error = error {
                    self.analysisResults = "❌ Request error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.analysisResults = "❌ No data received"
                    return
                }
                
                // Parse response
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        self.processFoodAnalysisResult(content)
                    } else {
                        self.analysisResults = "❌ Failed to parse response: \(String(data: data, encoding: .utf8) ?? "")"
                    }
                } catch {
                    self.analysisResults = "❌ Parsing error: \(error.localizedDescription)\n\(String(data: data, encoding: .utf8) ?? "")"
                }
            }
        }
        task.resume()
    }
    
    // Process food analysis result
    private func processFoodAnalysisResult(_ result: String) {
        var foods = result.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        
        // Merge similar foods
        if foods.contains("fried rice") && foods.contains("egg") {
            foods.removeAll { $0 == "egg" }
            analysisResults = "Analyzing...\n\n🧠 Merged fried rice components, removed separate egg"
        } else {
            analysisResults = "Analyzing...\n\n🧠 Identified foods: \(foods.joined(separator: ", "))"
        }
        
        lastAnalyzed.removeAll()
        var total: [String: Double] = ["calories": 0, "protein": 0, "fat": 0, "carbs": 0, "fiber": 0]
        
        // Get nutrition data for each food
        let group = DispatchGroup()
        
        for food in foods {
            group.enter()
            getFoodData(food) { nutrients in
                defer { group.leave() }
                
                if let nutrients = nutrients {
                    self.lastAnalyzed.append((food, nutrients))
                    
                    // Update totals
                    total["calories"]! += nutrients["calories"] as? Double ?? 0
                    total["protein"]! += nutrients["protein"] as? Double ?? 0
                    total["fat"]! += nutrients["fat"] as? Double ?? 0
                    total["carbs"]! += nutrients["carbs"] as? Double ?? 0
                    total["fiber"]! += nutrients["fiber"] as? Double ?? 0
                    
                    // Update UI
                    DispatchQueue.main.async {
                        self.analysisResults += "\n\n🍽️ \(food.capitalized):\n"
                        self.analysisResults += "   - Calories: \(nutrients["calories"] ?? 0) kcal\n"
                        self.analysisResults += "   - Protein: \(nutrients["protein"] ?? 0) g\n"
                        self.analysisResults += "   - Fat: \(nutrients["fat"] ?? 0) g\n"
                        self.analysisResults += "   - Carbohydrates: \(nutrients["carbs"] ?? 0) g\n"
                        self.analysisResults += "   - Fiber: \(nutrients["fiber"] ?? 0) g"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.analysisResults += "\n\n⚠️ No data found for \(food)"
                    }
                }
            }
        }
        
        // Show summary after all requests complete
        group.notify(queue: .main) {
            if !self.lastAnalyzed.isEmpty {
                self.analysisResults += "\n\n✅ Nutrition Summary"
                self.analysisResults += "\nTotal Calories: \(Int(total["calories"]!)) kcal"
                self.analysisResults += "\nTotal Protein: \(total["protein"]!.rounded(toPlaces: 1)) g"
                self.analysisResults += "\nTotal Fat: \(total["fat"]!.rounded(toPlaces: 1)) g"
                self.analysisResults += "\nTotal Carbohydrates: \(total["carbs"]!.rounded(toPlaces: 1)) g"
                self.analysisResults += "\nTotal Fiber: \(total["fiber"]!.rounded(toPlaces: 1)) g"
            }
            
            self.analysisResults += "\n\n✅ Analysis complete - add to your daily tracking"
        }
    }
    
    // Get food nutrition data
    private func getFoodData(_ food: String, completion: @escaping ([String: Any]?) -> Void) {
        let encodedFood = food.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = "https://api.edamam.com/api/food-database/v2/parser?app_id=\(appId)&app_key=\(appKey)&ingr=\(encodedFood)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Edamam API error: \(error.localizedDescription)")
                // Provide fallback data for fried rice
                if food.lowercased() == "fried rice" {
                    completion([
                        "calories": 200.0,
                        "protein": 5.0,
                        "fat": 7.0,
                        "carbs": 30.0,
                        "fiber": 2.0
                    ])
                } else {
                    completion(nil)
                }
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    var nutrients: [String: Any]?
                    
                    // Try to get data from parsed
                    if let parsed = json["parsed"] as? [[String: Any]], !parsed.isEmpty,
                       let foodData = parsed[0]["food"] as? [String: Any],
                       let nutrientsData = foodData["nutrients"] as? [String: Double] {
                        
                        nutrients = self.mapNutrients(nutrientsData)
                    }
                    // If no data in parsed, try from hints
                    else if let hints = json["hints"] as? [[String: Any]], !hints.isEmpty,
                             let foodData = hints[0]["food"] as? [String: Any],
                             let nutrientsData = foodData["nutrients"] as? [String: Double] {
                            
                        nutrients = self.mapNutrients(nutrientsData)
                    }
                    
                    completion(nutrients)
                } else {
                    completion(nil)
                }
            } catch {
                print("Parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    // Map nutrition data
    private func mapNutrients(_ nutrients: [String: Double]) -> [String: Any] {
        return [
            "calories": Double(nutrients["ENERC_KCAL"] ?? 0),
            "protein": (nutrients["PROCNT"] ?? 0).rounded(toPlaces: 1),
            "fat": (nutrients["FAT"] ?? 0).rounded(toPlaces: 1),
            "carbs": (nutrients["CHOCDF"] ?? 0).rounded(toPlaces: 1),
            "fiber": (nutrients["FIBTG"] ?? 0).rounded(toPlaces: 1)
        ]
    }
    
    // Add to daily tracking
    func addToDailyTrack() {
        if lastAnalyzed.isEmpty {
            showAlert(title: "No Data", message: "Please analyze an image first")
            return
        }
        
        // Update daily data
        if var meals = dailyData["meals"] as? [String: [[(String, [String: Any])]]] {
            var mealItems = meals[selectedMealType] ?? []
            
            for (food, nutrients) in lastAnalyzed {
                mealItems.append([(food, nutrients)])
                
                // Update totals
                if var total = dailyData["total"] as? [String: Double] {
                    total["calories"]! += nutrients["calories"] as? Double ?? 0.0
                    total["protein"]! += nutrients["protein"] as? Double ?? 0.0
                    total["fat"]! += nutrients["fat"] as? Double ?? 0.0
                    total["carbs"]! += nutrients["carbs"] as? Double ?? 0.0
                    total["fiber"]! += nutrients["fiber"] as? Double ?? 0.0
                    dailyData["total"] = total
                }
            }
            
            meals[selectedMealType] = mealItems
            dailyData["meals"] = meals
        }
        
        updateDailySummary()
        showAlert(title: "Success", message: "Added to \(selectedMealType)")
    }
    
    // Update daily summary
    private func updateDailySummary() {
        var summary = "Total Nutrient Intake:\n"
        
        if let total = dailyData["total"] as? [String: Double] {
            summary += "  Calories: \(Int(total["calories"]!)) kcal\n"
            summary += "  Protein: \(total["protein"]!.rounded(toPlaces: 1)) g\n"
            summary += "  Fat: \(total["fat"]!.rounded(toPlaces: 1)) g\n"
            summary += "  Carbohydrates: \(total["carbs"]!.rounded(toPlaces: 1)) g\n"
            summary += "  Fiber: \(total["fiber"]!.rounded(toPlaces: 1)) g\n\n"
        }
        
        if let meals = dailyData["meals"] as? [String: [[(String, [String: Any])]]] {
            for (meal, items) in meals {
                if !items.isEmpty {
                    summary += "\(meal):\n"
                    for item in items {
                        for (food, _) in item {
                            summary += "  - \(food.capitalized)\n"
                        }
                    }
                    summary += "\n"
                }
            }
        }
        
        dailySummary = summary
    }
    
    // Save summary
    func saveSummary() {
        guard !dailySummary.isEmpty else {
            showAlert(title: "No Data", message: "No summary data to save")
            return
        }
        
        // Show share menu to save summary
        let activityVC = UIActivityViewController(activityItems: [dailySummary], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // Reset analysis page
    func resetAnalysis() {
        let resetAlert = UIAlertController(
            title: "Confirm Reset",
            message: "Are you sure you want to reset current analysis data?",
            preferredStyle: .alert
        )
        
        resetAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        resetAlert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
            self.selectedImage = nil
            self.imagePathText = "No image selected"
            self.analysisResults = ""
            self.lastAnalyzed.removeAll()
            self.imageSelection = nil
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(resetAlert, animated: true, completion: nil)
        }
    }
    
    // Reset all data
    func resetAllData() {
        let resetAlert = UIAlertController(
            title: "Confirm Reset",
            message: "Are you sure you want to reset all tracking data?",
            preferredStyle: .alert
        )
        
        resetAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        resetAlert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in
            self.resetAnalysis()
            self.dailySummary = ""
            self.dailyData = [
                "total": [
                    "calories": 0.0,
                    "protein": 0.0, 
                    "fat": 0.0, 
                    "carbs": 0.0, 
                    "fiber": 0.0
                ],
                "meals": [
                    "Breakfast": [],
                    "Lunch": [],
                    "Dinner": [],
                    "Snack": [],
                    "Dessert": [],
                    "Afternoon Tea": []
                ]
            ]
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(resetAlert, animated: true, completion: nil)
        }
    }
    
    // Show alert
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true, completion: nil)
        }
    }
}
    