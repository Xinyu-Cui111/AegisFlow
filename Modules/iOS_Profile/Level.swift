import SwiftUI

// MARK: - 1. 等级与荣誉 (AegisLevelView)
struct AegisLevelView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animateProgress = false

    let cardBg = Color.white  // 纯白卡片本身
    let accentMint = Color(hex: "#4FA395")  // 主题薄荷绿
    let pearlGold = Color(hex: "#C5A869")  // 暖金，增加贵气
    let textDark = Color(hex: "#2C3E3A")  // 墨绿深灰字，代替死黑
    let textGray = Color(hex: "#8D9996")  // 呼吸感浅灰

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {

                // 1. 顶部贵气大功能卡片
                VStack(spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("铂金会员")
                                .font(.system(size: 28, weight: .heavy, design: .serif))
                                .foregroundColor(textDark)

                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(pearlGold)
                                Text("Lv.4")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(pearlGold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(pearlGold.opacity(0.12))
                            .cornerRadius(12)
                        }

                        Spacer()

                        // 立体感叶子星环徽章
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 64, height: 64)
                                .shadow(color: accentMint.opacity(0.1), radius: 8, x: 0, y: 4)

                            Image(systemName: "leaf.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [accentMint, Color(hex: "#81C784")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: accentMint.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .bottom) {
                            Text("当前成长值").font(.system(size: 13, weight: .medium)).foregroundColor(
                                textGray)
                            Spacer()
                            Text("8,450").font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(textDark)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [accentMint, pearlGold], startPoint: .leading,
                                            endPoint: .trailing)
                                    )
                                    .frame(
                                        width: animateProgress ? geometry.size.width * 0.84 : 0,
                                        height: 6
                                    )
                                    .shadow(color: accentMint.opacity(0.3), radius: 3, x: 0, y: 2)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Spacer()
                            Text("距下一等级需 1,550").font(.system(size: 11)).foregroundColor(textGray)
                        }
                    }
                }
                .padding(24)
                .background(
                    ZStack {
                        // 淡淡金到淡金色的渐变大背景，与主界面尊享会员同一种清透贵气
                        LinearGradient(
                            colors: [Color(hex: "#FFFCF2"), Color(hex: "#F9F0D4")],
                            startPoint: .topLeading, endPoint: .bottomTrailing)

                        // 贴合底色的隐约的贵气金箔光晕
                        Circle()
                            .fill(pearlGold.opacity(0.1))
                            .frame(width: 250, height: 250)
                            .blur(radius: 50)
                            .offset(x: 120, y: -60)
                    }
                )
                .cornerRadius(24)
                // 关键点1：外描边高光，切出与背景的清晰分界
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white, pearlGold.opacity(0.2)], startPoint: .topLeading,
                                endPoint: .bottomTrailing), lineWidth: 2)
                )
                // 关键点2：增强墨绿色系阴影，干净不脏
                .shadow(color: Color(hex: "#2C3E3A").opacity(0.06), radius: 24, x: 0, y: 12)
                .padding(.horizontal, 20)

                // 2. 会员专属特权 (横向滚动)
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("专属特权")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(textDark)
                        Spacer()
                        Text("更多特权")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(textGray)
                    }
                    .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            PrivilegeCard(
                                icon: "star.shield.fill", title: "专属徽章", desc: "会员荣誉标识",
                                iconColor: pearlGold)
                            PrivilegeCard(
                                icon: "chart.bar.xaxis", title: "深度报告", desc: "高阶健康洞察",
                                iconColor: accentMint)
                            PrivilegeCard(
                                icon: "bolt.fill", title: "运动加速", desc: "积分获取1.5倍",
                                iconColor: Color(hex: "#FFA726"))
                            PrivilegeCard(
                                icon: "headphones", title: "专属客服", desc: "极速响应",
                                iconColor: Color(hex: "#5C6BC0"))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)  // 为阴影留出防裁切空间
                    }
                }

                // 3. 荣誉徽章
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("荣誉徽章")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(textDark)
                        Spacer()
                        Text("查看全部")
                            .font(.system(size: 14))
                            .foregroundColor(textGray)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(textGray)
                    }
                    .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            MedalBoxLight(
                                icon: "figure.run", name: "暴走达人", desc: "单日10km", isUnlocked: true,
                                color: Color(hex: "#FFA726"))
                            MedalBoxLight(
                                icon: "drop.fill", name: "毅力之王", desc: "连续30天", isUnlocked: true,
                                color: accentMint)
                            MedalBoxLight(
                                icon: "bolt.heart.fill", name: "自律狂魔", desc: "连续早起",
                                isUnlocked: true, color: Color(hex: "#5C6BC0"))
                            MedalBoxLight(
                                icon: "crown.fill", name: "巅峰王者", desc: "榜单一月", isUnlocked: false,
                                color: textGray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }

                // 4. 等级权益
                VStack(alignment: .leading, spacing: 16) {
                    Text("当前等级权益")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(textDark)
                        .padding(.horizontal, 24)

                    VStack(spacing: 0) {
                        PrivilegeRowLight(icon: "percent", title: "商城折扣", desc: "兑换商品享 9 折优惠")
                        Divider().padding(.leading, 64)
                        PrivilegeRowLight(icon: "gift.fill", title: "每月礼包", desc: "每月可领取 200 运动币")
                        Divider().padding(.leading, 64)
                        PrivilegeRowLight(
                            icon: "star.circle.fill", title: "专属标志", desc: "社区昵称铂金专属外观")
                    }
                    .background(cardBg)
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white, lineWidth: 2))
                    .shadow(color: Color(hex: "#2C3E3A").opacity(0.04), radius: 15, x: 0, y: 6)
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 40)
            }
            .padding(.top, 16)
        }
        .background(Color.androidBg.ignoresSafeArea())
        .navigationTitle("我的等级")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").foregroundColor(textDark)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - 清新风格子组件

