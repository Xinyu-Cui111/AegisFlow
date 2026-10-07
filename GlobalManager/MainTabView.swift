import SwiftUI

// MARK: - 主Tab导航视图
struct MainTabView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var manager: DataManager
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack(alignment: .bottom) {
                let isChatVisible = coordinator.selectedTab == 4 || coordinator.pathContains(.chat)
                Group {
                    switch coordinator.selectedTab {
                    case 1:
                        DashboardView()
                    case 2:
                        PlanView()
                    case 3:
                        HealthDataView()
                    case 4:
                        ChatView()
                    case 5:
                        ProfileView()
                    default:
                        DashboardView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, isChatVisible ? 0 : 60)
                
                if !isChatVisible {
                    MainBottomTab(selected: $coordinator.selectedTab)
                }
                
                if !isChatVisible {
                    DeskPetFloatingOverlay()
                        .allowsHitTesting(true)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationDestination(for: AppRoute.self) { route in
                routeDestination(route)
            }
        }
    }
    
    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .dashboard:
            DashboardView()
        case .plan:
            PlanView()
        case .healthData:
            HealthDataView()
        case .chat:
            ChatView()
        case .profile:
            ProfileView()
        case .statistics:
            StatisticsScreen()
        case .settings:
            SettingsView()
        case .notificationSettings:
            NotificationSettingsView()
        case .privacySettings:
            PrivacySettingsView()
        case .notificationCenter:
            NotificationCenterView()
        case .generatedPage(let html):
            GeneratedPageView(htmlContent: html)
        case .twin3D:
            Twin3DView()
        case .avatar:
            AvatarViewerView()
        case .knowledgeGraph:
            KnowledgeGraphView()
        case .foodAnalysis:
            FoodAnalysisView()
        case .healthGoals:
            HealthGoals()
        case .helpSupport:
            HelpView()
        case .level:
            AegisLevelView()
        case .rewards:
            AegisRewardsView()
        case .premium:
            AegisPremiumView()
        case .insightDetail(let category, let title):
            InsightDetailView(category: category, title: title)
        case .elemeOrder(let url):
            ElemeOrderWebView(orderUrl: url)
        case .editProfile:
            EditProfileModal()
        default:
            EmptyView()
        }
    }
}

// MARK: - 底部Tab栏组件
struct MainBottomTab: View {
    @Binding var selected: Int
    @Environment(\.colorScheme) private var colorScheme
    
    private let tabs: [(selectedIcon: String, unselectedIcon: String, name: String)] = [
        ("house.fill", "house", "首页"),
        ("calendar.badge.clock", "calendar", "计划"),
        ("chart.bar.fill", "chart.bar", "数据"),
        ("bubble.left.fill", "bubble.left", "助理"),
        ("person.fill", "person", "我的")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                let tabIndex = index + 1
                
                TabButton(
                    selectedIcon: tabs[index].selectedIcon,
                    unselectedIcon: tabs[index].unselectedIcon,
                    title: tabs[index].name,
                    isSelected: selected == tabIndex
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = tabIndex
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .padding(.bottom, safeAreaBottom)
        .background {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5))
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.07))
                        .frame(height: 0.33)
                    Spacer(minLength: 0)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: -4)
    }
    
    private var safeAreaBottom: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let bottom = windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
        return bottom > 0 ? bottom : 10
    }
}

// MARK: - Tab按钮组件
struct TabButton: View {
    let selectedIcon: String
    let unselectedIcon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? selectedIcon : unselectedIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: "#ABABAB"))
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : Color(hex: "#ABABAB"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.sageBright)
                    }
                }
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 预览
#Preview {
    MainTabView()
        .environmentObject(DataManager.shared)
}

#Preview("HealthData") {
    NavigationStack {
        HealthDataView()
            .environmentObject(DataManager.shared)
    }
}
