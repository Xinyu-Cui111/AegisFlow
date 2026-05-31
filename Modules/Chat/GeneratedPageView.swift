import SwiftUI
import WebKit

// MARK: - GeneratedPageView
struct GeneratedPageView: View {
    let htmlContent: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            WebView(htmlContent: htmlContent)
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
}

// MARK: - WebView
struct WebView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(Color(hex: "#E8EEE9"))
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlContent, baseURL: URL(string: "https://local.aegisflow/"))
    }
}

// MARK: - 预览
#Preview {
    GeneratedPageView(htmlContent: "<html><body style='background:#E8EEE9'><h1>测试页面</h1></body></html>")
}
