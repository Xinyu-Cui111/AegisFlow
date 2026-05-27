import SwiftUI

struct HealthDataView: View {
    // 1. 注入全局数据中心
    @EnvironmentObject var manager: DataManager
    
    // 2. 状态管理
    @State private var showCalendar = false
    @State private var selectedDate = Date()
    @State private var showContent = false // 用于触发入场动效
    
    var body: some View {
        ZStack {
            // --- 全局顶级流体背景 (Mesh Gradient + 材质堆叠) ---
            AegisDynamicBackground()
            
            VStack(spacing: 0) {
                // 【固定区】：吸顶区使用薄材质和渐变模糊处理增加原生层级感
                VStack(spacing: 0) {
                    headerHeader // 标题栏
                        .padding(.top, 10)
                        .padding(.bottom, 15)
                    
                    WeekDatePicker(selectedDate: $selectedDate) // 周选择器
                        .padding(.bottom, 15)
                }
                .background(
                    ZStack {
                        Color.androidBg.opacity(0.85) // 使下方滚动有透出效果 (iOS 经典毛玻璃)
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    }
                    .ignoresSafeArea(.all, edges: .top)
                )
                .zIndex(2)
                // 顶部小阴影分隔
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                
                // 【滚动区】：下方内容块
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // --- 今日健康评分大卡片 ---
                        ScoreCard(score: 85)
                            .scaleEffect(showContent ? 1 : 0.95)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0).delay(0.1), value: showContent)
                        
                        // --- 横向滑动指标栏 ---
                        IndicatorRow()
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                        
                        // --- 趋势分析模块 ---
                        AnalysisView()
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 25)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                        
                        // --- 活动构成模块 ---
                        ActivityComposition()
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                        
                        // --- 周总结模块 ---
                        WeeklySummaryView()
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 35)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
                        
                        // --- 底部健康贴士 ---
                        HealthTipView()
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 40)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: showContent)
                        
                        // 底部留白，防止被 TabBar 遮挡
                        Spacer(minLength: 120)
                    }
                    .padding(.top, 15) // 内容与固定区的间距
                }
            }
            
            // --- 日历弹窗图层 ---
            if showCalendar {
                calendarOverlay
            }
        }
        .onAppear {
            showContent = true // 激活入场弹簧动效
        }
    }
    
    // MARK: - 局部视图组件 (功能完全保持原样)
    
    private var headerHeader: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("健康数据")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                
                Text(selectedDate.formatted(date: .long, time: .omitted))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            Spacer()
            
            // 日历按钮
            Button(action: {
                withAnimation(.spring()) { showCalendar = true }
            }) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.androidGreen)
                    .frame(width: 46, height: 46)
                    .background(Color.androidCardBg)
                    .clipShape(Circle())
                    .shadow(color: Color.androidNaturalShadow.opacity(0.1), radius: 5, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var calendarOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { showCalendar = false }
            
            VStack(spacing: 20) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(.androidGreen)
                
                Button("完成") {
                    withAnimation { showCalendar = false }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.androidGreen)
                .padding(.bottom, 10)
            }
            .padding(20)
            .background(Color.androidCardBg)
            .cornerRadius(32)
            .padding(.horizontal, 30)
            .shadow(color: .black.opacity(0.1), radius: 20)
        }
        .zIndex(100)
    }
}

// MARK: - 预览
struct HealthDataView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDataView()
            .environmentObject(DataManager())
    }
}
//底部贴士
// MARK: - 底部健康贴士组件
struct HealthTipView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.androidGreen.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.androidGreen)
                    .font(.system(size: 16))
            }
            
            Text("运动后30分钟内补充蛋白质有助于肌肉恢复，建议摄入适量乳清蛋白或鸡胸肉。")
                .font(.system(size: 13))
                .foregroundColor(.gray.opacity(0.9))
                .lineSpacing(4)
            
            Spacer()
        }
        .padding(20)
        .background(Color.androidGreen.opacity(0.05)) // 极浅绿背景
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.androidGreen.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
}
