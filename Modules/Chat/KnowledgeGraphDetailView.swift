import Combine
import SwiftUI
import WebKit

struct ChatGraphNode: Codable, Identifiable {
    var id: String { name }
    let name: String
    let type: String
    let isCenter: Bool
}

struct ChatGraphEdge: Codable, Hashable {
    let source: String
    let target: String
}

struct ChatEntityDetail: Codable {
    let name: String
    let description: String
    let type: String
    let relatedCount: Double
    var calories: String? = nil
    var protein: String? = nil
    var fat: String? = nil
    var dailyRecommendation: String? = nil
    var unit: String? = nil
}

enum ChatGraphCategory: String, CaseIterable {
    case food = "食物"
    case nutrient = "营养素"
    case disease = "疾病"
    case symptom = "症状"
    case exercise = "运动"

    var apiValue: String {
        switch self {
        case .food: return "food"
        case .nutrient: return "nutrient"
        case .disease: return "disease"
        case .symptom: return "symptom"
        case .exercise: return "exercise"
        }
    }
}

final class ChatKnowledgeGraphViewModel: ObservableObject {
    @Published var nodes: [ChatGraphNode] = []
    @Published var edges: [ChatGraphEdge] = []
    @Published var detail: ChatEntityDetail? = nil
    @Published var isLoading = false

    private var globalHost: String {
        APIConfig.ragBaseURL
    }

