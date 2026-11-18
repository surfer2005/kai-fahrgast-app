import SwiftUI
import UIKit

/// Farben der Fahrgast-Info (wie die Webseite: Blau #0B4A8F, Hintergrund #E9EEF3), dazu eine dunkle Fassung.
enum Farbe {
    static let kopfOben = Color(hex: 0x1A5FA8)
    static let kopfUnten = Color(hex: 0x083C73)
    static let hintergrund = Color(hell: 0xE9EEF3, dunkel: 0x0E141A)
    static let karte = Color(hell: 0xFFFFFF, dunkel: 0x18212A)
    static let rand = Color(hell: 0xE3E0D6, dunkel: 0x2A3742)
    static let text = Color(hell: 0x15241D, dunkel: 0xE8EEF2)
    static let textLeise = Color(hell: 0x5D6B63, dunkel: 0xA9B6BF)
    static let akzent = Color(hell: 0x0B4A8F, dunkel: 0x6FA8E8)
    static let rot = Color(hell: 0xC0392B, dunkel: 0xF06A57)
    static let gelb = Color(hell: 0xD79A00, dunkel: 0xF2B632)
    static let gelbText = Color(hell: 0x9A6A12, dunkel: 0xF2B632)
    static let gruen = Color(hell: 0x1F6E5C, dunkel: 0x54BC9F)
    static let gruenText = Color(hell: 0x1D6B4F, dunkel: 0x54BC9F)
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    /// Eine Farbe, die sich mit Hell/Dunkel des iPhones ändert.
    init(hell: UInt32, dunkel: UInt32) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dunkel) : UIColor(hex: hell) })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

extension MeldungsArt {
    var farbe: Color {
        switch self {
        case .gruen: Farbe.gruen
        case .gelb: Farbe.gelb
        case .rot: Farbe.rot
        }
    }

    var textFarbe: Color {
        switch self {
        case .gruen: Farbe.gruenText
        case .gelb: Farbe.gelbText
        case .rot: Farbe.rot
        }
    }

    var symbol: String {
        switch self {
        case .gruen: "checkmark.circle.fill"
        case .gelb: "clock.badge.exclamationmark"
        case .rot: "exclamationmark.triangle.fill"
        }
    }
}
