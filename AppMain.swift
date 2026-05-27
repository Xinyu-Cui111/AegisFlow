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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
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
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }
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

// MARK: - 预览
#Preview {
    RootView()
        .environmentObject(DataManager.shared)
        .environmentObject(AppState())
        .environmentObject(NavigationCoordinator.shared)
}
