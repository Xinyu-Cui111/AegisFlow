import AVFoundation
import Combine
import Speech
import SwiftUI
import UIKit

// MARK: - Chat视图
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var ambientAnimating = false
    @State private var lastMessageCount = 0
    private var isConversationEmpty: Bool { viewModel.messages.isEmpty }
    private var safeAreaBottom: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let bottom = windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
        return bottom > 0 ? bottom : 10
    }

    var body: some View {
        ZStack {
            ChatAmbientBackdrop(isAnimating: ambientAnimating)
            Color(.systemBackground).opacity(0.84).ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航栏+Banner合并
                ChatNavigationBar(
                    viewModel: viewModel,
                    bannerSummary: ChatNavigationBar.BannerSummary(
                        modeTitle: viewModel.currentMode.title,
                        isTyping: viewModel.isTyping,
                        lastMessage: viewModel.messages.last?.content,
                        suggestionsCount: viewModel.quickSuggestions.count,
                        messageCount: viewModel.messages.count
                    )
                )
                .padding(.bottom, 2)

                // 主消息区
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            if viewModel.messages.isEmpty {
                                WelcomeStateView(suggestions: viewModel.quickSuggestions) {
                                    suggestion in
                                    viewModel.inputText = suggestion
                                    viewModel.sendMessage()
                                }
                            } else {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        onLike: {
                                            viewModel.feedbackMessage(
                                                message.id, isPositive: true)
                                        },
                                        onDislike: {
                                            viewModel.feedbackMessage(
                                                message.id, isPositive: false)
                                        },
                                        onReply: {
                                            viewModel.inputText =
                                                message.role == .assistant
                                                ? "请继续基于这条回复展开：\(message.content)"
                                                : message.content
                                        }
                                    )
                                    .id(message.id)
                                    .scrollTransition(.interactive, axis: .vertical) {
                                        content, phase in
                                        content
                                            .scaleEffect(phase.isIdentity ? 1.0 : 0.985)
                                            .opacity(phase.isIdentity ? 1.0 : 0.9)
                                    }
                                }
                            }

                            if viewModel.isTyping {
                                TypingIndicator()
                                    .padding(.leading, 18)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .transition(
                                        .opacity.combined(with: .move(edge: .bottom)).combined(
                                            with: .scale(scale: 0.96)))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .padding(
                            .bottom,
                            safeAreaBottom + (isConversationEmpty ? 120 : 220)
                        )
                    }
                    
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastId = viewModel.messages.last?.id {
                            DispatchQueue.main.async {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                        lastMessageCount = viewModel.messages.count
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // 输入区吸底悬浮，使用 safeAreaInset 保证命中与布局都稳定
                ChatInputArea(
                    viewModel: viewModel,
                    isConversationEmpty: isConversationEmpty
                )
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, isConversationEmpty ? 2 : 6)
                .background(
                    Color(.systemBackground)
                        .opacity(0.92)
                        .ignoresSafeArea(edges: .bottom)
                        .allowsHitTesting(false)
                )
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: -2)
            }

            // Sidebar overlay
            if viewModel.showSidebar {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture { viewModel.showSidebar = false }
                    .transition(.opacity)

                HStack {
                    ConversationListPanel(viewModel: viewModel)
                        .frame(width: UIScreen.main.bounds.width * 0.68)
                        .background(Color.sidebarBackground)
                        .transition(.move(edge: .leading))
                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showSidebar)
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { n in
                if let info = n.userInfo,
                   let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    print("[Chat] keyboard will show height:\(frame.height)")
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                print("[Chat] keyboard will hide")
            }
        }
        .fullScreenCover(isPresented: $viewModel.showKnowledgeGraph) {
            KnowledgeGraphView()
        }
        .fullScreenCover(isPresented: $viewModel.showFoodAnalysis) {
            FoodAnalysisView()
        }
        .onAppear {
            ambientAnimating = true
            lastMessageCount = viewModel.messages.count
            viewModel.loadConversations()
        }
    }
}

