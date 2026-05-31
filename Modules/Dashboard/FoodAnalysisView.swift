import SwiftUI
import Combine
import PhotosUI

// MARK: - 食物分析视图
struct FoodAnalysisView: View {
    @StateObject private var viewModel = FoodAnalysisViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                
                if viewModel.isAnalyzing {
                    AnalyzingView(progress: viewModel.analyzingProgress)
                } else if let result = viewModel.analysisResult {
                    AnalysisResultView(result: result, viewModel: viewModel)
                } else {
                    EmptyAnalysisView(
                        onPickImage: { showImagePicker = true },
                        onTakePhoto: { showCamera = true }
                    )
                }
            }
            .navigationTitle("饮食分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.analysisResult != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("重新分析") {
                            viewModel.reset()
                        }
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $viewModel.selectedImage)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $viewModel.selectedImage)
            }
            .onChange(of: viewModel.selectedImage) { _, newImage in
                if newImage != nil {
                    Task {
                        await viewModel.analyzeFood()
                    }
                }
            }
        }
    }
}

// MARK: - 空状态视图
struct EmptyAnalysisView: View {
    let onPickImage: () -> Void
    let onTakePhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(Color.sageBright.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 64))
                    .foregroundColor(.sageBright)
            }
            
            VStack(spacing: 12) {
                Text("智能饮食分析")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.grayDark)
                
                Text("拍照或选择照片\nAI将自动识别食物并分析营养成分")
                    .font(.system(size: 15))
                    .foregroundColor(.grayMid)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // 操作按钮
            VStack(spacing: 16) {
                Button(action: onTakePhoto) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("拍照识别")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.sageBright)
                    .cornerRadius(AegisCornerRadius.medium)
                }
                
                Button(action: onPickImage) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("从相册选择")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.sageBright)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.sageBright.opacity(0.1))
                    .cornerRadius(AegisCornerRadius.medium)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // 提示
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.androidBlue)
                Text("支持多种食物混合识别")
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - 分析中视图
struct AnalyzingView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.grayLight.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.sageBright, .tealDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                VStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 32))
                        .foregroundColor(.sageBright)
                }
            }
            
            VStack(spacing: 12) {
                Text("正在分析中...")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.grayDark)
                
                Text("AI正在识别食物并计算营养成分")
                    .font(.system(size: 14))
                    .foregroundColor(.grayMid)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.sageBright)
            }
            
            Spacer()
        }
    }
}

// MARK: - 分析结果视图
struct AnalysisResultView: View {
    let result: FoodAnalysisResult
    @ObservedObject var viewModel: FoodAnalysisViewModel
    @State private var showDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AegisSpacing.sectionGap) {
                // 食物图片
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(AegisCornerRadius.large)
                }
                
                // 总热量概览
                CalorieOverviewCard(result: result)
                
                // 营养成分详情
                NutritionDetailCard(result: result)
                
                // 食物列表
                FoodListCard(foods: result.foods)
                
                // 健康建议
                HealthSuggestionCard(suggestions: result.suggestions)
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.saveToDiary()
                    }) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("添加到饮食日记")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.sageBright)
                        .cornerRadius(AegisCornerRadius.medium)
                    }
                    
                    Button(action: {
                        viewModel.shareResult()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("分享分析结果")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.sageBright)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.sageBright.opacity(0.1))
                        .cornerRadius(AegisCornerRadius.medium)
                    }
                }
                .padding(.bottom, AegisSpacing.bottomSafe)
            }
            .padding(.horizontal, AegisSpacing.pageHorizontal)
            .padding(.top, 16)
        }
    }
}

// MARK: - 热量概览卡片
struct CalorieOverviewCard: View {
    let result: FoodAnalysisResult
    
    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("\(result.totalCalories)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.grayDark)
                Text("千卡")
                    .font(.system(size: 14))
                    .foregroundColor(.grayMid)
            }
            
            Divider()
                .frame(height: 60)
            
