import SwiftUI
import UIKit

// MARK: - 3. 尊享会员
struct AegisPremiumView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animateDiamond = false
    @State private var selectedPlan = 1
    @State private var showUnlockPrompt = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // 1. 顶部黑金会员卡
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(LinearGradient(colors: [Color(hex: "#1A1A1A"), Color(hex: "#000000")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: Color(hex: "#D4AF37").opacity(0.2), radius: 15, x: 0, y: 8)
                        
                    // 局部鎏金光影
                    VStack {
                        HStack {
                            Circle().fill(Color(hex: "#D4AF37").opacity(0.3)).frame(width: 100, height: 100).blur(radius: 40).offset(x: -20, y: -20)
                            Spacer()
                        }
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Aegis Pass")
                                    .font(.system(size: 24, weight: .black, design: .serif))
                                    .overlay(LinearGradient(colors: [Color(hex: "#D4AF37"), Color(hex: "#F9D976")], startPoint: .leading, endPoint: .trailing))
                                    .mask(Text("Aegis Pass").font(.system(size: 24, weight: .black, design: .serif)))
                                Text("解锁所有高级功能，获得极致体验")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            // 钻石旋转特效
                            PremiumDiamond()
                                .frame(width: 48, height: 48)
                                .rotation3DEffect(.degrees(animateDiamond ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                                .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: animateDiamond)
                                .onAppear { animateDiamond = true }
                        }
                        
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("尊享贵宾").font(.system(size: 10)).foregroundColor(.white.opacity(0.6))
                                Text("立即加入").font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "#F9D976"))
                            }
                            Spacer()
                            Image(systemName: "infinity")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(Color(hex: "#D4AF37").opacity(0.3))
                        }
                    }
                    .padding(24)
                }
                .frame(height: 180)
                .padding(.horizontal, 20)
                
                // 2. 特权网格
                VStack(alignment: .leading, spacing: 16) {
                    Text("尊享特权")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        PremiumFeatureBox(icon: "chart.line.uptrend.xyaxis", title: "深度数据分析", desc: "无限量历史记录追踪与周报详解")
                        PremiumFeatureBox(icon: "video.fill", title: "名师视频课程", desc: "解锁全站500+顶级教练精讲课程")
                        PremiumFeatureBox(icon: "shield.righthalf.filled", title: "去广告净享", desc: "告别一切资讯干扰，纯净专注")
                        PremiumFeatureBox(icon: "crown.fill", title: "炫酷尊贵标识", desc: "社区专属红名及动态头像框")
                    }
                    .padding(.horizontal, 20)
                }
                
                // 3. 订阅方案
                VStack(alignment: .leading, spacing: 16) {
                    Text("选择方案")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 16) {
                        PlanOptionRow(id: 0, selectedId: $selectedPlan, duration: "连续包月", price: "¥18/月", desc: "首月特惠 ¥9.9，随时可取消", isRecommended: false)
                        PlanOptionRow(id: 1, selectedId: $selectedPlan, duration: "连续包年", price: "¥168/年", desc: "折合 ¥14/月，最高性价比", isRecommended: true)
                        PlanOptionRow(id: 2, selectedId: $selectedPlan, duration: "终身买断", price: "¥498", desc: "一次付费，终身享受所有权益", isRecommended: false)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer().frame(height: 120) // 留底空间
            }
            .padding(.top, 16)
        }
        .background(Color.androidBg.ignoresSafeArea())
        .navigationTitle("尊享会员")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) { Image(systemName: "chevron.left").foregroundColor(.primary) }
            }
        }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("开通尊享会员", isPresented: $showUnlockPrompt, titleVisibility: .visible) {
            Button("联系开通") {
                let subject = "Aegis Pass 开通咨询"
                let planName = selectedPlan == 0 ? "连续包月" : (selectedPlan == 1 ? "连续包年" : "终身买断")
                let body = "你好，我想咨询当前选择的会员方案：\(planName)"
                if let url = URL(
                    string: "mailto:support@aegisflow.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                ) {
                    UIApplication.shared.open(url)
                }
            }
            Button("稍后再说", role: .cancel) {}
        }
        .overlay(
            VStack {
                Spacer()
                Button(action: { showUnlockPrompt = true }) {
                    Text("立即解锁 Aegis Pass")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient(colors: [Color(hex: "#F9D976"), Color(hex: "#E6C27A")], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(28)
                        .shadow(color: Color(hex: "#D4AF37").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .background(
                    LinearGradient(colors: [Color.androidBg.opacity(0.0), Color.androidBg], startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.bottom)
                )
            }
        )
    }
}

// MARK: - Premium Components

struct RealDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width/2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height/3))
        path.addLine(to: CGPoint(x: width/2, y: height))
        path.addLine(to: CGPoint(x: 0, y: height/3))
        path.closeSubpath()
        return path
    }
}

struct PremiumDiamond: View {
    var body: some View {
        ZStack {
            RealDiamondShape()
                .fill(LinearGradient(colors: [Color.white.opacity(0.8), Color(hex: "#D4AF37")], startPoint: .topLeading, endPoint: .bottomTrailing))
            RealDiamondShape()
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
            
            // 内部线条刻画钻石折射
            Path { path in
                path.move(to: CGPoint(x: 24, y: 0))
                path.addLine(to: CGPoint(x: 24, y: 48))
                path.move(to: CGPoint(x: 0, y: 16))
                path.addLine(to: CGPoint(x: 48, y: 16))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            
            Image(systemName: "sparkle")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .offset(x: 14, y: -10)
        }
        .frame(width: 48, height: 48)
        .shadow(color: Color(hex: "#D4AF37").opacity(0.6), radius: 8, x: 0, y: 4)
    }
}

struct PremiumFeatureBox: View {
    let icon, title, desc: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hex: "#2A2A2A"), .black], startPoint: .top, endPoint: .bottom)).frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#F9D976"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 15, weight: .bold))
                Text(desc).font(.system(size: 11)).foregroundColor(.gray).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.androidCardBg.cornerRadius(20))
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

struct PlanOptionRow: View {
    let id: Int
    @Binding var selectedId: Int
    let duration, price, desc: String
    let isRecommended: Bool
    
    var isSelected: Bool { id == selectedId }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(isSelected ? Color(hex: "#D4AF37") : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 22, height: 22)
                if isSelected {
                    Circle().fill(Color(hex: "#D4AF37")).frame(width: 12, height: 12)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(duration).font(.system(size: 16, weight: .bold))
                    if isRecommended {
                        Text("推荐")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: "#D4AF37"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Text(desc).font(.system(size: 12)).foregroundColor(.gray)
            }
            Spacer()
            Text(price).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(isSelected ? Color(hex: "#D4AF37") : .primary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? Color(hex: "#D4AF37").opacity(0.05) : Color.androidCardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color(hex: "#D4AF37") : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture { withAnimation { selectedId = id } }
    }
}

// MARK: - Extension for Corner Radius
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