// MARK: - 自定义导航栏（合并Banner信息）
struct ChatNavigationBar: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var showMoreActions = false
    struct BannerSummary {
        let modeTitle: String
        let isTyping: Bool
        let lastMessage: String?
        let suggestionsCount: Int
        let messageCount: Int
    }
    var bannerSummary: BannerSummary

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: { viewModel.showSidebar.toggle() }) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(.grayDark)
                        .frame(width: 32, height: 32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
                }

                ChatHeader()

                Spacer()
                // 关闭按钮：如果在导航栈中则 pop，否则切回首页 Tab
                Button(action: {
                    if coordinator.pathContains(.chat) {
                        coordinator.pop()
                    } else {
                        coordinator.switchTab(1)
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.grayMid)
                        .frame(width: 32, height: 32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
                }

                Button(action: { showMoreActions = true }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.grayMid)
                        .frame(width: 32, height: 32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial)
            .confirmationDialog("更多操作", isPresented: $showMoreActions, titleVisibility: .visible) {
                Button("新建对话") {
                    viewModel.createNewConversation()
                }
                Button("知识图谱") {
                    viewModel.showKnowledgeGraph = true
                }
                Button("食物分析") {
                    viewModel.showFoodAnalysis = true
                }
                Button("取消", role: .cancel) {}
            }
            // 移除多余的 Divider/overlay，去掉那条线

            // 合并Banner信息
            HStack(spacing: 12) {
                Text(bannerSummary.modeTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.sageBright)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.sageBright.opacity(0.10), in: Capsule())

                Text(
                    bannerSummary.isTyping
                        ? "正在思考..."
                        : (bannerSummary.lastMessage?.isEmpty == false
                            ? "最近: \(String(bannerSummary.lastMessage!.prefix(24)))" : "欢迎开始对话")
                )
                .font(.system(size: 12))
                .foregroundColor(.grayMid)
                .lineLimit(1)

                Spacer()

                HStack(spacing: 8) {
                    Label("\(bannerSummary.messageCount)", systemImage: "message.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.grayMid)
                    Label("\(bannerSummary.suggestionsCount)", systemImage: "wand.and.stars")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.grayMid)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
        }
        .background(.ultraThinMaterial)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Chat头
struct ChatHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            ChatAssistantAvatar(size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("AI 健康助手")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.sageBright)
                        .frame(width: 6, height: 6)
                        .opacity(0.9)

                    Text("在线")
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }
            }
        }
    }
}

// MARK: - 顶部状态摘要区
struct ChatSceneBanner: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ChatAssistantAvatar(size: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text("AI 健康助手")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(summaryText)
                        .font(.system(size: 13))
                        .foregroundColor(.grayMid)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(viewModel.currentMode.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.sageBright)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.sageBright.opacity(0.12), in: Capsule())

                    HStack(spacing: 6) {
                        Circle().fill(Color.sageBright).frame(width: 6, height: 6)
                        Text(viewModel.isTyping ? "正在思考" : "在线")
                            .font(.system(size: 11))
                            .foregroundColor(.grayMid)
                    }
                }
            }

            HStack(spacing: 10) {
                BannerMetric(
                    title: "消息", value: "\(viewModel.messages.count)", icon: "message.fill")
                BannerMetric(title: "模式", value: viewModel.currentMode.title, icon: "sparkles")
                BannerMetric(
                    title: "建议", value: "\(viewModel.quickSuggestions.count)",
                    icon: "wand.and.stars")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [
                    Color.white, Color.white.opacity(0.92), Color.accentGreenLight.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.9), Color.sageBright.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 5)
    }

    private var summaryText: String {
        if viewModel.isTyping { return "正在整理你的健康反馈，稍等一下。" }
        if let last = viewModel.messages.last?.content, !last.isEmpty {
            return "最近一条对话：\(String(last.prefix(32)))"
        }
        return "围绕饮食、运动和睡眠，开始一段更顺滑的健康对话。"
    }
}

private struct BannerMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.sageBright)
                .frame(width: 20, height: 20)
                .background(Color.sageBright.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.grayMid)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.grayDark)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.75), lineWidth: 0.6)
        )
    }
}

// MARK: - 欢迎状态
struct WelcomeStateView: View {
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ChatAssistantAvatar(size: 80)

            VStack(spacing: 8) {
                Text("AI 健康助手")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.grayDark)

