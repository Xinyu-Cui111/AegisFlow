import SwiftUI
import UIKit

// 定义功能类型
enum ProfileActionType: Identifiable {
    case editProfile, upgrade, rewards, premium
    var id: Int { self.hashValue }

    var title: String {
        switch self {
        case .editProfile: return "编辑资料"
        case .upgrade: return "我的等级"
        case .rewards: return "奖励中心"
        case .premium: return "尊享会员"
        }
    }

    var icon: String {
        switch self {
        case .editProfile: return "slider.horizontal.3"
        case .upgrade: return "trophy.fill"
        case .rewards: return "gift.fill"
        case .premium: return "crown.fill"
        }
    }

    // 清新低饱和但有贵气的图标颜色
    var color: Color {
        switch self {
        case .editProfile: return Color(hex: "#A3B8B0")  // 雾霾雅绿
        case .upgrade: return Color(hex: "#C5A869")  // 珍珠香槟金
        case .rewards: return Color(hex: "#EEB6B6")  // 柔雾粉
        case .premium: return Color(hex: "#4FA395")  // 主题薄荷绿
        }
    }
}

private struct ProfileAvatarTheme {
    let backgroundColors: [Color]
    let glowColors: [Color]
    let badgeIcon: String
    let badgeText: String
    let accentColor: Color
    let orbitOffset: CGSize
    let accentRingOpacity: Double
    let accessoryIcons: [String]
}

private enum ProfileAvatarThemeFactory {
    private static let themes: [ProfileAvatarTheme] = [
        ProfileAvatarTheme(
            backgroundColors: [
                Color(hex: "#F7EAC4"), Color(hex: "#D3B56B"), Color(hex: "#8C6C2F"),
            ],
            glowColors: [Color(hex: "#FFF6DD"), Color(hex: "#EFD07A")],
            badgeIcon: "sparkles",
            badgeText: "晨曦",
            accentColor: Color(hex: "#8C6C2F"),
            orbitOffset: CGSize(width: -20, height: -18),
            accentRingOpacity: 0.26,
            accessoryIcons: ["sparkles", "sun.max.fill"]
        ),
        ProfileAvatarTheme(
            backgroundColors: [
                Color(hex: "#E8F4EF"), Color(hex: "#9AC9B8"), Color(hex: "#4A8E7C"),
            ],
            glowColors: [Color(hex: "#F4FFF9"), Color(hex: "#BEE8DA")],
            badgeIcon: "leaf.fill",
            badgeText: "青岚",
            accentColor: Color(hex: "#4A8E7C"),
            orbitOffset: CGSize(width: 18, height: -20),
            accentRingOpacity: 0.22,
            accessoryIcons: ["leaf.fill", "drop.fill"]
        ),
        ProfileAvatarTheme(
            backgroundColors: [
                Color(hex: "#F1E8FF"), Color(hex: "#C8A6F5"), Color(hex: "#8D63D5"),
            ],
            glowColors: [Color(hex: "#FAF4FF"), Color(hex: "#D8C0FF")],
            badgeIcon: "moon.stars.fill",
            badgeText: "星轨",
            accentColor: Color(hex: "#8D63D5"),
            orbitOffset: CGSize(width: -22, height: 16),
            accentRingOpacity: 0.24,
            accessoryIcons: ["moon.stars.fill", "star.fill"]
        ),
        ProfileAvatarTheme(
            backgroundColors: [
                Color(hex: "#FEE9D8"), Color(hex: "#F5A86B"), Color(hex: "#D96B32"),
            ],
            glowColors: [Color(hex: "#FFF5ED"), Color(hex: "#FFD3B3")],
            badgeIcon: "flame.fill",
            badgeText: "活力",
            accentColor: Color(hex: "#D96B32"),
            orbitOffset: CGSize(width: 20, height: 14),
            accentRingOpacity: 0.23,
            accessoryIcons: ["flame.fill", "bolt.fill"]
        ),
        ProfileAvatarTheme(
            backgroundColors: [
                Color(hex: "#EAF2FF"), Color(hex: "#8CB5FF"), Color(hex: "#4B76D1"),
            ],
            glowColors: [Color(hex: "#F5FAFF"), Color(hex: "#CAE0FF")],
            badgeIcon: "waveform.path.ecg",
            badgeText: "智感",
            accentColor: Color(hex: "#4B76D1"),
            orbitOffset: CGSize(width: -16, height: 18),
            accentRingOpacity: 0.25,
            accessoryIcons: ["waveform.path.ecg", "heart.fill"]
        ),
    ]