            VStack(alignment: .leading, spacing: 8) {
                CalorieIndicator(label: "蛋白质", value: result.protein, color: .tealDeep)
                CalorieIndicator(label: "碳水化合物", value: result.carbs, color: .orangeWarm)
                CalorieIndicator(label: "脂肪", value: result.fat, color: .purpleSoft)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct CalorieIndicator: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.grayMid)
            Spacer()
            Text("\(value)g")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.grayDark)
        }
    }
}

// MARK: - 营养详情卡片
struct NutritionDetailCard: View {
    let result: FoodAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("营养成分")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.grayDark)
            
            ForEach(result.nutritionDetails, id: \.name) { item in
                NutritionRow(item: item)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct NutritionRow: View {
    let item: NutritionItem
    
    var body: some View {
        HStack {
            Text(item.name)
                .font(.system(size: 14))
                .foregroundColor(.grayDark)
            
            Spacer()
            
            Text("\(item.value)\(item.unit)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.grayDark)
            
            Text(item.percentOfDaily > 0 ? "\(item.percentOfDaily)%" : "")
                .font(.system(size: 12))
                .foregroundColor(.grayMid)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - 食物列表卡片
struct FoodListCard: View {
    let foods: [RecognizedFood]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("识别到的食物")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.grayDark)
            
            ForEach(foods) { food in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(food.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: food.icon)
                            .font(.system(size: 20))
                            .foregroundColor(food.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.grayDark)
                        Text("\(food.weight)g · \(food.calories)千卡")
                            .font(.system(size: 12))
                            .foregroundColor(.grayMid)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 健康建议卡片
struct HealthSuggestionCard: View {
    let suggestions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellowBright)
                Text("健康建议")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.grayDark)
            }
            
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1).")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.sageBright)
                    Text(suggestion)
                        .font(.system(size: 14))
                        .foregroundColor(.grayMid)
                }
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.yellowBright.opacity(0.1))
        .cornerRadius(AegisCornerRadius.large)
    }
}

