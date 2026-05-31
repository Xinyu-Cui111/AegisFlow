import UIKit
import SwiftUI

struct TeammateHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var teammates: [TeammateInfo] = []
    @State private var showShareSheet = false
    @State private var shareText = "邀请你加入 AegisFlow，一起记录健康生活！"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("健康团队")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.grayDark)

                    Text("和朋友一起保持健康")
                        .font(.system(size: 14))
                        .foregroundColor(.grayMid)
                }
                .padding(.top, 20)

                Button(action: { showShareSheet = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("邀请好友")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.sageBright)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.sageBright.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)

                if teammates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(.grayLight)

                        Text("暂无团队成员")
                            .font(.system(size: 15))
                            .foregroundColor(.grayMid)

                        Text("邀请好友一起开始健康之旅")
                            .font(.system(size: 13))
                            .foregroundColor(.grayMid)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(teammates) { mate in
                            TeammateCard(teammate: mate)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .background(Color.cream.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [shareText])
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.grayDark)
                }
            }
        }
        .onAppear { loadTeammates() }
    }

    private func loadTeammates() {
        teammates = [
            TeammateInfo(id: "1", name: "小明", avatarEmoji: "👨", steps: 8542, stepsGoal: 10000),
            TeammateInfo(id: "2", name: "小红", avatarEmoji: "👩", steps: 12350, stepsGoal: 10000),
            TeammateInfo(id: "3", name: "小华", avatarEmoji: "🧑", steps: 5200, stepsGoal: 8000),
        ]
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct TeammateInfo: Identifiable {
    let id: String
    let name: String
    let avatarEmoji: String
    let steps: Int
    let stepsGoal: Int
    var progress: Double { min(Double(steps) / Double(stepsGoal), 1.0) }
}

struct TeammateCard: View {
    let teammate: TeammateInfo

    var body: some View {
        HStack(spacing: 14) {
            Text(teammate.avatarEmoji)
                .font(.system(size: 32))
                .frame(width: 48, height: 48)
                .background(Color.sageBright.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(teammate.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.grayDark)

                HStack(spacing: 4) {
                    Text("\(teammate.steps)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.sageBright)
                    Text("/ \(teammate.stepsGoal) 步")
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.grayLight).frame(height: 6)
                        Capsule().fill(Color.sageBright)
                            .frame(width: geo.size.width * teammate.progress, height: 6)
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            if teammate.progress >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.sageBright)
                    .font(.system(size: 20))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}
