import SwiftUI

struct ProfileInsightCardView: View {
    let profileSummary: ProfileSummaryUI
    let personalizationScore: Int
    let isLoading: Bool
    let todaySteps: Int
    let todayHeartRate: Int
    let todaySleepMinutes: Int
    let onRefresh: () -> Void
    let onExplore: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.sageBright.opacity(0.14))
                            .frame(width: 36, height: 36)
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.sageBright)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("健康画像")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary.opacity(0.86))
                        Text("基于您的互动生成")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.sageBright)
                }
                .buttonStyle(AegisBouncyCardStyle())
            }

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                scoreRow
                chipSection(title: "关注领域", icon: "💡", items: profileSummary.activeTopics)
                if !profileSummary.preferredFoods.isEmpty {
                    chipSection(title: "偏好食物", icon: "🥗", items: profileSummary.preferredFoods)
                }
                if let radar = profileSummary.knowledgeRadar {
                    radarSection(labels: radar.labels, scores: radar.scores)
                }
                if !profileSummary.knowledgeGaps.isEmpty {
                    chipSection(title: "知识缺口", icon: "🔍", items: profileSummary.knowledgeGaps)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private var scoreRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("个性化程度")
                    .font(.system(size: 13))
                    .foregroundColor(.grayMid)
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(personalizationScore)")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.sageBright)
                    Text("%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.sageBright)
                }
            }
            Spacer()
            VStack(spacing: 8) {
                ZStack {
                    Circle().stroke(Color.sageBright.opacity(0.2), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: CGFloat(personalizationScore) / 100)
                        .stroke(Color.sageBright, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(personalizationScore >= 60 ? "良好" : "待完善")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.sageBright)
                }
                .frame(width: 64, height: 64)
            }
        }
    }

    @ViewBuilder
    private func chipSection(title: String, icon: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(icon)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.grayMid)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.self) { topic in
                        Button {
                            onExplore(topic)
                        } label: {
                            Text(topic)
                                .font(.system(size: 12))
                                .foregroundColor(.grayDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.sageBright.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.sageBright.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(14)
                        }
                        .buttonStyle(AegisBouncyCardStyle())
                    }
                }
            }
        }
    }

    private func radarSection(labels: [String], scores: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("知识覆盖")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.grayMid)
            RadarCoverageChart(labels: labels, scores: scores)
                .frame(height: 190)
        }
    }
}

private struct RadarCoverageChart: View {
    let labels: [String]
    let scores: [Int]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = side * 0.30
            let values = normalizedValues

            ZStack {
                ForEach(1...4, id: \.self) { level in
                    RadarPolygonShape(
                        values: Array(repeating: CGFloat(level) / 4.0, count: axisCount)
                    )
                    .stroke(Color.sageBright.opacity(0.15), lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                }

                ForEach(0..<axisCount, id: \.self) { index in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: axisPoint(for: index, radius: radius, center: center))
                    }
                    .stroke(Color.sageBright.opacity(0.2), lineWidth: 1)
                }

                RadarPolygonShape(values: values)
                    .fill(Color.sageBright.opacity(0.22))
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                RadarPolygonShape(values: values)
                    .stroke(Color.sageBright, lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                ForEach(0..<axisCount, id: \.self) { index in
                    let point = axisPoint(
                        for: index, radius: radius * max(values[index], 0.08), center: center)
                    Circle()
                        .fill(Color.sageBright)
                        .frame(width: 6, height: 6)
                        .position(point)
                }

                ForEach(0..<axisCount, id: \.self) { index in
                    let labelPoint = axisPoint(for: index, radius: radius + 18, center: center)
                    Text(labels.indices.contains(index) ? labels[index] : "-")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.grayMid)
                        .position(labelPoint)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 6)
    }

    private var axisCount: Int {
        max(labels.count, 3)
    }

    private var normalizedValues: [CGFloat] {
        (0..<axisCount).map { idx in
            let raw = scores.indices.contains(idx) ? scores[idx] : 0
            return max(0.05, min(1.0, CGFloat(raw) / 100.0))
        }
    }

    private func axisPoint(for index: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = (Double(index) / Double(axisCount)) * Double.pi * 2 - Double.pi / 2
        return CGPoint(
            x: center.x + CGFloat(cos(angle)) * radius,
            y: center.y + CGFloat(sin(angle)) * radius
        )
    }
}

private struct RadarPolygonShape: Shape {
    let values: [CGFloat]

    func path(in rect: CGRect) -> Path {
        guard values.count > 2 else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()

        for idx in values.indices {
            let angle = (Double(idx) / Double(values.count)) * Double.pi * 2 - Double.pi / 2
            let r = radius * values[idx]
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * r,
                y: center.y + CGFloat(sin(angle)) * r
            )

            if idx == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

struct ProfileSummaryUI {
    let activeTopics: [String]
    let preferredFoods: [String]
    let avoidedTopics: [String]
    let knowledgeGaps: [String]
    let knowledgeRadar: KnowledgeRadarUI?
}
struct KnowledgeRadarUI {
    let labels: [String]
    let scores: [Int]
}