                Text("你好！我是你的智能健康助手\n有什么我可以帮助你的吗？")
                    .font(.system(size: 14))
                    .foregroundColor(.grayMid)
                    .multilineTextAlignment(.center)
            }

            // 快捷建议
            VStack(spacing: 12) {
                ForEach(suggestions, id: \.self) { suggestion in
                    QuickSuggestionButton(text: suggestion) {
                        onSuggestionTap(suggestion)
                    }
                }
            }

            Spacer()
        }
        .padding(.top, 40)
    }
}

// MARK: - 快捷建议按钮
struct QuickSuggestionButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.grayDark)

                Spacer()

                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.sageBright)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.white, Color.grayLight.opacity(0.06)], startPoint: .top,
                    endPoint: .bottom)
            )
            .cornerRadius(AegisCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AegisCornerRadius.medium)
                    .stroke(Color.grayLight.opacity(0.6), lineWidth: 0.6)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - 消息气泡
struct MessageBubble: View {
    let message: ChatMessage
    var onLike: (() -> Void)? = nil
    var onDislike: (() -> Void)? = nil
    var onReply: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
            messageBubbleCard
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            MessageMetaRow(
                role: message.role,
                timestamp: message.timestamp,
                isLiked: message.isLiked,
                isHtmlContent: message.isHtmlContent,
                onLike: onLike,
                onDislike: onDislike,
                onReply: onReply
            )
            .padding(.leading, message.role == .assistant ? 48 : 0)
            .padding(.trailing, message.role == .user ? 48 : 0)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
        .transition(
            .asymmetric(
                insertion: .opacity.combined(
                    with: .move(edge: message.role == .user ? .trailing : .leading)),
                removal: .opacity
            )
        )
    }

    @ViewBuilder
    private var messageBubbleCard: some View {
        if message.role == .assistant, message.isHtmlContent {
            MessageHtmlContent(html: message.content, role: message.role)
        } else {
            Text(message.content)
                .font(.system(size: 17))
                .foregroundColor(message.role == .user ? .white : .grayDark)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    ZStack(alignment: message.role == .user ? .bottomTrailing : .bottomLeading) {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(message.role == .user ? Color(hex: "#2B6CB0") : Color.white)

                        ChatBubbleTail(isFromUser: message.role == .user)
                            .fill(message.role == .user ? Color(hex: "#2B6CB0") : Color.white)
                            .frame(width: 14, height: 10)
                            .offset(x: message.role == .user ? 9 : -9, y: 8)
                            .shadow(
                                color: .black.opacity(message.role == .user ? 0.06 : 0.03),
                                radius: 1.2, x: 0, y: 1
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            message.role == .user
                                ? Color.white.opacity(0.10) : Color.grayLight.opacity(0.18),
                            lineWidth: 0.5)
                )
                .shadow(
                    color: .black.opacity(message.role == .user ? 0.08 : 0.04), radius: 12, x: 0,
                    y: 4)
        }
    }

}

// MARK: - HTML消息内容
struct MessageHtmlContent: View {
    let html: String
    var role: MessageRole = .assistant

    var body: some View {
        let preview = htmlPreview

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        LinearGradient(
                            colors: [.accentGreenLight, .sageBright],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("生成结果")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.grayDark)
                    Text("点击查看详情")
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.sageBright)
            }

            Text(preview.isEmpty ? "已生成一段适合在卡片中浏览的内容。" : preview)
                .font(.system(size: 13))
                .foregroundColor(.grayDark.opacity(0.86))
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            HStack(spacing: 8) {
                Label("智能生成", systemImage: "wand.and.stars")
                    .labelStyle(.titleAndIcon)
                Label("可继续追问", systemImage: "arrow.turn.up.right")
                    .labelStyle(.titleAndIcon)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.grayMid)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "#F8F8F8"), Color.accentGreenLight.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    Color.grayLight.opacity(0.75),
                    lineWidth: 0.7
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.035), radius: 8, x: 0, y: 3)
    }

    private var htmlPreview: String {
        let stripped =
            html
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
        return stripped
    }
}

