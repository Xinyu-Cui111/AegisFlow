import SwiftUI
import Combine
import Combine

// MARK: - SplashScreen启动页
struct SplashScreen: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SplashViewModel()
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var showSubtitle: Bool = false
    @State private var showProgress: Bool = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            BackgroundGradient()
            
            // Logo和标题
            VStack(spacing: 24) {
                Spacer()
                
                // Logo
                LogoView(scale: scale, rotationAngle: rotationAngle)
                
                // 应用名称
                AppNameView(opacity: opacity)
                
                // 副标题
                if showSubtitle {
                    SubtitleView()
                }
                
                Spacer()
                
                // 进度指示
                if showProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .padding(.bottom, 60)
                }
            }
            
            // 底部版本信息
            VStack {
                Spacer()
                
                VersionInfoView()
                    .padding(.bottom, 30)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
        .onChange(of: viewModel.isReady) { _, isReady in
            if isReady {
                withAnimation(.easeInOut(duration: 0.5)) {
                    appState.isShowingSplash = false
                }
            }
        }
    }
    
    private func startAnimations() {
        // Logo动画
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            scale = 1.0
        }
        
        // 旋转动画
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            rotationAngle = 360
        }
        
        // 淡入
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            opacity = 1.0
        }
        
        // 副标题
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showSubtitle = true
        }
        
        // 进度
        withAnimation(.easeOut(duration: 0.3).delay(1.2)) {
            showProgress = true
        }
        
        // 初始化并检查状态
        viewModel.initialize()
    }
}

// MARK: - 背景渐变
struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "#1A3A3A"),
                Color(hex: "#0D2828"),
                Color(hex: "#0A1F1F")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            // 装饰圆
            GeometryReader { geometry in
                Circle()
                    .stroke(Color.sageBright.opacity(0.1), lineWidth: 1)
                    .frame(width: 400, height: 400)
                    .offset(x: -50, y: -100)
                
                Circle()
                    .stroke(Color.tealDeep.opacity(0.15), lineWidth: 1)
                    .frame(width: 300, height: 300)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height * 0.6)
            }
        )
    }
}

// MARK: - Logo视图
struct LogoView: View {
    let scale: CGFloat
    let rotationAngle: Double
    
    var body: some View {
        ZStack {
            // 外圈光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.sageBright.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
            
            // Logo背景
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.sageBright, .tealDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color.sageBright.opacity(0.4), radius: 20, x: 0, y: 10)
            
            // Logo图标
            if let uiImage = UIImage(named: "AppIcon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotationAngle))
    }
}

// MARK: - 应用名称视图
struct AppNameView: View {
    let opacity: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text("AegisFlow")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            Text("守护你的每一次心跳")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .opacity(opacity)
    }
}

// MARK: - 副标题视图
struct SubtitleView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.errorRed)
                Image(systemName: "figure.walk")
                    .foregroundColor(.sageBright)
                Image(systemName: "moon.fill")
                    .foregroundColor(.purpleSoft)
            }
            .font(.system(size: 24))
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - 版本信息视图
struct VersionInfoView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Version 2.0.0")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            
            Text("© 2026 AegisFlow. All rights reserved.")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
        }
    }
}

// MARK: - 欢迎页
struct WelcomeView: View {
    @Binding var isLoggedIn: Bool
    @State private var currentPage = 0
    @State private var showLogin = false
    
    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "heart.circle.fill",
            title: "全方位健康守护",
            subtitle: "整合步数、睡眠、心率等多维度健康数据",
            color: .errorRed
        ),
        WelcomePage(
            icon: "brain.head.profile",
            title: "AI智能助手",
            subtitle: "基于RAG技术，为你提供专业的健康建议",
            color: .purpleSoft
        ),
        WelcomePage(
            icon: "chart.line.uptrend.xyaxis",
            title: "数据趋势分析",
            subtitle: "可视化呈现你的健康变化趋势",
            color: .tealDeep
        ),
        WelcomePage(
            icon: "person.2.fill",
            title: "个性化定制",
            subtitle: "根据你的目标，生成专属健康计划",
            color: .sageBright
        )
    ]
    
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 跳过按钮
                HStack {
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button(action: { showLogin = true }) {
                            Text("跳过")
                                .font(.system(size: 14))
                                .foregroundColor(.grayMid)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                    }
                }
                
                // 页面内容
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        WelcomePageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 页面指示器
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.sageBright : Color.grayLight)
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.vertical, 30)
                
                // 按钮
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // 开始使用按钮
                        Button(action: { showLogin = true }) {
                            Text("开始使用")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.sageBright)
                                .cornerRadius(AegisCornerRadius.medium)
                        }
                        
                        // 登录入口
                        Button(action: { showLogin = true }) {
                            Text("已有账号？登录")
                                .font(.system(size: 15))
                                .foregroundColor(.tealDeep)
                        }
                    } else {
                        // 下一步按钮
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            Text("下一步")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.sageBright)
                                .cornerRadius(AegisCornerRadius.medium)
                        }
                    }
                }
                .padding(.horizontal, AegisSpacing.pageHorizontal)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}

// MARK: - 欢迎页数据
struct WelcomePage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - 欢迎页视图
struct WelcomePageView: View {
    let page: WelcomePage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(page.color)
            }
            
            // 文字
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.grayDark)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.grayMid)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - 启动视图模型
class SplashViewModel: ObservableObject {
    @Published var isReady: Bool = false
    @Published var loadingProgress: Double = 0
    
    func initialize() {
        // 模拟初始化过程
        Task {
            // 1. 检查网络
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                loadingProgress = 0.3
            }
            
            // 2. 加载配置
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                loadingProgress = 0.6
            }
            
            // 3. 检查登录状态
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            await MainActor.run {
                loadingProgress = 0.8
            }
            
            // 4. 完成
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            await MainActor.run {
                loadingProgress = 1.0
                isReady = true
            }
        }
    }
}

// MARK: - 预览
#Preview("Splash") {
    SplashScreen()
        .environmentObject(AppState())
}

#Preview("Welcome") {
    WelcomeView(isLoggedIn: .constant(false))
}
