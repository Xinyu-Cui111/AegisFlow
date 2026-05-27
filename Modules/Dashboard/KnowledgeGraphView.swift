import Combine
import SwiftUI

// MARK: - 知识图谱视图
struct KnowledgeGraphView: View {
    @StateObject private var viewModel = KnowledgeGraphViewModel()
    @State private var selectedNode: KnowledgeNode?
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 搜索栏
                    SearchBar(text: $searchText)
                        .padding(.horizontal, AegisSpacing.pageHorizontal)
                        .padding(.vertical, 12)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredNodes.isEmpty {
                        EmptyStateView(
                            icon: "brain",
                            title: "暂无相关知识",
                            message: "系统正在学习您的健康数据"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // 核心知识节点
                                if !viewModel.coreNodes.isEmpty {
                                    KnowledgeSection(title: "核心指标", nodes: viewModel.coreNodes)
                                }

                                // 关联知识
                                if !viewModel.relatedNodes.isEmpty {
                                    KnowledgeSection(title: "关联分析", nodes: viewModel.relatedNodes)
                                }

                                // 建议知识
                                if !viewModel.suggestedNodes.isEmpty {
                                    KnowledgeSection(title: "健康建议", nodes: viewModel.suggestedNodes)
                                }
                            }
                            .padding(.horizontal, AegisSpacing.pageHorizontal)
                            .padding(.bottom, AegisSpacing.bottomSafe)
                        }
                    }
                }
            }
            .navigationTitle("知识图谱")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.refreshGraph() }) {
                            Label("刷新", systemImage: "arrow.clockwise")
                        }
                        Button(action: { viewModel.exportKnowledge() }) {
                            Label("导出", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.grayDark)
                    }
                }
            }
            .sheet(item: $selectedNode) { node in
                KnowledgeDetailSheet(node: node)
            }
        }
        .onAppear {
            viewModel.loadGraph()
        }
    }

    private var filteredNodes: [KnowledgeNode] {
        if searchText.isEmpty {
            return viewModel.allNodes
        }
        return viewModel.allNodes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - 知识分区
struct KnowledgeSection: View {
    let title: String
    let nodes: [KnowledgeNode]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.grayDark)

            ForEach(nodes) { node in
                KnowledgeCard(node: node)
            }
        }
    }
}

// MARK: - 知识卡片
struct KnowledgeCard: View {
    let node: KnowledgeNode
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(node.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: node.icon)
                        .font(.system(size: 22))
                        .foregroundColor(node.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(node.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.grayDark)

                    Text(node.category)
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }

                Spacer()

                // 关联强度指示器
                VStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i < node.relationLevel ? node.color : Color.grayLight)
                            .frame(width: 6, height: 6)
                    }
                }
            }

            Text(node.description)
                .font(.system(size: 14))
                .foregroundColor(.grayMid)
                .lineLimit(isExpanded ? nil : 2)

            // 关联标签
            if !node.relatedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(node.relatedTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12))
                                .foregroundColor(node.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(node.color.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // 展开/收起按钮
            if node.description.count > 80 {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Text(isExpanded ? "收起" : "展开")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.sageBright)
                }
            }
        }
        .padding(AegisSpacing.cardPadding)
        .background(Color.white)
        .cornerRadius(AegisCornerRadius.large)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 知识详情表单
struct KnowledgeDetailSheet: View {
    let node: KnowledgeNode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 头部
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(node.color.opacity(0.15))
                                .frame(width: 64, height: 64)

                            Image(systemName: node.icon)
                                .font(.system(size: 28))
                                .foregroundColor(node.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(node.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.grayDark)

                            Text(node.category)
                                .font(.system(size: 14))
                                .foregroundColor(.grayMid)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)

                    // 描述
                    VStack(alignment: .leading, spacing: 12) {
                        Text("详细说明")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.grayDark)

