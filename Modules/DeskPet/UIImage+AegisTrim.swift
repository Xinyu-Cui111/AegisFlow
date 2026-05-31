import UIKit

extension UIImage {
    /// 裁掉四周近似透明像素，减轻「长方画布」悬浮感；失败时返回原图。
    func aegisTrimmingTransparentEdges(alphaThreshold: UInt8 = 12) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let normalized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }

        guard let cgImage = normalized.cgImage else { return self }
        let w = cgImage.width
        let h = cgImage.height
        guard w > 0, h > 0 else { return self }

        let bytesPerPixel = 4
        let rowBytes = w * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: rowBytes * h)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &pixels,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: rowBytes,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return self }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        var minX = w
        var maxX = 0
        var minY = h
        var maxY = 0

        for y in 0 ..< h {
            let row = y * rowBytes
            for x in 0 ..< w {
                let a = pixels[row + x * bytesPerPixel + 3]
                if a > alphaThreshold {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }

        guard minX <= maxX, minY <= maxY else { return self }

        let crop = CGRect(
            x: CGFloat(minX),
            y: CGFloat(minY),
            width: CGFloat(maxX - minX + 1),
            height: CGFloat(maxY - minY + 1)
        )

        guard let cropped = cgImage.cropping(to: crop) else { return self }
        return UIImage(cgImage: cropped, scale: scale, orientation: .up)
    }

    /// 将几乎透明或接近背景噪点的像素设为完全透明，避免边缘出现马赛克及半透明背景
    func aegisAlphaThresholding(alphaThreshold: UInt8 = 24) -> UIImage {
        guard let cgImage = self.cgImage else { return self }

        let w = cgImage.width
        let h = cgImage.height
        let bytesPerPixel = 4
        let rowBytes = w * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: rowBytes * h)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &pixels,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: rowBytes,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return self }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        for y in 0 ..< h {
            let row = y * rowBytes
            for x in 0 ..< w {
                let idx = row + x * bytesPerPixel
                let a = pixels[idx + 3]
                if a <= alphaThreshold {
                    pixels[idx + 3] = 0
                }
            }
        }

        guard let outCtx = CGContext(
            data: &pixels,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: rowBytes,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let outCG = outCtx.makeImage() else { return self }

        return UIImage(cgImage: outCG, scale: scale, orientation: .up)
    }
}