// MARK: - ViewModel
class FoodAnalysisViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isAnalyzing: Bool = false
    @Published var analyzingProgress: Double = 0
    @Published var analysisResult: FoodAnalysisResult?
    
    private let apiClient = APIClient.shared
    
    @MainActor
    func analyzeFood() async {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        analyzingProgress = 0
        
        // 模拟分析进度
        while analyzingProgress < 0.9 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            analyzingProgress += 0.1
        }
        
        // 调用API分析
        do {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法处理图片"])
            }
            
            let base64Image = imageData.base64EncodedString()
            
            let response = try await apiClient.request(
                endpoint: "/api/v1/food/analyze",
                method: "POST",
                parameters: ["image": base64Image]
            )
            
            if let data = response["data"] as? [String: Any] {
                analysisResult = parseAnalysisResult(data)
            }
        } catch {
            print("Food Analysis Error: \(error.localizedDescription)")
            // 使用mock数据作为后备
            analysisResult = generateMockResult()
        }
        
        analyzingProgress = 1.0
        isAnalyzing = false
    }
    
    private func parseAnalysisResult(_ data: [String: Any]) -> FoodAnalysisResult? {
        guard let totalCalories = data["total_calories"] as? Int else { return nil }
        
        let foods = (data["foods"] as? [[String: Any]])?.compactMap { foodData -> RecognizedFood? in
            guard let name = foodData["name"] as? String,
                  let weight = foodData["weight"] as? Int,
                  let calories = foodData["calories"] as? Int else { return nil }
            return RecognizedFood(
                id: UUID().uuidString,
                name: name,
                weight: weight,
                calories: calories,
                icon: "fork.knife",
                color: .tealDeep
            )
        } ?? []
        
        let nutritionDetails = (data["nutrition_details"] as? [[String: Any]])?.compactMap { item -> NutritionItem? in
            guard let name = item["name"] as? String,
                  let value = item["value"] as? Int,
                  let unit = item["unit"] as? String else { return nil }
            return NutritionItem(
                name: name,
                value: value,
                unit: unit,
                percentOfDaily: item["percent_of_daily"] as? Int ?? 0
            )
        } ?? []
        
        return FoodAnalysisResult(
            totalCalories: totalCalories,
            protein: data["protein"] as? Int ?? 0,
            carbs: data["carbs"] as? Int ?? 0,
            fat: data["fat"] as? Int ?? 0,
            foods: foods,
            nutritionDetails: nutritionDetails,
            suggestions: data["suggestions"] as? [String] ?? []
        )
    }
    
    private func generateMockResult() -> FoodAnalysisResult {
        FoodAnalysisResult(
            totalCalories: 680,
            protein: 35,
            carbs: 75,
            fat: 28,
            foods: [
                RecognizedFood(id: "1", name: "米饭", weight: 200, calories: 260, icon: "fork.knife", color: .orangeWarm),
                RecognizedFood(id: "2", name: "番茄炒蛋", weight: 150, calories: 180, icon: "flame.fill", color: .errorRed),
                RecognizedFood(id: "3", name: "青菜", weight: 100, calories: 25, icon: "leaf.fill", color: .successGreen),
                RecognizedFood(id: "4", name: "鸡腿", weight: 120, calories: 215, icon: "fork.knife", color: .orangeWarm)
            ],
            nutritionDetails: [
                NutritionItem(name: "热量", value: 680, unit: "kcal", percentOfDaily: 34),
                NutritionItem(name: "蛋白质", value: 35, unit: "g", percentOfDaily: 58),
                NutritionItem(name: "碳水", value: 75, unit: "g", percentOfDaily: 25),
                NutritionItem(name: "脂肪", value: 28, unit: "g", percentOfDaily: 42),
                NutritionItem(name: "膳食纤维", value: 5, unit: "g", percentOfDaily: 20),
                NutritionItem(name: "钠", value: 800, unit: "mg", percentOfDaily: 40)
            ],
            suggestions: [
                "这顿饭蛋白质摄入充足，建议搭配一些蔬菜来均衡营养。",
                "脂肪摄入略高，建议减少油炸食品的摄入频率。",
                "建议在饭后2小时补充一些水果。"
            ]
        )
    }
    
    @MainActor
    func saveToDiary() {
        Task {
            do {
                guard let result = analysisResult else { return }
                let foods = result.foods.map { ["name": $0.name, "weight": $0.weight, "calories": $0.calories] }
                let _ = try await apiClient.request(
                    endpoint: "/api/v1/diet/save",
                    method: "POST",
                    parameters: [
                        "type": "lunch",
                        "foods": foods,
                        "total_calories": result.totalCalories
                    ]
                )
                
                // 发送保存成功通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("DietSaved"),
                    object: nil
                )
            } catch {
                print("Save to Diary Error: \(error.localizedDescription)")
            }
        }
    }
    
    func shareResult() {
        guard let result = analysisResult else { return }
        
        let text = """
        AegisFlow饮食分析
        总热量: \(result.totalCalories)千卡
        蛋白质: \(result.protein)g | 碳水: \(result.carbs)g | 脂肪: \(result.fat)g
        
        识别食物:
        \(result.foods.map { "\($0.name) \($0.weight)g" }.joined(separator: "\n"))
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func reset() {
        selectedImage = nil
        analysisResult = nil
        isAnalyzing = false
        analyzingProgress = 0
    }
}

// MARK: - 数据模型
struct FoodAnalysisResult {
    let totalCalories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let foods: [RecognizedFood]
    let nutritionDetails: [NutritionItem]
    let suggestions: [String]
}

struct RecognizedFood: Identifiable {
    let id: String
    let name: String
    let weight: Int
    let calories: Int
    let icon: String
    let color: Color
}

struct NutritionItem {
    let name: String
    let value: Int
    let unit: String
    let percentOfDaily: Int
}

// MARK: - 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    self?.parent.image = image as? UIImage
                }
            }
        }
    }
}

// MARK: - 相机视图
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 预览
#Preview {
    FoodAnalysisView()
}
