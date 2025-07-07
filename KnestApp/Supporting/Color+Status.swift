import SwiftUI

extension Color {
    /// カスタムステータス文字列 ("green" / "orange" / "red") を Color に変換
    init(statusColorName name: String) {
        switch name {
        case "green": self = .green
        case "orange": self = .orange
        case "red": self = .red
        default: self = .gray
        }
    }
} 