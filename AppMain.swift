import SwiftUI
import Combine
import UserNotifications

@main
struct AegisFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var coordinator = NavigationCoordinator.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataManager)
                .environmentObject(appState)
                .environmentObject(coordinator)
                .preferredColorScheme(.light)
                .onAppear {
                    NotificationService.shared.setupNotificationCategories()
                }
        }
    }
}

// MARK: - AppDelegate for APNs
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            try? await APIClient.shared.request(.registerFcm(token: token), responseType: EmptyResponse.self)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let actionId = response.actionIdentifier
        let categoryId = response.notification.request.content.categoryIdentifier
        
        Task {
            try? await APIClient.shared.request(
                .recordNotificationAction(notificationId: categoryId, action: actionId),
                responseType: EmptyResponse.self
            )
        }
    }
}

// MARK: - App状态管理
class AppState: ObservableObject {
    @Published var isInitialized: Bool = false
    @Published var isShowingSplash: Bool = true
    @Published var currentRoute: AppRoute = .splash
    
    init() {
        #if DEBUG
        let uiDemo = ProcessInfo.processInfo.arguments.contains("-uiDemo")
        let splashDelay: TimeInterval = uiDemo ? 0.35 : 2.0
        #else
        let uiDemo = false
        let splashDelay: TimeInterval = 2.0
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + splashDelay) { [weak self] in
            guard let self = self else { return }
            self.isShowingSplash = false
            self.isInitialized = true

            // DEBUG：启动参数 -forceLogin 清除本地登录态并强制进入登录页（方便反复测「测试登录」）
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-forceLogin") {
                TokenStorage.shared.clearTokens()
                PreferencesStorage.shared.isLoggedIn = false
                PreferencesStorage.shared.onboardingCompleted = false
                self.currentRoute = .auth
                return
            }

            // DEBUG：-uiDemo 直达主界面，供 CI / Simulator 截真实界面
            // 可选：-uiDemoTab dashboard|plan|data|chat|profile
            // 可选：-uiDemoPage 打开 PAGE 生成页样例
            if uiDemo {
                Self.applyUIDemoBootstrap()
                self.currentRoute = .main
                return
            }
            #endif

            let hasToken = UserDefaults.standard.string(forKey: APIConfig.accessTokenKey) != nil
            let onboardingDone = UserDefaults.standard.bool(forKey: "onboardingCompleted")

            if hasToken && onboardingDone {
                self.currentRoute = .main
            } else if hasToken {
                self.currentRoute = .onboarding
            } else {
                self.currentRoute = .auth
            }
        }
    }

    #if DEBUG
    private static func applyUIDemoBootstrap() {
        let now = Date()
        TokenStorage.shared.accessToken = "uidemo_access_token"
        TokenStorage.shared.refreshToken = "uidemo_refresh_token"
        TokenStorage.shared.tokenExpiry = now.addingTimeInterval(60 * 60 * 24)
        UserDefaults.standard.set("uidemo-user", forKey: APIConfig.userIdKey)
        UserDefaults.standard.set("uidemo@aegisflow.local", forKey: APIConfig.userEmailKey)
        PreferencesStorage.shared.isLoggedIn = true
        PreferencesStorage.shared.onboardingCompleted = true

        let args = ProcessInfo.processInfo.arguments
        let tabName: String = {
            if let idx = args.firstIndex(of: "-uiDemoTab"), args.indices.contains(idx + 1) {
                return args[idx + 1].lowercased()
            }
            return "dashboard"
        }()
        let tab: Int = {
            switch tabName {
            case "plan": return 2
            case "data", "health": return 3
            case "chat", "assistant": return 4
            case "profile", "me": return 5
            default: return 1
            }
        }()
        NavigationCoordinator.shared.switchTab(tab)

        if args.contains("-uiDemoPage") {
            let sampleHTML = """
            <html><head><meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
            body{font-family:-apple-system,sans-serif;background:#E8EEE9;margin:0;padding:24px;color:#2E2E2E}
            h1{font-size:22px;margin:0 0 8px} .sub{color:#6b7280;margin-bottom:20px}
            .card{background:#fff;border-radius:16px;padding:16px;margin-bottom:12px}
            .bar{height:10px;background:#D4EADB;border-radius:8px;overflow:hidden;margin-top:8px}
            .fill{height:100%;background:#4FAE83;width:72%}
            </style></head><body>
            <h1>本周睡眠分析</h1>
            <div class="sub">PAGE 模式 · GeneratedPageView</div>
            <div class="card"><b>平均睡眠</b><div>7.1 小时</div><div class="bar"><div class="fill"></div></div></div>
            <div class="card"><b>建议</b><div>固定入睡窗口，午后减少咖啡因。</div></div>
            </body></html>
            """
            NavigationCoordinator.shared.generatedPageHtml = sampleHTML
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NavigationCoordinator.shared.navigate(to: .generatedPage(html: sampleHTML))
            }
        }
    }
    #endif
}

// MARK: - 根视图
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var coordinator: NavigationCoordinator
    
    var body: some View {
        ZStack {
            if appState.isShowingSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                switch appState.currentRoute {
                case .auth:
                    LoginView()
                        .transition(.opacity)
                case .onboarding:
                    OnboardingView()
                        .transition(.opacity)
                default:
                    MainTabView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.isShowingSplash)
        .animation(.easeInOut(duration: 0.3), value: appState.currentRoute)
    }
}

// MARK: - 启动页视图
struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [.sageBright, .tealDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo
                BrandLogoBadge(size: 120)
                .scaleEffect(scale)
                
                // 应用名称
                VStack(spacing: 8) {
                    Text("AegisFlow")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("智能健康管理")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - 品牌 Logo 徽章
private struct BrandLogoBadge: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: size, height: size)

            if let uiImage = UIImage(named: "AppIcon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.62, height: size * 0.62)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.14, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            } else {
                Image(systemName: "shield.checkered")
                    .font(.system(size: size * 0.46, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 预览
#Preview {
    RootView()
        .environmentObject(DataManager.shared)
        .environmentObject(AppState())
        .environmentObject(NavigationCoordinator.shared)
}
