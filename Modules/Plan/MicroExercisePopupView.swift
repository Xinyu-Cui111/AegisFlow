import SwiftUI

struct ExpandableSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isExpanded.toggle() } }) {
                HStack {
                    Text(icon)
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                }
            }

            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

struct ExerciseCardViewMicro: View {
    let exercise: MicroExerciseItem
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack { Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding([.horizontal, .top], 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Text(exercise.emoji)
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.system(size: 22, weight: .semibold))
                            Text(exercise.duration)
                                .font(.system(size: 13)).foregroundColor(.gray)
                        }
                    }

                    if !exercise.steps.isEmpty {
                        Text("动作要领").font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "1F5F5B"))
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(exercise.steps.indices, id: \.self) { idx in
                                let step = exercise.steps[idx]
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(idx + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 22, height: 22)
                                        .background(Color(hex: "1F5F5B"))
                                        .clipShape(Circle())
                                    Text(step).font(.system(size: 16)).foregroundColor(.black.opacity(0.85))
                                }
                            }
                        }
                    }

                    ExpandableSection(title: "呼吸配合", icon: "💨", color: .green) {
                        Text(exercise.breathingTips).font(.system(size: 15)).foregroundColor(.black.opacity(0.75)).lineSpacing(4)
                    }

                    ExpandableSection(title: "常见错误", icon: "⚠️", color: .red) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(exercise.commonMistakes, id: \.self) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•").foregroundColor(.red)
                                    Text(item).font(.system(size: 15)).foregroundColor(.black.opacity(0.75))
                                }
                            }
                        }
                    }

                    ExpandableSection(title: "运动获益", icon: "💪", color: .blue) {
                        VStack(alignment: .leading, spacing: 6) {
                            if exercise.benefits.isEmpty {
                                Text("无").font(.system(size: 15)).foregroundColor(.black.opacity(0.75))
                            } else {
                                ForEach(exercise.benefits.split(separator: "、").map(String.init), id: \.self) { item in
                                    Text(item).font(.system(size: 15)).foregroundColor(.black.opacity(0.75))
                                }
                            }
                        }
                    }

                    ExpandableSection(title: "场景建议", icon: "📍", color: .orange) {
                        Text(exercise.scenarioTips).font(.system(size: 15)).foregroundColor(.black.opacity(0.75))
                    }

                    ExpandableSection(title: "难度调节", icon: "📈", color: .purple) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                Text("进阶").font(.system(size: 11, weight: .bold)).foregroundColor(.green).padding(.horizontal,6).padding(.vertical,2).background(Color.green.opacity(0.15)).cornerRadius(4)
                                Text(exercise.progression).font(.system(size: 14)).foregroundColor(.black.opacity(0.75))
                            }
                            HStack(alignment: .top) {
                                Text("退阶").font(.system(size: 11, weight: .bold)).foregroundColor(.blue).padding(.horizontal,6).padding(.vertical,2).background(Color.blue.opacity(0.15)).cornerRadius(4)
                                Text(exercise.regression).font(.system(size: 14)).foregroundColor(.black.opacity(0.75))
                            }
                        }
                    }

                    HStack {
                        Spacer()
                        ZStack {
                            Circle().stroke(Color(.systemGray5), lineWidth: 6).frame(width: 90, height: 90)
                            Circle().trim(from: 0, to: 0.75).stroke(Color(hex: "1F5F5B"), style: StrokeStyle(lineWidth: 6, lineCap: .round)).frame(width: 90, height: 90).rotationEffect(.degrees(-90))
                            Text(exercise.duration.replacingOccurrences(of: " min", with: ":00")).font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: "1F5F5B"))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)

                    Button(action: { print("开始练习：\(exercise.name)") }) {
                        HStack(spacing: 8) { Image(systemName: "waveform.path.ecg") ; Text("开始练习").font(.system(size: 18, weight: .bold)) }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: "1F5F5B"))
                            .cornerRadius(26)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .background(Color.white)
        .cornerRadius(28)
        .padding(.horizontal, 16)
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}