private struct NativeChatTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var onCommit: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 17)
        textView.textColor = .label
        textView.text = text
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.keyboardType = .default
        textView.textContentType = .none
        textView.returnKeyType = .send
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .sentences
        textView.smartDashesType = .default
        textView.smartQuotesType = .default
        textView.smartInsertDeleteType = .yes
        textView.spellCheckingType = .yes
        textView.enablesReturnKeyAutomatically = false
        textView.keyboardDismissMode = .interactive
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.inputAssistantItem.leadingBarButtonGroups = []
        textView.inputAssistantItem.trailingBarButtonGroups = []
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text && !context.coordinator.isUpdatingText {
            uiView.text = text
        }

        uiView.keyboardType = .default
        uiView.textContentType = .none

        if isFocused {
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        } else if uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: NativeChatTextView
        var isUpdatingText = false

        init(parent: NativeChatTextView) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdatingText else { return }
            isUpdatingText = true
            parent.text = textView.text ?? ""
            isUpdatingText = false
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            if text == "\n" && textView.markedTextRange == nil {
                parent.onCommit()
                return false
            }
            return true
        }
    }
}

// MARK: - 打字指示器
struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ChatAssistantAvatar(size: 32)

            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.grayMid)
                        .frame(width: 8, height: 8)
                        .offset(y: animating ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.4)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - 输入区域
struct ChatInputArea: View {
    @ObservedObject var viewModel: ChatViewModel
    let isConversationEmpty: Bool
    @State private var isInputFocused: Bool = false

    private var hasTypedContent: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isCompactComposer: Bool {
        isConversationEmpty && !hasTypedContent && !isInputFocused
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            // 空会话时轻薄，开始聊天后再展开完整模式条
            if !isCompactComposer {
                HStack(spacing: 8) {
                    ForEach(AiMode.allCases, id: \.rawValue) { mode in
                        Button(action: { viewModel.currentMode = mode }) {
                            Text(mode.title)
                                .font(
                                    .system(
                                        size: 12,
                                        weight: viewModel.currentMode == mode ? .bold : .regular)
                                )
                                .foregroundColor(viewModel.currentMode == mode ? .white : .grayMid)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(
                                            viewModel.currentMode == mode
                                                ? Color.sageBright : Color.grayLight.opacity(0.5))
                                )
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: isCompactComposer ? 10 : 12) {
                Menu {
                    Button(action: { viewModel.showKnowledgeGraph = true }) {
                        Label("知识图谱", systemImage: "circle.hexagongrid.fill")
                    }
                    Button(action: { viewModel.showFoodAnalysis = true }) {
                        Label("食物分析", systemImage: "fork.knife")
                    }
                    Button(action: { viewModel.showImagePicker = true }) {
                        Label("发送图片", systemImage: "photo")
                    }
                    Button(action: { viewModel.showCamera = true }) {
                        Label("拍照", systemImage: "camera")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: isCompactComposer ? 22 : 24))
                        .foregroundColor(.grayMid)
                        .symbolEffect(.bounce, value: isInputFocused)
                }
                .buttonStyle(.plain)

                ZStack(alignment: .topLeading) {
                    if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("输入消息...")
                            .font(.system(size: 17))
                            .foregroundColor(.grayMid)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }

                    NativeChatTextView(
                        text: $viewModel.inputText,
                        isFocused: $isInputFocused,
                        onCommit: {
                            viewModel.sendMessage()
                        }
                    )
                    .frame(minHeight: 48, maxHeight: 140, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.grayLight.opacity(0.6), lineWidth: 0.5)
                )
                .shadow(
                    color: isInputFocused ? Color.sageBright.opacity(0.12) : Color.clear,
                    radius: 14, x: 0, y: 6
                )
                .scaleEffect(isInputFocused ? 1.01 : 1.0)

                // Voice input button
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    Image(systemName: viewModel.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: isCompactComposer ? 18 : 20))
                        .foregroundColor(viewModel.isRecording ? .errorRed : .grayMid)
                        .symbolEffect(.pulse, value: viewModel.isRecording)
                }
                    .buttonStyle(.plain)

