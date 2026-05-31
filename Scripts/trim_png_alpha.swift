#!/usr/bin/env swift
import AppKit
import CoreGraphics

/// 桌宠 PNG：支持 **RGBA 透明边裁剪**，或对 **RGB + 纯色背景** 做近似抠底后再裁剪（解决「长方不透明画布」观感）。
///
/// **勿放入 `Modules/`**：该目录会被 Xcode 同步进 iOS Target；本脚本仅在 Mac 终端运行：
/// `swift Scripts/trim_png_alpha.swift Modules/DeskPet/AegisAssets.xcassets/DeskPetMascot.imageset/DeskPetMascot.png`
guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("用法: swift Scripts/trim_png_alpha.swift <png路径>\n".utf8))
    exit(1)
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path)

guard let img = NSImage(contentsOf: url) else {
    FileHandle.standardError.write(Data("无法读取图片\n".utf8))
    exit(1)
}

guard let rep = img.representations.compactMap({ $0 as? NSBitmapImageRep }).first else {
    FileHandle.standardError.write(Data("需要 NSBitmapImageRep\n".utf8))
    exit(1)
}

let w = rep.pixelsWide
let h = rep.pixelsHigh
let bpp = rep.bitsPerPixel / 8
let rowBytes = rep.bytesPerRow
guard let srcBytes = rep.bitmapData else {
    FileHandle.standardError.write(Data("无法读取像素\n".utf8))
    exit(1)
}

let tol = 38

func sampleRGB(x: Int, y: Int) -> (Int, Int, Int) {
    let o = y * rowBytes + x * bpp
    let r = Int(srcBytes[o])
    let g = Int(srcBytes[o + 1])
    let b = Int(srcBytes[o + 2])
    return (r, g, b)
}

func sampleAlpha(x: Int, y: Int) -> Int {
    guard bpp >= 4 else { return 255 }
    let o = y * rowBytes + x * bpp
    return Int(srcBytes[o + 3])
}

/// 取四角与边缘均值作为背景估计（适合白底 / 浅灰底插画）
func estimateBackground() -> (Int, Int, Int) {
    var rs = 0, gs = 0, bs = 0, n = 0
    let xs = [0, w / 2, w - 1]
    let ys = [0, h / 2, h - 1]
    for y in ys {
        for x in xs where x >= 0 && x < w && y >= 0 && y < h {
            let p = sampleRGB(x: x, y: y)
            rs += p.0; gs += p.1; bs += p.2; n += 1
        }
    }
    for x in stride(from: 0, to: w, by: max(1, w / 64)) {
        let p1 = sampleRGB(x: x, y: 0)
        let p2 = sampleRGB(x: x, y: h - 1)
        rs += p1.0 + p2.0; gs += p1.1 + p2.1; bs += p1.2 + p2.2; n += 2
    }
    for y in stride(from: 0, to: h, by: max(1, h / 64)) {
        let p1 = sampleRGB(x: 0, y: y)
        let p2 = sampleRGB(x: w - 1, y: y)
        rs += p1.0 + p2.0; gs += p1.1 + p2.1; bs += p1.2 + p2.2; n += 2
    }
    guard n > 0 else { return (255, 255, 255) }
    return (rs / n, gs / n, bs / n)
}

let bg = estimateBackground()

func isForeground(x: Int, y: Int) -> Bool {
    if bpp >= 4 {
        let a = sampleAlpha(x: x, y: y)
        if a <= 12 { return false }
        if a < 250 {
            return true
        }
    }
    let p = sampleRGB(x: x, y: y)
    let dr = abs(p.0 - bg.0)
    let dg = abs(p.1 - bg.1)
    let db = abs(p.2 - bg.2)
    return max(dr, dg, db) > tol
}

var minX = w
var maxX = 0
var minY = h
var maxY = 0

for y in 0 ..< h {
    for x in 0 ..< w where isForeground(x: x, y: y) {
        minX = min(minX, x)
        maxX = max(maxX, x)
        minY = min(minY, y)
        maxY = max(maxY, y)
    }
}

guard minX <= maxX, minY <= maxY else {
    FileHandle.standardError.write(Data("未检测到前景（背景阈值 tol=\(tol)，可调脚本）\n".utf8))
    exit(1)
}

let pad = 6
minX = max(0, minX - pad)
minY = max(0, minY - pad)
maxX = min(w - 1, maxX + pad)
maxY = min(h - 1, maxY + pad)

let cropx = maxX - minX + 1
let cropy = maxY - minY + 1

guard cropx > 0, cropy > 0 else { exit(1) }

var rgba = [UInt8](repeating: 0, count: cropx * cropy * 4)
for dy in 0 ..< cropy {
    let sy = minY + dy
    for dx in 0 ..< cropx {
        let sx = minX + dx
        let di = (dy * cropx + dx) * 4
        let r = Int(srcBytes[sy * rowBytes + sx * bpp])
        let g = Int(srcBytes[sy * rowBytes + sx * bpp + 1])
        let b = Int(srcBytes[sy * rowBytes + sx * bpp + 2])

        let alpha: UInt8
        if bpp >= 4 {
            alpha = srcBytes[sy * rowBytes + sx * bpp + 3]
        } else {
            let dr = abs(r - bg.0)
            let dg = abs(g - bg.1)
            let db = abs(b - bg.2)
            let dmax = max(dr, dg, db)
            alpha = dmax > tol ? 255 : 0
        }

        rgba[di] = UInt8(r)
        rgba[di + 1] = UInt8(g)
        rgba[di + 2] = UInt8(b)
        rgba[di + 3] = alpha
    }
}

let colorSpace = CGColorSpaceCreateDeviceRGB()
let rowRGBA = cropx * 4
guard let ctx = CGContext(
    data: &rgba,
    width: cropx,
    height: cropy,
    bitsPerComponent: 8,
    bytesPerRow: rowRGBA,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
),
    let outCG = ctx.makeImage() else {
    FileHandle.standardError.write(Data("构建 CGImage 失败\n".utf8))
    exit(1)
}

let outImg = NSImage(cgImage: outCG, size: NSSize(width: cropx, height: cropy))
guard let tiff = outImg.tiffRepresentation,
      let outRep = NSBitmapImageRep(data: tiff),
      let png = outRep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("编码 PNG 失败\n".utf8))
    exit(1)
}

do {
    try png.write(to: url, options: .atomic)
    print("已裁切并写入透明底: \(w)×\(h) → \(cropx)×\(cropy) （估计背景 RGB \(bg.0),\(bg.1),\(bg.2)）→ \(path)")
} catch {
    FileHandle.standardError.write(Data("写入失败: \(error)\n".utf8))
    exit(1)
}