    func fetchGraphData(for entityName: String, category: ChatGraphCategory) {
        isLoading = true
        guard let encodedName = entityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(globalHost)/api/knowledge/graph?entity=\(encodedName)&category=\(category.apiValue)")
        else {
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8.0

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                if let data,
                   (try? JSONDecoder().decode(GraphResponseMock.self, from: data)) != nil {
                    // 后端接口通了后在这里解析赋值
                    self.loadLocalMockData(for: entityName, category: category)
                } else {
                    self.loadLocalMockData(for: entityName, category: category)
                }
            }
        }.resume()
    }

    private struct GraphResponseMock: Codable {}

    private func loadLocalMockData(for entity: String, category: ChatGraphCategory) {
        switch category {
        case .nutrient:
            nodes = [
                ChatGraphNode(name: entity, type: "nutrient", isCenter: true),
                ChatGraphNode(name: "铁", type: "nutrient", isCenter: false),
                ChatGraphNode(name: "叶酸", type: "nutrient", isCenter: false),
                ChatGraphNode(name: "膳食纤维", type: "nutrient", isCenter: false),
                ChatGraphNode(name: "草莓", type: "food", isCenter: false),
                ChatGraphNode(name: "西兰花", type: "food", isCenter: false),
                ChatGraphNode(name: "菠菜", type: "food", isCenter: false),
            ]
            edges = [
                ChatGraphEdge(source: entity, target: "铁"),
                ChatGraphEdge(source: entity, target: "叶酸"),
                ChatGraphEdge(source: entity, target: "草莓"),
                ChatGraphEdge(source: entity, target: "西兰花"),
                ChatGraphEdge(source: entity, target: "菠菜"),
                ChatGraphEdge(source: entity, target: "膳食纤维"),
            ]
            detail = ChatEntityDetail(
                name: entity,
                description: "\(entity)是一种营养素",
                type: "营养素",
                relatedCount: 8.0,
                dailyRecommendation: "100mg",
                unit: "mg"
            )

        case .food:
            nodes = [
                ChatGraphNode(name: entity, type: "food", isCenter: true),
                ChatGraphNode(name: "维生素C", type: "nutrient", isCenter: false),
                ChatGraphNode(name: "铁", type: "nutrient", isCenter: false),
                ChatGraphNode(name: "肠道", type: "disease", isCenter: false),
            ]
            edges = [
                ChatGraphEdge(source: entity, target: "维生素C"),
                ChatGraphEdge(source: entity, target: "铁"),
                ChatGraphEdge(source: entity, target: "肠道"),
            ]
            detail = ChatEntityDetail(
                name: entity,
                description: "\(entity)是一种优质的健康实体。",
                type: "食物",
                relatedCount: 9.0,
                calories: "34kcal/100g",
                protein: "4.3g"
            )

        case .disease:
            nodes = [
                ChatGraphNode(name: entity, type: "disease", isCenter: true),
                ChatGraphNode(name: "高盐饮食", type: "food", isCenter: false),
                ChatGraphNode(name: "低运动", type: "symptom", isCenter: false),
                ChatGraphNode(name: "高纤维饮食", type: "food", isCenter: false),
                ChatGraphNode(name: "Omega-3", type: "nutrient", isCenter: false),
            ]
            edges = [
                ChatGraphEdge(source: entity, target: "高盐饮食"),
                ChatGraphEdge(source: entity, target: "低运动"),
                ChatGraphEdge(source: entity, target: "高纤维饮食"),
                ChatGraphEdge(source: entity, target: "Omega-3"),
            ]
            detail = ChatEntityDetail(
                name: entity,
                description: "\(entity)与饮食结构和生活方式密切相关。",
                type: "疾病",
                relatedCount: 6.0,
                dailyRecommendation: "规律作息 + 适量运动",
                unit: "plan"
            )

        case .symptom:
            nodes = [
                ChatGraphNode(name: entity, type: "symptom", isCenter: true),
                ChatGraphNode(name: "缺铁", type: "nutrient", isCenter: false),
                ChatGraphNode(name: "睡眠不足", type: "symptom", isCenter: false),
                ChatGraphNode(name: "香蕉", type: "food", isCenter: false),
                ChatGraphNode(name: "深呼吸训练", type: "food", isCenter: false),
            ]
            edges = [
                ChatGraphEdge(source: entity, target: "缺铁"),
                ChatGraphEdge(source: entity, target: "睡眠不足"),
                ChatGraphEdge(source: entity, target: "香蕉"),
                ChatGraphEdge(source: entity, target: "深呼吸训练"),
            ]
            detail = ChatEntityDetail(
                name: entity,
                description: "\(entity)可通过营养补充与生活习惯进行缓解。",
                type: "症状",
                relatedCount: 5.0,
                dailyRecommendation: "先评估诱因，再做针对性调整",
                unit: "step"
            )

        case .exercise:
            nodes = [
                ChatGraphNode(name: entity, type: "food", isCenter: true),
                ChatGraphNode(name: "心肺耐力", type: "symptom", isCenter: false),
                ChatGraphNode(name: "蛋白质", type: "nutrient", isCenter: false),
                ChatGraphNode(name: "拉伸", type: "food", isCenter: false),
                ChatGraphNode(name: "饮水", type: "nutrient", isCenter: false),
            ]
            edges = [
                ChatGraphEdge(source: entity, target: "心肺耐力"),
                ChatGraphEdge(source: entity, target: "蛋白质"),
                ChatGraphEdge(source: entity, target: "拉伸"),
                ChatGraphEdge(source: entity, target: "饮水"),
            ]
            detail = ChatEntityDetail(
                name: entity,
                description: "\(entity)与运动恢复、能量代谢和补给策略相关。",
                type: "运动",
                relatedCount: 7.0,
                dailyRecommendation: "每周 3-5 次中等强度训练",
                unit: "times/week"
            )
        }
    }
}

struct ChatEChartsGraphWebView: UIViewRepresentable {
    let nodes: [ChatGraphNode]
    let edges: [ChatGraphEdge]

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let nodesData = try? JSONEncoder().encode(nodes),
              let nodesJson = String(data: nodesData, encoding: .utf8),
              let edgesData = try? JSONEncoder().encode(edges),
              let edgesJson = String(data: edgesData, encoding: .utf8)
        else {
            return
        }