                Button(action: { viewModel.sendMessage() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: isCompactComposer ? 26 : 28))
                        .foregroundColor(.white)
                        .padding(isCompactComposer ? 7 : 8)
                        .background(
                            hasTypedContent ? Color.sageBright : Color.grayLight
                        )
                        .clipShape(Circle())
                        .shadow(
                            color: (!hasTypedContent
                                ? Color.black.opacity(0.02) : Color.sageBright.opacity(0.25)),
                            radius: 6, x: 0, y: 3
                        )
                        .scaleEffect(
                            !hasTypedContent ? 0.96 : (isInputFocused ? 1.06 : 1.0)
                        )
                        .animation(
                            .spring(response: 0.24, dampingFraction: 0.78),
                            value: hasTypedContent)
                }
                .buttonStyle(.plain)
                .disabled(!hasTypedContent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isCompactComposer ? 6 : 9)
            .background(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 0.45)
            )
        }
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.94), Color.white.opacity(0.88),
                    Color(hex: "#F3F4F6").opacity(0.9),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
        .overlay(
            LinearGradient(
                colors: [Color.white.opacity(0.28), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.screen)
            .allowsHitTesting(false)
        )
        .shadow(
            color: isInputFocused ? .black.opacity(0.05) : .black.opacity(0.025), radius: 10, x: 0,
            y: -1
        )
        
        .padding(.bottom, 0)
        .zIndex(999)
    }

    private var safeAreaBottom: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let bottom = windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
        return bottom > 0 ? bottom : 10
    }
}

// MARK: - 对话列表面板
struct ConversationListPanel: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("对话列表")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.grayDark)
                Spacer()
                Button(action: { viewModel.showSidebar = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.grayMid)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            Button(action: { viewModel.createNewConversation() }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新建对话")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.sageBright)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .background(Color.sageBright.opacity(0.1))

            Divider()

            if viewModel.conversations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "message")
                        .font(.system(size: 48))
                        .foregroundColor(.grayLight)

                    Text("暂无对话记录")
                        .font(.system(size: 15))
                        .foregroundColor(.grayMid)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
            } else {
                List {
                    ForEach(viewModel.conversations) { conversation in
                        ConversationRow(
                            conversation: conversation,
                            isSelected: viewModel.currentSessionId == conversation.id
                        ) {
                            viewModel.switchConversation(conversation.id)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { viewModel.deleteConversation(at: $0) }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - 对话行
struct ConversationRow: View {
    let conversation: ConversationItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ChatAssistantAvatar(size: 40, isSelected: isSelected)

                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.grayDark)
                        .lineLimit(1)

                    Text(conversation.lastMessage.isEmpty ? "暂无消息" : conversation.lastMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.grayMid)
                        .lineLimit(1)
                }

                Spacer()

                if let time = conversation.lastMessageTime {
                    Text(formatRelativeTime(time))
                        .font(.system(size: 11))
                        .foregroundColor(.grayMid)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Bubble Shape
private struct ChatBubbleShape: Shape {
    var isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let corners: UIRectCorner =
            isFromUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 共享头像
private struct ChatAssistantAvatar: View {
    var size: CGFloat
    var isSelected: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            if let ui = UIImage(named: "AppIcon") {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.82, height: size * 0.82)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            } else {
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundColor(.sageBright)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.gray.opacity(0.13), lineWidth: 0.7)
        )
    }
}

// MARK: - 页面氛围背景
private struct ChatAmbientBackdrop: View {
    var isAnimating: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.sageBright.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 42)
                .offset(x: isAnimating ? -120 : -90, y: -260)
                .animation(
                    .easeInOut(duration: 10).repeatForever(autoreverses: true), value: isAnimating)

            Circle()
                .fill(Color.accentGreenLight.opacity(0.16))
                .frame(width: 300, height: 300)
                .blur(radius: 52)
                .offset(x: isAnimating ? 120 : 90, y: -130)
                .animation(
                    .easeInOut(duration: 12).repeatForever(autoreverses: true), value: isAnimating)

            Circle()
                .fill(Color.white.opacity(0.84))
                .frame(width: 180, height: 180)
                .blur(radius: 38)
                .offset(x: isAnimating ? 90 : 60, y: 260)
                .animation(
                    .easeInOut(duration: 11).repeatForever(autoreverses: true), value: isAnimating)
        }
        .ignoresSafeArea()
    }
}

