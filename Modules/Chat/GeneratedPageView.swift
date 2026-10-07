import SwiftUI
import WebKit

// MARK: - GeneratedPageView
struct GeneratedPageView: View {
    let htmlContent: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // 由外层 NavigationStack 承载，避免嵌套导致空白
        DemoHTMLWebView(htmlContent: htmlContent)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("助理生成页面")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.grayDark)
                    }
                }
            }
    }
}

// MARK: - WebView（CI 演示：make 时即 load，避免 update 竞态空白页）
struct DemoHTMLWebView: UIViewRepresentable {
    let htmlContent: String

    func makeCoordinator() -> Coordinator {
        Coordinator(html: htmlContent)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.91, green: 0.93, blue: 0.91, alpha: 1)
        webView.navigationDelegate = context.coordinator
        context.coordinator.load(into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.html != htmlContent {
            context.coordinator.html = htmlContent
            context.coordinator.load(into: webView)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var html: String
        private var didLoad = false

        init(html: String) {
            self.html = html
        }

        func load(into webView: WKWebView) {
            let payload = html.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !payload.isEmpty else { return }
            didLoad = true
            webView.loadHTMLString(payload, baseURL: nil)
        }
    }
}

// 兼容旧调用名
typealias WebView = DemoHTMLWebView

// MARK: - 预览
#Preview {
    NavigationStack {
        GeneratedPageView(htmlContent: "<html><body style='background:#E8EEE9;font-family:-apple-system;padding:24px'><h1>本周睡眠分析</h1><p>PAGE 模式测试</p></body></html>")
    }
}
