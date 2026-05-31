import SwiftUI
import UIKit

extension Image {
    /// 若系统暂无对应 SF Symbol，则回退到占位图标，避免空白问号。
    init(safeSystemName name: String, fallback: String = "circle.fill") {
        if UIImage(systemName: name) != nil {
            self.init(systemName: name)
        } else {
            self.init(systemName: fallback)
        }
    }
}