    static func theme(for seed: String) -> ProfileAvatarTheme {
        let value = stableSeedValue(for: seed)
        return themes[value % themes.count]
    }

    private static func stableSeedValue(for seed: String) -> Int {
        var result = 0
        for scalar in seed.unicodeScalars {
            result = result &* 31 &+ Int(scalar.value)
        }
        return abs(result)
    }
}

struct GeneratedProfileAvatarView: View {
    let seed: String
    let displayName: String
    let initials: String
    let isPremium: Bool

    @State private var animateBorder = false

    private var theme: ProfileAvatarTheme {
        ProfileAvatarThemeFactory.theme(for: seed)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: theme.backgroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(theme.glowColors.first?.opacity(0.34) ?? .white.opacity(0.34))
                .frame(width: 56, height: 56)
                .blur(radius: 4)
                .offset(x: 16, y: -18)

            Circle()
                .stroke(Color.white.opacity(0.54), lineWidth: 2)
                .frame(width: 68, height: 68)

            Circle()
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.6, dash: [4, 5], dashPhase: 1)
                )
                .foregroundColor(Color.white.opacity(theme.accentRingOpacity))
                .frame(width: 78, height: 78)
                .rotationEffect(.degrees(animateBorder ? 360 : 0))
                .animation(
                    .linear(duration: 14).repeatForever(autoreverses: false), value: animateBorder)

            Circle()
                .fill(theme.accentColor.opacity(0.2))
                .frame(width: 18, height: 18)
                .offset(x: theme.orbitOffset.width, y: theme.orbitOffset.height)

            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 11, height: 11)
                .offset(x: -theme.orbitOffset.width * 0.55, y: -theme.orbitOffset.height * 0.55)

            if let firstAccessory = theme.accessoryIcons.first {
                accessoryBubble(
                    icon: firstAccessory, offset: CGSize(width: 24, height: -22), size: 26)
            }

            if theme.accessoryIcons.count > 1 {
                accessoryBubble(
                    icon: theme.accessoryIcons[1], offset: CGSize(width: -24, height: 22), size: 22)
            }

            VStack(spacing: 3) {
                Image(systemName: theme.badgeIcon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                Text(theme.badgeText)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.78))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            .offset(x: -18, y: -22)

            VStack(spacing: 3) {
                Text(displayName.isEmpty ? "未命名" : displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.94))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(theme.badgeText)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .offset(y: 40)

            Text(initials.isEmpty ? "--" : initials)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)

            if isPremium {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#F7E09E"))
                            .padding(6)
                            .background(Color.black.opacity(0.16))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(6)
            }
        }
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.92), theme.accentColor.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: theme.accentColor.opacity(0.24), radius: 14, x: 0, y: 8)
        .onAppear { animateBorder = true }
    }

    @ViewBuilder
    private func accessoryBubble(icon: String, offset: CGSize, size: CGFloat) -> some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundColor(.white.opacity(0.92))
            .frame(width: size, height: size)
            .background(theme.accentColor.opacity(0.28))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.26), lineWidth: 1))
            .shadow(color: theme.accentColor.opacity(0.22), radius: 5, x: 0, y: 2)
            .offset(offset)
    }
}

// MARK: - ProfileHeaderView
struct ProfileHeaderView: View {
    let userName: String
    let isPremium: Bool
    let avatarInitials: String
    let avatarLocalPath: String?
    let onAction: (ProfileActionType) -> Void

    @State private var activeAction: ProfileActionType? = nil
    @State private var isSparkleAnim = false

    // 统一的【清新贵气】色值
    let accentMint = Color(hex: "#4FA395")
    let pearlGold = Color(hex: "#C5A869")
    let bgLight = Color(hex: "#ECF0EE")
    let textDark = Color(hex: "#2C3E3A")
    let textGray = Color(hex: "#8D9996")

