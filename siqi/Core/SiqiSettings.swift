//
//  SiqiSettings.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI
import Combine

@MainActor
public final class SiqiSettings: ObservableObject {
    public static let shared = SiqiSettings()

    public static let availableThemes: [String] = [
        "Tokyo Night",
        "Catppuccin Macchiato",
        "Catppuccin Mocha",
        "Dracula",
        "Nord",
        "One Dark",
        "Solarized Dark",
        "Gruvbox Dark",
        "Monokai",
        "GitHub Dark"
    ]

    public static let availableFonts: [String] = [
        "SF Mono",
        "Menlo",
        "Monaco",
        "Courier New"
    ]

    @AppStorage("siqi.themeName") public var themeName: String = "Tokyo Night" {
        didSet { objectWillChange.send() }
    }

    @AppStorage("siqi.fontSize") public var fontSize: Double = 13.5 {
        didSet { objectWillChange.send() }
    }

    @AppStorage("siqi.fontFamily") public var fontFamily: String = "SF Mono" {
        didSet { objectWillChange.send() }
    }

    @AppStorage("siqi.backgroundOpacity") public var backgroundOpacity: Double = 0.88 {
        didSet { objectWillChange.send() }
    }

    @AppStorage("siqi.cursorStyle") public var cursorStyle: String = "bar" {
        didSet { objectWillChange.send() }
    }

    @AppStorage("siqi.cursorBlink") public var cursorBlink: Bool = true {
        didSet { objectWillChange.send() }
    }

    private init() {}

    public func increaseFontSize() {
        if fontSize < 28.0 {
            fontSize = min(28.0, fontSize + 1.0)
        }
    }

    public func decreaseFontSize() {
        if fontSize > 9.0 {
            fontSize = max(9.0, fontSize - 1.0)
        }
    }

    public func resetFontSize() {
        fontSize = 13.5
    }
}
