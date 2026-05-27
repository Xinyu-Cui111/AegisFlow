import SwiftUI
import Combine
import Combine
import SceneKit
import UIKit

// MARK: - Avatar API DTOs (`APIResponse.data`)

private struct AvatarStatusDTO: Codable {
    let stamina: Int?
    let mood: Int?
    let focus: Int?
}

private struct AvatarDataDTO: Codable {
    let name: String?
    let icon: String?
    let level: Int?
    let experience: Int?
    let status: AvatarStatusDTO?
    let customization: [Int]?
    let equipped_items: [String: Int]?
    let model_url: String?
}

private struct AvatarHistoryEntryDTO: Codable {
    let id: String?
    let name: String?
    let created_at: String?
}

// MARK: - Avatar形象查看器
struct AvatarViewerView: View {
    @StateObject private var viewModel = AvatarViewerViewModel()
    @State private var showCustomization = false
    @State private var showWardrobe = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 3D头像展示区
                    AvatarDisplayView(
                        viewModel: viewModel,
                        rotationAngle: $rotationAngle
                    )
                    .frame(height: 400)
                    
                    // 信息和操作区
                    ScrollView {
                        VStack(spacing: AegisSpacing.sectionGap) {
                            // 头像信息
                            AvatarInfoCard(
                                viewModel: viewModel
                            )
                            
                            // 身体状态
                            BodyStatusSection(viewModel: viewModel)
                            
                            // 操作按钮
                            AvatarActionsGrid(
                                viewModel: viewModel,
                                showCustomization: $showCustomization,
                                showWardrobe: $showWardrobe
                            )
                            
                            Spacer(minLength: AegisSpacing.bottomSafe)
                        }
                        .padding(.horizontal, AegisSpacing.pageHorizontal)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("我的形象")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.saveAvatar() }) {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.grayDark)
                    }
                }
            }
            .sheet(isPresented: $showCustomization) {
                AvatarCustomizationView(viewModel: viewModel)
            }
            .sheet(isPresented: $showWardrobe) {
                AvatarWardrobeView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadAvatar()
        }
    }
}

// MARK: - Avatar展示视图
struct AvatarDisplayView: View {
    @ObservedObject var viewModel: AvatarViewerViewModel
    @Binding var rotationAngle: Double
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.sageBright.opacity(0.3), Color.tealDeep.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 3D场景
            AvatarSceneView(scene: viewModel.scene)
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 1, z: 0)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            rotationAngle = Double(value.translation.width)
                        }
                )
            
            // 底部渐变
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.cream.opacity(0), Color.cream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
            }
        }
    }
}

// MARK: - Avatar场景视图
struct AvatarSceneView: UIViewRepresentable {
    let scene: SCNScene?
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

// MARK: - Avatar信息卡片
struct AvatarInfoCard: View {
    @ObservedObject var viewModel: AvatarViewerViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // 头像缩略图
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.sageBright, .tealDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: viewModel.avatarIcon)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.avatarName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.grayDark)
                
                HStack(spacing: 12) {
                    // 等级
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellowBright)
                        Text("Lv.\(viewModel.level)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.grayDark)
                    }
                    
                    // 经验值
                    Text("\(viewModel.experience) EXP")
                        .font(.system(size: 13))
                        .foregroundColor(.grayMid)
                }
                
                // 状态标签
                HStack(spacing: 8) {
                    StatusBadge(
                        icon: "heart.fill",
                        text: "健康",
                        color: .errorRed
                    )
                    
                    StatusBadge(
                        icon: "flame.fill",
                        text: "活跃",
                        color: .orangeWarm
                    )
                }
            }
            
            Spacer()
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 状态标签
struct StatusBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - 身体状态区
struct BodyStatusSection: View {
    @ObservedObject var viewModel: AvatarViewerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.grayDark)
            
            HStack(spacing: 12) {
                BodyStatusCard(
                    title: "体力",
                    value: viewModel.stamina,
                    maxValue: 100,
                    color: .successGreen,
                    icon: "bolt.fill"
                )
                
                BodyStatusCard(
                    title: "心情",
                    value: viewModel.mood,
                    maxValue: 100,
                    color: .yellowBright,
                    icon: "face.smiling.fill"
                )
                
                BodyStatusCard(
                    title: "专注",
                    value: viewModel.focus,
                    maxValue: 100,
                    color: .androidBlue,
                    icon: "brain.head.profile"
                )
            }
        }
    }
}

// MARK: - 身体状态卡片
struct BodyStatusCard: View {
    let title: String
    let value: Int
    let maxValue: Int
    let color: Color
    let icon: String
    
