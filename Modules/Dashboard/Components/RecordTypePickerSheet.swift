import SwiftUI

/// 首页「我的记录」加号：替代系统 `confirmationDialog`，对标分组表单 + 大触点网格。
struct RecordTypePickerSheet: View {
    let accent: Color
    let onSelect: (LogType) -> Void
    let onCancel: () -> Void

    // Use the exact order defined in GlobalManager/DataManager.LogType
    private let types: [LogType] = [.meal, .water, .mood, .exercise, .headache, .bloodPressure, .bloodSugar, .meditation, .sleep, .menstrual]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(types) { type in
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onSelect(type)
                        } label: {
                            VStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    type.color.opacity(0.28),
                                                    type.color.opacity(0.1),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 72)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(type.color.opacity(0.22), lineWidth: 1)
                                        }

                                    Image(safeSystemName: type.icon, fallback: "square.grid.2x2")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundStyle(type.color)
                                        .symbolRenderingMode(.hierarchical)
                                }

                                Text(type.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(typeSubtitle(for: type))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(type.title)记录")
                        .accessibilityHint("打开该类型的补记表单")
                    }
                }
                .padding(16)
                .padding(.bottom, 8)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("选择记录类型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭", role: .cancel) {
                        onCancel()
                    }
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .tint(accent)
    }

    private func typeSubtitle(for type: LogType) -> String {
        switch type {
        case .meal: return "饮食与热量"
        case .water: return "饮水毫升"
        case .mood: return "情绪标签"
        case .exercise: return "运动时长"
        case .sleep: return "睡眠时长"
        case .headache, .bloodPressure, .bloodSugar, .meditation, .menstrual:
            return "健康记录"
        }
    }
}