    var body: some View {
        VStack(spacing: 28) {
            // --- 1. 顶部个人信息大框 (清新贵气大气精致) ---
            Button(action: {
                triggerHaptic()
                onAction(.editProfile)
            }) {
                HStack(spacing: 18) {
                    // 头像部分
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let avatarLocalPath,
                                let uiImage = UIImage(contentsOfFile: avatarLocalPath)
                            {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                GeneratedProfileAvatarView(
                                    seed: "\(userName)|\(avatarInitials)",
                                    displayName: userName,
                                    initials: avatarInitials,
                                    isPremium: isPremium
                                )
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [Color.white, pearlGold.opacity(0.3)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2)
                        )
                        .shadow(color: accentMint.opacity(0.15), radius: 12, x: 0, y: 6)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(accentMint)
                            )
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 2, y: 2)
                            .shadow(
                                color: Color(hex: "#2C3E3A").opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(userName)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(textDark)
                        if isPremium {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(Color(hex: "#F5C869"))
                                    .rotationEffect(.degrees(isSparkleAnim ? 8 : -8))
                                    .animation(
                                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                        value: isSparkleAnim)
                                Text("Aegis Premium")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundColor(Color(hex: "#87661E"))
                            }
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#FFF4D2").opacity(0.8),
                                        Color(hex: "#F9E4A9").opacity(0.8),
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12).stroke(
                                    Color.white.opacity(0.6), lineWidth: 1)
                            )
                            .cornerRadius(12)
                            .onAppear { isSparkleAnim = true }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(textGray.opacity(0.6))
                }
            }
            .buttonStyle(AegisBouncyGlassStyle())
            .padding(.horizontal, 28)
            .padding(.top, 32)

            // 雅致的分割线
            HStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, textGray.opacity(0.15), .clear], startPoint: .leading,
                            endPoint: .trailing)
                    )
                    .frame(height: 1)
                Spacer()
            }
            .padding(.horizontal, 24)

            // --- 2. 下方三个核心功能块 (升级、奖励、尊享会员) ---
            HStack(spacing: 16) {
                NavigationLink(value: "level") {
                    ProfileGlassActionContent(type: .upgrade)
                }
                NavigationLink(value: "rewards") {
                    ProfileGlassActionContent(type: .rewards)
                }
                NavigationLink(value: "premium") {
                    ProfileGlassActionContent(type: .premium)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(
            ZStack {
                // 淡淡金色到淡金色的渐变大背景
                LinearGradient(
                    colors: [Color(hex: "#FFFCF2"), Color(hex: "#F9F0D4")], startPoint: .topLeading,
                    endPoint: .bottomTrailing)

                // 增加隐约的高级香槟金与薄荷绿光效
                Circle()
                    .fill(pearlGold.opacity(0.05))
                    .frame(width: 250, height: 250)
                    .blur(radius: 40)
                    .offset(x: 100, y: -80)

                Circle()
                    .fill(accentMint.opacity(0.04))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(x: -100, y: 80)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        // 关键对比度修复：纯白描边分离背景 + 墨绿色系悬浮阴影
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white, pearlGold.opacity(0.2)], startPoint: .topLeading,
                        endPoint: .bottomTrailing), lineWidth: 2)
        )
        .shadow(color: Color(hex: "#2C3E3A").opacity(0.05), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 20)
        // 跳转和弹窗由外部onAction处理
    }

    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - 内部清新气泡操作卡片
struct ProfileGlassAction: View {
    let type: ProfileActionType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ProfileGlassActionContent(type: type)
        }
        .buttonStyle(AegisBouncyGlassStyle())
    }
}

struct ProfileGlassActionContent: View {
    let type: ProfileActionType

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [type.color.opacity(0.7), type.color], startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                )
                .shadow(color: type.color.opacity(0.3), radius: 4, x: 0, y: 2)

            Text(type.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: "#2C3E3A"))  // 统一深灰绿字
        }
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        // 纯白高光锁边配合底壳托浮
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: Color(hex: "#2C3E3A").opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// 优雅的缩小回弹按钮特效
struct AegisBouncyGlassStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
