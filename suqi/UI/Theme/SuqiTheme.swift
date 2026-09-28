//
//  SuqiTheme.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit
import GhosttyTheme

public enum SuqiTheme {
    public static func backgroundColor(for themeName: String) -> Color {
        if let theme = GhosttyThemeCatalog.theme(named: themeName) {
            return Color(hex: theme.background)
        }
        return Color(hex: "1a1b26")
    }

    public static func nsBackgroundColor(for themeName: String) -> NSColor {
        if let theme = GhosttyThemeCatalog.theme(named: themeName) {
            return NSColor(hex: theme.background)
        }
        return NSColor(hex: "1a1b26")
    }
}

// MARK: - Color Hex Extensions

public extension Color {
    init(hex: String, defaultColor: Color = Color(red: 26/255.0, green: 27/255.0, blue: 38/255.0)) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        if Scanner(string: clean).scanHexInt64(&int) {
            let r, g, b: Double
            switch clean.count {
            case 6:
                r = Double((int >> 16) & 0xFF) / 255.0
                g = Double((int >> 8) & 0xFF) / 255.0
                b = Double(int & 0xFF) / 255.0
                self.init(red: r, green: g, blue: b)
                return
            default:
                break
            }
        }
        self = defaultColor
    }
}

public extension NSColor {
    convenience init(hex: String, defaultColor: NSColor = NSColor(srgbRed: 26/255.0, green: 27/255.0, blue: 38/255.0, alpha: 1.0)) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        if Scanner(string: clean).scanHexInt64(&int) {
            let r, g, b: CGFloat
            switch clean.count {
            case 6:
                r = CGFloat((int >> 16) & 0xFF) / 255.0
                g = CGFloat((int >> 8) & 0xFF) / 255.0
                b = CGFloat(int & 0xFF) / 255.0
                self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
                return
            default:
                break
            }
        }
        self.init(cgColor: defaultColor.cgColor)!
    }
}