                        Text(node.description)
                            .font(.system(size: 15))
                            .foregroundColor(.grayMid)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)

                    // 关联知识
                    if !node.relatedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("相关知识点")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.grayDark)

                            FlowLayout(spacing: 8) {
                                ForEach(node.relatedTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 14))
                                        .foregroundColor(.sageBright)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.sageBright.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, AegisSpacing.pageHorizontal)
                    }

                    // 健康建议
                    if let suggestion = node.healthSuggestion {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("健康建议")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.grayDark)

                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellowBright)

                                Text(suggestion)
                                    .font(.system(size: 14))
                                    .foregroundColor(.grayDark)
                            }
                            .padding(AegisSpacing.cardPadding)
                            .background(Color.yellowBright.opacity(0.1))
                            .cornerRadius(AegisCornerRadius.medium)
                        }
                        .padding(.horizontal, AegisSpacing.pageHorizontal)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .navigationTitle("知识详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

// MARK: - ViewModel
class KnowledgeGraphViewModel: ObservableObject {
    @Published var coreNodes: [KnowledgeNode] = []
    @Published var relatedNodes: [KnowledgeNode] = []
    @Published var suggestedNodes: [KnowledgeNode] = []
    @Published var isLoading: Bool = false

    private let apiClient = APIClient.shared

    var allNodes: [KnowledgeNode] {
        coreNodes + relatedNodes + suggestedNodes
    }

    @MainActor
    func loadGraph() {
        isLoading = true
        Task {
            do {
                let graphURL = "\(APIConfig.ragBaseURL)/api/v1/knowledge/graph"
                let response = try await apiClient.request(
                    endpoint: graphURL,
                    method: "GET"
                )

                if let data = response["data"] as? [String: Any] {
                    if let core = data["core_nodes"] as? [[String: Any]] {
                        self.coreNodes = core.compactMap { parseNode($0) }
                    }
                    if let related = data["related_nodes"] as? [[String: Any]] {
                        self.relatedNodes = related.compactMap { parseNode($0) }
                    }
                    if let suggested = data["suggested_nodes"] as? [[String: Any]] {
                        self.suggestedNodes = suggested.compactMap { parseNode($0) }
                    }
                }
            } catch {
                print("Knowledge Graph API Error: \(error.localizedDescription)")
                loadMockData()
            }
            isLoading = false
        }
    }

    @MainActor
    func refreshGraph() {
        loadGraph()
    }

    @MainActor
    func exportKnowledge() {
        Task {
            do {
                let exportURL = "\(APIConfig.ragBaseURL)/api/v1/knowledge/export"
                let _ = try await apiClient.request(
                    endpoint: exportURL,
                    method: "POST",
                    parameters: ["format": "json"]
                )
            } catch {
                print("Export Error: \(error.localizedDescription)")
            }
        }
    }

    private func parseNode(_ data: [String: Any]) -> KnowledgeNode? {
        guard let id = data["id"] as? String,
            let title = data["title"] as? String,
            let desc = data["description"] as? String,
            let icon = data["icon"] as? String,
            let category = data["category"] as? String,
            let colorHex = data["color"] as? String
        else { return nil }

        return KnowledgeNode(
            id: id,
            title: title,
            description: desc,
            icon: icon,
            category: category,
            color: Color(hex: colorHex),
            relationLevel: data["relation_level"] as? Int ?? 1,
            relatedTags: data["related_tags"] as? [String] ?? [],
            healthSuggestion: data["health_suggestion"] as? String
        )
    }

    private func loadMockData() {
        coreNodes = [
            KnowledgeNode(
                id: "1",
                title: "心率监测",
                description: "静息心率是指在安静状态下每分钟心跳次数。正常成年人静息心率在60-100次/分钟。经常运动的人通常心率较低，这是心肺功能良好的表现。",
                icon: "heart.fill",
                category: "心血管",
                color: .errorRed,
                relationLevel: 3,
                relatedTags: ["血压", "运动", "压力"],
                healthSuggestion: "建议每天保持30分钟以上中等强度有氧运动，有助于降低静息心率。"
            ),
            KnowledgeNode(
                id: "2",
                title: "睡眠质量",
                description: "睡眠质量由睡眠时长、入睡时间、睡眠深度等多个维度综合评估。成年人建议每天7-9小时睡眠。",
                icon: "moon.fill",
                category: "睡眠",
                color: .purpleSoft,
                relationLevel: 3,
                relatedTags: ["褪黑素", "作息规律", "深度睡眠"]
            ),
            KnowledgeNode(
                id: "3",
                title: "每日步数",
                description: "世界卫生组织建议成年人每天步行6000-10000步。达到这个目标可显著降低心血管疾病风险。",
                icon: "figure.walk",
                category: "运动",
                color: .tealDeep,
                relationLevel: 2,
                relatedTags: ["有氧运动", "卡路里", "目标"]
            ),
        ]

        relatedNodes = [
            KnowledgeNode(
                id: "4",
                title: "血压管理",
                description: "血压是血液对血管壁的侧压力。正常血压低于120/80 mmHg。高血压是心脑血管疾病的重要危险因素。",
                icon: "waveform.path.ecg",
                category: "心血管",
                color: .orangeWarm,
                relationLevel: 2,
                relatedTags: ["心率", "盐分摄入", "压力"]
            ),
            KnowledgeNode(
                id: "5",
                title: "水分摄入",
                description: "建议每天饮水1500-2000ml。足够的水分摄入对维持身体正常代谢、调节体温、运输营养物质至关重要。",
                icon: "drop.fill",
                category: "营养",
                color: .androidBlue,
                relationLevel: 2,
                relatedTags: ["饮水计划", "脱水", "代谢"]
            ),
        ]

        suggestedNodes = [
            KnowledgeNode(
                id: "6",
                title: "压力管理",
                description: "长期压力会影响免疫系统，导致睡眠质量下降、血压升高。学会压力管理对整体健康至关重要。",
                icon: "brain.head.profile",
                category: "心理健康",
                color: .yellowBright,
                relationLevel: 1,
                relatedTags: ["冥想", "放松", "睡眠"]
            )
        ]
    }
}

// MARK: - 数据模型
struct KnowledgeNode: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: String
    let color: Color
    let relationLevel: Int
    let relatedTags: [String]
    let healthSuggestion: String?

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: String,
        color: Color,
        relationLevel: Int,
        relatedTags: [String],
        healthSuggestion: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.color = color
        self.relationLevel = relationLevel
        self.relatedTags = relatedTags
        self.healthSuggestion = healthSuggestion
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.grayMid)

            TextField("搜索健康知识...", text: $text)
                .font(.system(size: 15))

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.grayMid)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.grayLight)
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.grayMid)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.grayLight)
            Spacer()
        }
    }
}

// MARK: - 预览
#Preview {
    KnowledgeGraphView()
}