// MARK: - 统一消息信息栏
private struct MessageMetaRow: View {
    let role: MessageRole
    let timestamp: Date
    let isLiked: Bool?
    let isHtmlContent: Bool
    let onLike: (() -> Void)?
    let onDislike: (() -> Void)?
    let onReply: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            MetaAvatar(role: role)

            Text(role == .assistant ? "AI 助手" : "我")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.grayDark)

            Text(timestampString)
                .font(.system(size: 10))
                .foregroundColor(.grayMid)

            Spacer(minLength: 8)

            if role == .assistant && !isHtmlContent {
                MetaFeedbackBar(
                    isLiked: isLiked,
                    onLike: onLike,
                    onDislike: onDislike,
                    onReply: onReply
                )
            } else {
                MessageStateChip(text: role == .assistant ? "已理解" : "已发送")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}

private struct MetaAvatar: View {
    let role: MessageRole

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: role == .assistant
                            ? [Color.grayLight.opacity(0.35), Color.white]
                            : [Color.grayLight.opacity(0.55), Color.whitePure],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: role == .assistant ? "sparkles" : "person.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.grayMid)
        }
        .frame(width: 18, height: 18)
        .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 0.5))
    }
}

private struct MetaFeedbackBar: View {
    let isLiked: Bool?
    let onLike: (() -> Void)?
    let onDislike: (() -> Void)?
    let onReply: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { onLike?() }) {
                Image(systemName: isLiked == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isLiked == true ? .sageBright : .grayMid)
            }

            Button(action: { onDislike?() }) {
                Image(systemName: isLiked == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isLiked == false ? .errorRed : .grayMid)
            }

            Button(action: { onReply?() }) {
                Image(systemName: "arrowshape.turn.up.left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.grayMid)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.grayLight.opacity(0.55), lineWidth: 0.6))
    }
}

private struct MessageStateChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.grayMid)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.grayLight.opacity(0.55), lineWidth: 0.6))
    }
}

private struct ChatBubbleTail: Shape {
    var isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isFromUser {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.minY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Chat视图模型
class ChatViewModel: ObservableObject {

    // 网络请求配置
    private let baseURL = APIConfig.baseURL
    private var token: String? {
        UserDefaults.standard.string(forKey: APIConfig.accessTokenKey)
    }

    // 消息状态
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isTyping: Bool = false
    @Published var showSidebar: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var showCamera: Bool = false
    @Published var showKnowledgeGraph: Bool = false
    @Published var showFoodAnalysis: Bool = false
    @Published var currentSessionId: String?
    @Published var error: String? = nil
    @Published var currentMode: AiMode = .chat
    @Published var isRecording: Bool = false

    // Speech recognition
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hans"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // 对话列表
    @Published var conversations: [ConversationItem] = []

    // 快捷建议
    let quickSuggestions = [
        "今天有什么健康建议？",
        "帮我规划一周运动",
        "分析我的饮食习惯",
    ]

    // MARK: - 初始化
    init() {
        if APIConfig.shouldAllowMockData {
            loadMockConversations()
        }
    }

    // MARK: - 发送消息
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: inputText,
            timestamp: Date()
        )
        messages.append(userMessage)
        let currentInput = inputText
        inputText = ""

        // 更新对话的最后消息
        updateConversationLastMessage(currentInput)

        // 调用AI接口
        fetchAIResponse(userInput: currentInput)
    }

    // MARK: - 网络请求: 调用AI
    func fetchAIResponse(userInput: String) {
        isTyping = true

        guard let token = token, let url = URL(string: "\(baseURL)/chat/completions") else {
            isTyping = false
            error = "请先登录以使用 AI 助手"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["message": userInput]
        if let currentSessionId, !currentSessionId.isEmpty {
            body["sessionId"] = currentSessionId
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isTyping = false

                if let error = error {
                    self.error = error.localizedDescription
                    return
                }

                guard let data = data else {
                    self.error = "服务器无响应"
                    return
                }

                do {
                    let result = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
                    if result.success, let aiMessage = result.data {
                        let assistantMessage = ChatMessage(
                            id: UUID().uuidString,
                            role: .assistant,
                            content: aiMessage.content,
                            timestamp: ISO8601DateFormatter().date(from: aiMessage.timestamp ?? "")
                                ?? Date(),
                            isHtmlContent: false
                        )
                        self.messages.append(assistantMessage)
                        self.currentSessionId = aiMessage.sessionId ?? self.currentSessionId

                    } else {
                        self.error = result.message
                    }
                } catch {
                    self.error = "解析 AI 回复失败"
                }
            }
        }.resume()
    }