        let graphHtml = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\">
            <script src=\"https://fastly.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js\"></script>
            <style>body,html,#canvas{width:100%;height:100%;margin:0;padding:0;background-color:transparent;}</style>
        </head>
        <body>
            <div id=\"canvas\"></div>
            <script>
                var myChart = echarts.init(document.getElementById('canvas'));
                var formattedNodes = \(nodesJson).map(n => {
                    let itemColor = '#f39800';
                    if (n.type === 'food') itemColor = '#2baf4a';
                    if (n.type === 'disease' || n.type === 'symptom') itemColor = '#ff9ebb';
                    return { name: n.name, symbolSize: n.isCenter ? 52 : 38, itemStyle: { color: itemColor }, label: { show: true, fontSize: 11, color: '#fff' } };
                });
                var option = {
                    series: [{ type: 'graph', layout: 'force', roam: true, draggable: true, data: formattedNodes, links: \(edgesJson).map(e => ({source:e.source,target:e.target})), force: { repulsion: 300, edgeLength: 110, gravity: 0.12 }, lineStyle: { color: '#cccccc', width: 1.2 } }]
                };
                myChart.setOption(option);
            </script>
        </body>
        </html>
        """
        uiView.loadHTMLString(graphHtml, baseURL: nil)
    }
}

struct KnowledgeGraphDetailView: View {
    let entityName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChatKnowledgeGraphViewModel()
    @State private var selectedCategory: ChatGraphCategory = .food

    private let darkGreenText = Color(red: 40 / 255, green: 90 / 255, blue: 80 / 255)
    private let canvasBgColor = Color(red: 238 / 255, green: 240 / 255, blue: 238 / 255)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(darkGreenText)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("知识图谱")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                    Text(entityName)
                        .font(.system(size: 16, design: .serif))
                        .foregroundColor(darkGreenText)
                }
                .padding(.leading, 10)

                Spacer()

                Text("\(viewModel.nodes.count) 节点")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(darkGreenText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(darkGreenText.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChatGraphCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                            viewModel.fetchGraphData(for: entityName, category: category)
                        } label: {
                            Text(category.rawValue)
                                .font(.system(size: 16, weight: selectedCategory == category ? .semibold : .regular, design: .serif))
                                .foregroundColor(selectedCategory == category ? .white : .black.opacity(0.58))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedCategory == category ? darkGreenText : Color(.systemGray6).opacity(0.55))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 10)

            ZStack(alignment: .top) {
                canvasBgColor.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("正在连接全局接口绘制...")
                        .padding(.top, 120)
                } else {
                    ChatEChartsGraphWebView(nodes: viewModel.nodes, edges: viewModel.edges)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                HStack(spacing: 18) {
                    ChatFloatingActionButton(iconName: "plus.magnifyingglass")
                    ChatFloatingActionButton(iconName: "viewfinder")
                    ChatFloatingActionButton(iconName: "minus.magnifyingglass")
                }
                .padding(.top, 16)
            }

            if let detail = viewModel.detail {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 255 / 255, green: 244 / 255, blue: 225 / 255))
                                .frame(width: 48, height: 48)
                            Text(detail.type == "食物" ? "🍎" : "💊")
                                .font(.title2)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(detail.name)
                                .font(.system(size: 24, weight: .bold, design: .serif))
                            Text(detail.description)
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }

                    Divider()

                    HStack(spacing: 12) {
                        ChatAttributeCardBlock(
                            label: "RelatedCount",
                            value: String(format: "%.1f", detail.relatedCount),
                            tintColor: darkGreenText
                        )

                        if detail.type == "食物" {
                            ChatAttributeCardBlock(
                                label: "Calories",
                                value: detail.calories ?? "0kcal",
                                tintColor: darkGreenText
                            )
                            ChatAttributeCardBlock(
                                label: "Protein",
                                value: detail.protein ?? "--",
                                tintColor: darkGreenText
                            )
                        } else {
                            ChatAttributeCardBlock(
                                label: "Daily recommendation",
                                value: detail.dailyRecommendation ?? "--",
                                tintColor: darkGreenText
                            )
                            ChatAttributeCardBlock(
                                label: "Unit",
                                value: detail.unit ?? "--",
                                tintColor: darkGreenText
                            )
                        }
                    }
                }
                .padding(22)
                .background(Color.white)
                .clipShape(ChatTopRoundedShape(radius: 26))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchGraphData(for: entityName, category: selectedCategory)
        }
    }
}

struct ChatFloatingActionButton: View {
    let iconName: String

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(red: 40 / 255, green: 90 / 255, blue: 80 / 255))
            .frame(width: 46, height: 46)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

struct ChatAttributeCardBlock: View {
    let label: String
    let value: String
    let tintColor: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.gray.opacity(0.8))
                .lineLimit(1)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(tintColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ChatTopRoundedShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