struct PrivilegeCard: View {
    let icon, title, desc: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [iconColor.opacity(0.8), iconColor], startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                )
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .shadow(color: iconColor.opacity(0.2), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(
                    Color(hex: "#2C3E3A"))
                Text(desc).font(.system(size: 11)).foregroundColor(Color(hex: "#8D9996"))
            }
        }
        .frame(width: 130, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white, lineWidth: 2))
        .shadow(color: Color(hex: "#2C3E3A").opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct MedalBoxLight: View {
    let icon, name, desc: String
    let isUnlocked: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(
                                colors: [color.opacity(0.15), color.opacity(0.05)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.08)], startPoint: .top,
                                endPoint: .bottom)
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isUnlocked ? color : .gray.opacity(0.3))
                    .shadow(color: isUnlocked ? color.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(6)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.1), lineWidth: 1))
                        .offset(x: 24, y: 24)
                }
            }
            .overlay(
                Circle().stroke(
                    isUnlocked ? color.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1.5))

            VStack(spacing: 4) {
                Text(name).font(.system(size: 14, weight: .bold)).foregroundColor(
                    isUnlocked ? Color(hex: "#2C3E3A") : .gray.opacity(0.8))
                Text(desc).font(.system(size: 11)).foregroundColor(Color(hex: "#8D9996"))
            }
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white, lineWidth: 2))
        .shadow(color: Color(hex: "#2C3E3A").opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct PrivilegeRowLight: View {
    let icon, title, desc: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#C5A869"))  // 统一用暖金点缀权益图标
                .frame(width: 48, height: 48)
                .background(Color(hex: "#C5A869").opacity(0.1))
                .cornerRadius(14)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(
                    Color(hex: "#2C3E3A"))
                Text(desc).font(.system(size: 13)).foregroundColor(Color(hex: "#8D9996"))
            }
            Spacer()
        }
        .padding(16)
    }
}