    // MARK: - 模拟AI回复（离线模式）
    private func simulateAIResponse(userInput: String) {
        isTyping = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.isTyping = false

            var responseContent = ""
            let input = userInput.lowercased()

            if input.contains("饮食") || input.contains("吃什么") {
                responseContent =
                    "根据您今天的饮食记录，我建议您多吃一些富含蛋白质的食物，如鸡胸肉、鱼和豆制品。同时，保证蔬菜和水果的摄入量，这样可以帮助您维持营养均衡。"
            } else if input.contains("运动") || input.contains("跑步") {
                responseContent = "建议您每天进行30分钟的中等强度运动，如快走、慢跑或游泳。每周保持3-5次运动习惯，可以有效提升心肺功能和代谢水平。"
            } else if input.contains("睡眠") || input.contains("睡不着") {
                responseContent =
                    "改善睡眠的小技巧：1. 睡前1小时避免使用电子设备；2. 保持卧室温度在18-22度；3. 尝试深呼吸或冥想放松；如果持续失眠，建议咨询医生。"
            } else if input.contains("喝水") || input.contains("饮水") {
                responseContent =
                    "建议您每天饮用1500-2000ml的水。可以在起床后喝一杯温水，餐前半小时喝一杯水，帮助消化。避免一次性大量饮水，少量多次更健康。"
            } else {
                responseContent =
                    "好的，我理解您的需求。让我为您分析一下：根据您近期的健康数据，您的整体状况良好。建议继续保持良好的生活习惯，如有任何健康问题，随时可以咨询我。"
            }

            let assistantMessage = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                content: responseContent,
                timestamp: Date()
            )
            self.messages.append(assistantMessage)
        }
    }

    // MARK: - 网络请求: 获取对话列表
    func loadConversations() {
        guard let token = token else {
            loadMockConversations()
            return
        }

        guard let url = URL(string: "\(baseURL)/chat/history") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let data = data {
                    if let result = try? JSONDecoder().decode(
                        ConversationsResponse.self, from: data)
                    {
                        if result.success, let conversations = result.data?.sessions {
                            self.conversations = conversations.map { item in
                                ConversationItem(
                                    id: item.id,
                                    title: item.title,
                                    lastMessage: item.lastMessage?.content ?? "",
                                    lastMessageTime: ISO8601DateFormatter().date(
                                        from: item.lastMessageAt ?? "")
                                )
                            }
                            return
                        }
                    }
                }
                if APIConfig.shouldAllowMockData {
                    self.loadMockConversations()
                } else {
                    self.conversations = []
                }
            }
        }.resume()
    }

    private func loadMockConversations() {
        conversations = [
            ConversationItem(
                id: "1",
                title: "健康饮食建议",
                lastMessage: "今天的饮食计划...",
                lastMessageTime: Date().addingTimeInterval(-3600)
            ),
            ConversationItem(
                id: "2",
                title: "运动计划",
                lastMessage: "跑步的好处...",
                lastMessageTime: Date().addingTimeInterval(-86400)
            ),
            ConversationItem(
                id: "3",
                title: "睡眠改善",
                lastMessage: "如何提高睡眠质量...",
                lastMessageTime: Date().addingTimeInterval(-172800)
            ),
        ]
    }

    // MARK: - 创建新对话
    func createNewConversation() {
        let newConversation = ConversationItem(
            id: UUID().uuidString,
            title: "新对话",
            lastMessage: "",
            lastMessageTime: nil
        )
        conversations.insert(newConversation, at: 0)
        currentSessionId = newConversation.id
        messages = []
        showSidebar = false

        // 保存到服务器
        saveConversation(newConversation)
    }

    // MARK: - 切换对话
    func switchConversation(_ id: String) {
        currentSessionId = id

        // 从服务器加载消息
        loadMessages(for: id)
        showSidebar = false
    }

    // MARK: - 网络请求: 加载消息
    func loadMessages(for sessionId: String) {
        guard let token = token, let url = URL(string: "\(baseURL)/chat/session/\(sessionId)")
        else {
            messages = []
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let data = data,
                    let result = try? JSONDecoder().decode(MessagesResponse.self, from: data)
                {
                    if result.success, let messages = result.data?.messages {
                        self.messages = messages.map { msg in
                            ChatMessage(
                                id: msg.id,
                                role: msg.role == "user" ? .user : .assistant,
                                content: msg.content,
                                timestamp: ISO8601DateFormatter().date(from: msg.createdAt)
                                    ?? Date()
                            )
                        }
                        return
                    }
                }
                self.messages = []
            }
        }.resume()
    }

    // MARK: - 删除对话
    func deleteConversation(at index: Int) {
        guard index < conversations.count else { return }
        let conversation = conversations[index]

        // 本地删除
        conversations.remove(at: index)

        // 如果删除的是当前对话，清空消息
        if currentSessionId == conversation.id {
            currentSessionId = nil
            messages = []
        }
    }

    // MARK: - 网络请求: 删除对话
    func deleteConversationFromServer(_ id: String) {
        return
    }

    // MARK: - 网络请求: 保存消息
    func saveMessage(_ message: ChatMessage) {
        return
    }

    // MARK: - 网络请求: 保存对话
    func saveConversation(_ conversation: ConversationItem) {
        return
    }

    // MARK: - 更新对话最后消息
    private func updateConversationLastMessage(_ message: String) {
        if let index = conversations.firstIndex(where: { $0.id == currentSessionId }) {
            conversations[index].lastMessage = message
            conversations[index].lastMessageTime = Date()
        }
    }

    // MARK: - 消息反馈
    func feedbackMessage(_ messageId: String, isPositive: Bool) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].isLiked = isPositive
        }
    }

    // MARK: - 语音录入
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self, status == .authorized else { return }

                self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = self.recognitionRequest else { return }
                recognitionRequest.shouldReportPartialResults = true

                let inputNode = self.audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
                    buffer, _ in
                    recognitionRequest.append(buffer)
                }

                self.audioEngine.prepare()
                do {
                    try self.audioEngine.start()
                    self.isRecording = true
                } catch {
                    self.error = "无法启动录音"
                    return
                }

                self.recognitionTask = self.speechRecognizer?.recognitionTask(
                    with: recognitionRequest
                ) { [weak self] result, error in
                    guard let self = self else { return }
                    if let result = result {
                        DispatchQueue.main.async {
                            self.inputText = result.bestTranscription.formattedString
                        }
                    }
                    if error != nil || (result?.isFinal == true) {
                        self.stopRecording()
                    }
                }
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

