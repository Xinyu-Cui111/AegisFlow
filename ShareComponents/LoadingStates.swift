import SwiftUI

// MARK: - Loading Spinner (matches Android CircularProgressIndicator)
struct AegisLoadingView: View {
    var message: String = "加载中..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .sageBright))
                .scaleEffect(1.2)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.grayMid)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State (matches Android empty state pattern)
struct AegisEmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.grayLight)

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.grayDark)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.grayMid)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.sageBright)
                        .cornerRadius(AegisCornerRadius.small)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Error Banner (matches Android Snackbar-style)
struct AegisErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orangeWarm)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.grayDark)
                .lineLimit(3)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.grayMid)
                }
            }
        }
        .padding(12)
        .background(Color.orangeWarm.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Shimmer Loading Placeholder
struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.grayLight.opacity(0.4),
                Color.grayLight.opacity(0.1),
                Color.grayLight.opacity(0.4)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: isAnimating ? 200 : -200)
        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

struct ShimmerCard: View {
    var height: CGFloat = 80

    var body: some View {
        RoundedRectangle(cornerRadius: AegisCornerRadius.medium)
            .fill(Color.white)
            .frame(height: height)
            .overlay(
                ShimmerView()
                    .clipShape(RoundedRectangle(cornerRadius: AegisCornerRadius.medium))
            )
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}
