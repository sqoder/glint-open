//
//  SuqiSettings.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import Combine

@MainActor
public final class SuqiSettings: ObservableObject {
    public static let shared = SuqiSettings()

    public static let availableThemes: [String] = [
        "TokyoNight",
        "TokyoNight Storm",
        "Catppuccin Macchiato",
        "Catppuccin Mocha",
        "Dracula",
        "Nord",
        "One Dark",
        "Solarized Dark",
        "Gruvbox Dark",
        "GitHub Dark"
    ]

    public static let availableFonts: [String] = [
        "SF Mono",
        "Menlo",
        "Monaco",
        "Courier New"
    ]

    @AppStorage("suqi.themeName") public var themeName: String = "TokyoNight" {
        didSet { objectWillChange.send() }
    }

    @AppStorage("suqi.fontSize") public var fontSize: Double = 13.5 {
        didSet { objectWillChange.send() }
    }

    @AppStorage("suqi.fontFamily") public var fontFamily: String = "SF Mono" {
        didSet { objectWillChange.send() }
    }

    @AppStorage("suqi.backgroundOpacity") public var backgroundOpacity: Double = 1.0 {
        didSet { objectWillChange.send() }
    }

    @AppStorage("suqi.cursorStyle") public var cursorStyle: String = "bar" {
        didSet { objectWillChange.send() }
    }

    @AppStorage("suqi.cursorBlink") public var cursorBlink: Bool = true {
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