    var progress: Double {
        Double(value) / Double(maxValue)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.grayMid)
            
            Text("\(value)%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.grayDark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.medium)
    }
}

// MARK: - 操作按钮网格
struct AvatarActionsGrid: View {
    @ObservedObject var viewModel: AvatarViewerViewModel
    @Binding var showCustomization: Bool
    @Binding var showWardrobe: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("形象管理")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.grayDark)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ActionGridItem(
                    icon: "paintbrush.fill",
                    title: "自定义",
                    color: .purpleSoft
                ) {
                    showCustomization = true
                }
                
                ActionGridItem(
                    icon: "tshirt.fill",
                    title: "衣柜",
                    color: .androidBlue
                ) {
                    showWardrobe = true
                }
                
                ActionGridItem(
                    icon: "arrow.triangle.2.circlepath",
                    title: "重置",
                    color: .tealDeep
                ) {
                    viewModel.resetAvatar()
                }
                
                ActionGridItem(
                    icon: "camera.fill",
                    title: "拍照",
                    color: .orangeWarm
                ) {
                    viewModel.takePhoto()
                }
                
                ActionGridItem(
                    icon: "square.and.arrow.up",
                    title: "分享",
                    color: .sageBright
                ) {
                    viewModel.shareAvatar()
                }
                
                ActionGridItem(
                    icon: "clock.arrow.circlepath",
                    title: "历史",
                    color: .grayMid
                ) {
                    viewModel.showHistory()
                }
            }
        }
    }
}

// MARK: - 操作网格项
struct ActionGridItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.grayDark)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(AegisCornerRadius.medium)
        }
    }
}

// MARK: - 形象自定义视图
struct AvatarCustomizationView: View {
    @ObservedObject var viewModel: AvatarViewerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    private let tabs = ["发型", "脸型", "肤色", "配饰"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 预览区
                    ZStack {
                        Color.sageBright.opacity(0.2)
                            .ignoresSafeArea()
                        
                        Image(systemName: viewModel.avatarIcon)
                            .font(.system(size: 100))
                            .foregroundColor(.tealDeep)
                    }
                    .frame(height: 300)
                    
                    // 选项区
                    VStack(spacing: 0) {
                        // 标签页
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                                    AvatarSegmentTabButton(
                                        title: tab,
                                        isSelected: selectedTab == index
                                    ) {
                                        selectedTab = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        // 选项内容
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(0..<9, id: \.self) { index in
                                    OptionItem(isSelected: index == viewModel.selectedOptions[selectedTab]) {
                                        viewModel.selectOption(tab: selectedTab, index: index)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                }
            }
            .navigationTitle("自定义形象")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        viewModel.saveCustomization(tab: selectedTab)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Tab按钮
struct AvatarSegmentTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .sageBright : .grayMid)
                
                Rectangle()
                    .fill(isSelected ? Color.sageBright : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(2)
            }
            .frame(width: 80)
        }
    }
}

// MARK: - 选项项
struct OptionItem: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.sageBright.opacity(0.2) : Color.grayLight.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundColor(isSelected ? .sageBright : .grayMid)
                
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.sageBright)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - 形象衣柜视图
struct AvatarWardrobeView: View {
    @ObservedObject var viewModel: AvatarViewerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory = 0
    
