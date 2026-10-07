import SwiftUI

#if DEBUG
/// DEBUG launch helpers for Simulator / CI media capture (`-uiDemo`, `-uiDemoScroll`, …).
enum UIDemoLaunch {
    static let topID = "uidemo-top"
    static let bottomID = "uidemo-bottom"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiDemo")
    }

    static var wantsScroll: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiDemoScroll")
    }

    static func argValue(after flag: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: flag), args.indices.contains(idx + 1) else { return nil }
        return args[idx + 1]
    }

    static var tabName: String {
        (argValue(after: "-uiDemoTab") ?? "dashboard").lowercased()
    }

    static var routeName: String? {
        argValue(after: "-uiDemoRoute")?.lowercased()
    }

    static var aiModeName: String? {
        argValue(after: "-uiDemoMode")?.uppercased()
    }
}
#endif

extension View {
    /// Mark the top of a scrollable page for `-uiDemoScroll`.
    @ViewBuilder
    func uiDemoTopAnchor() -> some View {
        #if DEBUG
        self.id(UIDemoLaunch.topID)
        #else
        self
        #endif
    }

    /// Append a bottom scroll anchor (keeps the original view).
    @ViewBuilder
    func uiDemoBottomAnchor() -> some View {
        #if DEBUG
        VStack(spacing: 0) {
            self
            Color.clear.frame(height: 1).id(UIDemoLaunch.bottomID)
        }
        #else
        self
        #endif
    }

    /// Auto scroll down then up while CI records video (`-uiDemoScroll`).
    func uiDemoPerformAutoScroll(proxy: ScrollViewProxy) -> some View {
        #if DEBUG
        self.onAppear {
            guard UIDemoLaunch.wantsScroll else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 2.4)) {
                    proxy.scrollTo(UIDemoLaunch.bottomID, anchor: .bottom)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    proxy.scrollTo(UIDemoLaunch.topID, anchor: .top)
                }
            }
        }
        #else
        self
        #endif
    }
}