// MARK: - 数据模型
struct ChatMessage: Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var isHtmlContent: Bool = false
    var isLiked: Bool? = nil
}

enum MessageRole: String {
    case user
    case assistant
    case system
}

struct ConversationItem: Identifiable {
    let id: String
    var title: String
    var lastMessage: String
    var lastMessageTime: Date?
}

// MARK: - 网络响应结构

struct ChatCompletionsResponse: Codable {
    let success: Bool
    let message: String
    let data: ChatCompletionsData?
}

struct ChatCompletionsData: Codable {
    let id: String
    let role: String?
    let content: String
    let timestamp: String?
    let suggestions: [String]?
    let sessionId: String?
}

struct ConversationsResponse: Codable {
    let success: Bool
    let message: String
    let data: ConversationsPayload?
}

struct ConversationsData: Codable {
    let id: String
    let title: String
    let lastMessage: ConversationLastMessage?
    let lastMessageAt: String?
}

struct ConversationsPayload: Codable {
    let sessions: [ConversationsData]
}

struct ConversationLastMessage: Codable {
    let content: String
    let role: String
}

struct MessagesResponse: Codable {
    let success: Bool
    let message: String
    let data: MessagesPayload?
}

struct MessagesData: Codable {
    let id: String
    let role: String
    let content: String
    let createdAt: String
}

struct MessagesPayload: Codable {
    let sessionId: String
    let messages: [MessagesData]
}

// MARK: - 预览
#Preview {
    ChatView()
        .environmentObject(DataManager.shared)
}