    private let categories = ["上衣", "下装", "鞋子", "配饰"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 标签页
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                                CategoryChip(
                                    title: category,
                                    isSelected: selectedCategory == index
                                ) {
                                    selectedCategory = index
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    
                    // 服装网格
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(0..<12, id: \.self) { index in
                                WardrobeItem(
                                    isOwned: index < 8,
                                    isEquipped: index == viewModel.equippedItems[selectedCategory]
                                ) {
                                    if index < 8 {
                                        viewModel.equipItem(category: selectedCategory, index: index)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("形象衣柜")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 分类标签
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .grayDark)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.sageBright : Color.white)
                .cornerRadius(20)
        }
    }
}

// MARK: - 衣柜项
struct WardrobeItem: View {
    let isOwned: Bool
    let isEquipped: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isOwned ? Color.white : Color.grayLight.opacity(0.3))
                    .frame(height: 100)
                
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 36))
                    .foregroundColor(isOwned ? (isEquipped ? .sageBright : .grayMid) : .grayLight)
                
                if !isOwned {
                    VStack {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.grayMid)
                                .padding(8)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                if isEquipped {
                    VStack {
                        HStack {
                            Spacer()
                            Text("已装备")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.sageBright)
                                .cornerRadius(6)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .disabled(!isOwned)
    }
}

// MARK: - ViewModel
class AvatarViewerViewModel: ObservableObject {
    @Published var scene: SCNScene?
    @Published var avatarName: String = "我的形象"
    @Published var avatarIcon: String = "person.fill"
    @Published var level: Int = 5
    @Published var experience: Int = 2450
    
    @Published var stamina: Int = 85
    @Published var mood: Int = 92
    @Published var focus: Int = 78
    
    @Published var selectedOptions: [Int] = [0, 0, 0, 0]
    @Published var equippedItems: [Int: Int] = [0: 1, 1: 0, 2: 2, 3: -1]
    
    private let apiClient = APIClient.shared
    
    func loadAvatar() {
        initLocalScene()
        Task { @MainActor in
            await loadAvatarFromAPI()
        }
    }
    
    @MainActor
    private func loadAvatarFromAPI() async {
        do {
            let data = try await apiClient.request(.getAvatar, responseType: AvatarDataDTO.self)
            avatarName = data.name ?? "我的形象"
            avatarIcon = data.icon ?? "person.fill"
            level = data.level ?? 1
            experience = data.experience ?? 0
            if let status = data.status {
                stamina = status.stamina ?? 85
                mood = status.mood ?? 92
                focus = status.focus ?? 78
            }
            if let options = data.customization, !options.isEmpty {
                selectedOptions = options
            }
            if let equipped = data.equipped_items {
                equippedItems = Dictionary(uniqueKeysWithValues: equipped.compactMap { key, value in
                    guard let k = Int(key) else { return nil }
                    return (k, value)
                })
            }
            if let modelUrl = data.model_url {
                await load3DModel(from: modelUrl)
            }
            // 缓存到本地
            saveAvatarToLocal(data)
        } catch {
            print("Avatar API Error: \(error.localizedDescription)")
            // 尝试从本地恢复
            if let cached = loadAvatarFromLocal() {
                avatarName = cached.name ?? "我的形象"
                avatarIcon = cached.icon ?? "person.fill"
                level = cached.level ?? 1
                experience = cached.experience ?? 0
                if let status = cached.status {
                    stamina = status.stamina ?? 85
                    mood = status.mood ?? 92
                    focus = status.focus ?? 78
                }
                if let options = cached.customization, !options.isEmpty {
                    selectedOptions = options
                }
            } else {
                print("头像接口暂不可用，使用默认设置。")
            }
        }
    }
    
    private func saveAvatarToLocal(_ data: AvatarDataDTO) {
        let fm = FileManager.default
        guard let docDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let cacheFile = docDir.appendingPathComponent("avatar_cache.json")
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: cacheFile)
        }
    }
    
    private func loadAvatarFromLocal() -> AvatarDataDTO? {
        let fm = FileManager.default
        guard let docDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let cacheFile = docDir.appendingPathComponent("avatar_cache.json")
        guard fm.fileExists(atPath: cacheFile.path),
              let data = try? Data(contentsOf: cacheFile) else { return nil }
        return try? JSONDecoder().decode(AvatarDataDTO.self, from: data)
    }
    
    private func initLocalScene() {
        scene = SCNScene()
        
        let sphere = SCNSphere(radius: 1.5)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemOrange.withAlphaComponent(0.8)
        sphere.materials = [material]
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, 1.5, 0)
        scene?.rootNode.addChildNode(sphereNode)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 2, 8)
        scene?.rootNode.addChildNode(cameraNode)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(5, 5, 5)
        scene?.rootNode.addChildNode(lightNode)
    }
    
    @MainActor
    private func load3DModel(from urlString: String) async {
        // 加载远程3D模型
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let source = SCNSceneSource(data: data, options: nil)
            scene = source?.scene(options: nil)
        } catch {
            print("Failed to load 3D model: \(error)")
        }
    }
    
    @MainActor
    func saveAvatar() {
        Task { @MainActor in
            do {
                let equippedStrings = Dictionary(uniqueKeysWithValues: equippedItems.map { ("\($0.key)", $0.value) })
                _ = try await apiClient.request(
                    .saveAvatar(name: avatarName, customization: selectedOptions, equippedItems: equippedStrings),
                    responseType: EmptyResponse.self
                )
                NotificationCenter.default.post(
                    name: NSNotification.Name("AvatarSaved"),
                    object: nil
                )
            } catch {
                print("Save Avatar Error: \(error.localizedDescription)")
                // 后端不可用，保存到本地
                let avatarData = AvatarDataDTO(
                    name: avatarName,
                    icon: avatarIcon,
                    level: level,
                    experience: experience,
                    status: AvatarStatusDTO(stamina: stamina, mood: mood, focus: focus),
                    customization: selectedOptions,
                    equipped_items: Dictionary(uniqueKeysWithValues: equippedItems.map { ("\($0.key)", $0.value) }),
                    model_url: nil
                )
                saveAvatarToLocal(avatarData)
                NotificationCenter.default.post(
                    name: NSNotification.Name("AvatarSaved"),
                    object: nil
                )
            }
        }
    }
    
    func selectOption(tab: Int, index: Int) {
        selectedOptions[tab] = index
    }
    
    @MainActor
    func saveCustomization(tab: Int) {
        Task { @MainActor in
            do {
                _ = try await apiClient.request(
                    .saveAvatarCustomization(customization: selectedOptions, tab: tab),
                    responseType: EmptyResponse.self
                )
            } catch {
                print("Save Customization Error: \(error.localizedDescription)")
                // 后端不可用，保存到本地
                let avatarData = AvatarDataDTO(
                    name: avatarName,
                    icon: avatarIcon,
                    level: level,
                    experience: experience,
                    status: AvatarStatusDTO(stamina: stamina, mood: mood, focus: focus),
                    customization: selectedOptions,
                    equipped_items: Dictionary(uniqueKeysWithValues: equippedItems.map { ("\($0.key)", $0.value) }),
                    model_url: nil
                )
                saveAvatarToLocal(avatarData)
            }
        }
    }
    
    @MainActor
    func equipItem(category: Int, index: Int) {
        equippedItems[category] = index
        Task { @MainActor in
            do {
                _ = try await apiClient.request(
                    .equipAvatarItem(category: category, itemIndex: index),
                    responseType: EmptyResponse.self
                )
            } catch {
                print("Equip Item Error: \(error.localizedDescription)")
                // 后端不可用，保存到本地
                let avatarData = AvatarDataDTO(
                    name: avatarName,
                    icon: avatarIcon,
                    level: level,
                    experience: experience,
                    status: AvatarStatusDTO(stamina: stamina, mood: mood, focus: focus),
                    customization: selectedOptions,
                    equipped_items: Dictionary(uniqueKeysWithValues: equippedItems.map { ("\($0.key)", $0.value) }),
                    model_url: nil
                )
                saveAvatarToLocal(avatarData)
            }
        }
    }
    
    @MainActor
    func resetAvatar() {
        Task { @MainActor in
            do {
                _ = try await apiClient.request(.resetAvatar, responseType: EmptyResponse.self)
            } catch {
                print("Reset Avatar Error: \(error.localizedDescription)")
                // 后端不可用，仍执行本地重置
            }
            selectedOptions = [0, 0, 0, 0]
            equippedItems = [0: -1, 1: -1, 2: -1, 3: -1]
            // 清除本地缓存
            let fm = FileManager.default
            if let docDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
                let cacheFile = docDir.appendingPathComponent("avatar_cache.json")
                try? fm.removeItem(at: cacheFile)
            }
            initLocalScene()
        }
    }
    
    private func makeSnapshotImage() -> UIImage? {
        guard let scene = scene else { return nil }
        let size = CGSize(width: 512, height: 512)
        let view = SCNView(frame: CGRect(origin: .zero, size: size))
        view.scene = scene
        view.backgroundColor = .clear
        view.autoenablesDefaultLighting = true
        return view.snapshot()
    }
    
    func takePhoto() {
        guard let snapshot = makeSnapshotImage() else { return }
        UIImageWriteToSavedPhotosAlbum(snapshot, nil, nil, nil)
        NotificationCenter.default.post(
            name: NSNotification.Name("AvatarPhotoTaken"),
            object: snapshot
        )
    }
    
    func shareAvatar() {
        guard let snapshot = makeSnapshotImage() else { return }
        let activityVC = UIActivityViewController(
            activityItems: [snapshot],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    @MainActor
    func showHistory() {
        Task { @MainActor in
            do {
                let rows = try await apiClient.request(.getAvatarHistory, responseType: [AvatarHistoryEntryDTO].self)
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowAvatarHistory"),
                    object: rows
                )
            } catch {
                print("Avatar History Error: \(error.localizedDescription)")
                // 后端不可用，返回空列表或本地历史
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowAvatarHistory"),
                    object: []
                )
            }
        }
    }
}

// MARK: - 预览
#Preview {
    AvatarViewerView()
}
