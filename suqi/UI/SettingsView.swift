//
//  SettingsView.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import GhosttyTheme

public struct SettingsView: View {
    @State private var themeName: String
    @State private var backgroundOpacity: Double
    @State private var fontFamily: String
    @State private var fontSize: Double
    @State private var cursorStyle: String
    @State private var cursorBlink: Bool

    private static let popularThemes = [
        "Catppuccin Mocha",
        "Catppuccin Macchiato",
        "Catppuccin Frappe",
        "Catppuccin Latte",
        "TokyoNight",
        "TokyoNight Storm",
        "Dracula",
        "Nord",
        "One Dark",
        "Solarized Dark",
        "Solarized Light",
        "Gruvbox Dark",
        "GitHub Dark",
        "Monokai Pro"
    ]

    private static let availableFonts = [
        "Maple Mono NF",
        "SF Mono",
        "Menlo",
        "Monaco",
        "Fira Code",
        "JetBrains Mono",
        "Courier New"
    ]

    public init() {
        let (cfg, _) = GhosttyUserConfig.load()
        _themeName = State(initialValue: cfg.themeName)
        _backgroundOpacity = State(initialValue: cfg.backgroundOpacity)
        _fontFamily = State(initialValue: cfg.fontFamily)
        _fontSize = State(initialValue: cfg.fontSize)
        _cursorStyle = State(initialValue: cfg.cursorStyle)
        _cursorBlink = State(initialValue: cfg.cursorBlink)
    }

    private var allThemes: [String] {
        var list = Self.popularThemes
        if !list.contains(themeName) {
            list.insert(themeName, at: 0)
        }
        return list
    }

    private var allFonts: [String] {
        var list = Self.availableFonts
        if !list.contains(fontFamily) {
            list.insert(fontFamily, at: 0)
        }
        return list
    }

    public var body: some View {
        Form {
            Section("Appearance & Theme") {
                Picker("Theme", selection: $themeName) {
                    ForEach(allThemes, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .onChange(of: themeName) { _, newTheme in
                    GhosttyUserConfig.saveValues(["theme": newTheme])
                    SuqiWindowManager.shared.reloadAllWindows()
                }

                Slider(value: $backgroundOpacity, in: 0.4...1.0, step: 0.02) {
                    Text("Background Opacity")
                } minimumValueLabel: {
                    Text("40%")
                } maximumValueLabel: {
                    Text("100%")
                }
                .onChange(of: backgroundOpacity) { _, newOpacity in
                    GhosttyUserConfig.saveValues(["background-opacity": String(format: "%.2f", newOpacity)])
                    SuqiWindowManager.shared.updateAllThemeBackgrounds()
                }
            }

            Section("Font & Typography") {
                Picker("Font Family", selection: $fontFamily) {
                    ForEach(allFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .onChange(of: fontFamily) { _, newFont in
                    GhosttyUserConfig.saveValues(["font-family": newFont])
                    SuqiWindowManager.shared.reloadAllWindows()
                }

                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(fontSize)) pt")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Stepper("", value: $fontSize, in: 9...28, step: 1)
                        .onChange(of: fontSize) { _, newSize in
                            GhosttyUserConfig.saveValues(["font-size": String(Int(newSize))])
                            SuqiWindowManager.shared.reloadAllWindows()
                        }
                }
            }

            Section("Cursor") {
                Picker("Cursor Style", selection: $cursorStyle) {
                    Text("Bar").tag("bar")
                    Text("Block").tag("block")
                    Text("Underline").tag("underline")
                }
                .onChange(of: cursorStyle) { _, newStyle in
                    GhosttyUserConfig.saveValues(["cursor-style": newStyle])
                    SuqiWindowManager.shared.reloadAllWindows()
                }

                Toggle("Cursor Blink", isOn: $cursorBlink)
                    .onChange(of: cursorBlink) { _, newBlink in
                        GhosttyUserConfig.saveValues(["cursor-style-blink": newBlink ? "true" : "false"])
                        SuqiWindowManager.shared.reloadAllWindows()
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 400)
        .navigationTitle("Settings")
    }
}
