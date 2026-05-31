import SwiftUI

/// 通用桌宠圆形预览（支持裁剪、渐变底、可选描边/阴影），用于悬浮球和个人中心等
struct DeskPetOrbPreview: View {
    let mascotName: String
    var diameter: CGFloat = 48
    var showShadow: Bool = true
    var showBorder: Bool = true
    var body: some View {
        ZStack {
            // 纯透明底，仅保留形象
            Circle()
                .fill(Color.clear)
                .frame(width: diameter, height: diameter)
                .overlay(
                    Circle().stroke(Color.white.opacity(showBorder ? 0.13 : 0), lineWidth: 1)
                )
                .shadow(color: .black.opacity(showShadow ? 0.10 : 0), radius: 7, x: 0, y: 5)

            if let ui = UIImage(named: mascotName)?.aegisTrimmingTransparentEdges().aegisAlphaThresholding(alphaThreshold: 24) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(width: diameter * 0.82, height: diameter * 0.82)
            } else {
                // 只保留白色线条，无色块
                Image(systemName: "sparkles")
                    .font(.system(size: diameter * 0.38, weight: .semibold))
                    .foregroundColor(.white)
                    .opacity(0.72)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}
