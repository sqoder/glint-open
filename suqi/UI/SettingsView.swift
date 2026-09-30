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
    @State private var backgroundBlur: Double
    @State private var fontFamily: String
    @State private var fontSize: Double
    @State private var adjustCellHeight: Int
    @State private var windowPaddingX: Int
    @State private var windowPaddingY: Int
    @State private var cursorStyle: String
    @State private var cursorBlink: Bool
    @State private var isAccessibilityTrusted: Bool = QuickTerminalController.isAccessibilityTrusted

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
        _backgroundBlur = State(initialValue: Double(cfg.backgroundBlur))
        _fontFamily = State(initialValue: cfg.fontFamily)
        _fontSize = State(initialValue: cfg.fontSize)
        _adjustCellHeight = State(initialValue: cfg.adjustCellHeight)
        _windowPaddingX = State(initialValue: cfg.windowPaddingX)
        _windowPaddingY = State(initialValue: cfg.windowPaddingY)
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

                Slider(value: $backgroundBlur, in: 0...50, step: 2) {
                    Text("Background Blur")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("50")
                }
                .onChange(of: backgroundBlur) { _, newBlur in
                    GhosttyUserConfig.saveValues(["background-blur": "\(Int(newBlur))"])
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

                HStack {
                    Text("Adjust Cell Height")
                    Spacer()
                    Text("\(adjustCellHeight) pt")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Stepper("", value: $adjustCellHeight, in: -4...12, step: 1)
                        .onChange(of: adjustCellHeight) { _, newAdj in
                            GhosttyUserConfig.saveValues(["adjust-cell-height": "\(newAdj)"])
                            SuqiWindowManager.shared.reloadAllWindows()
                        }
                }
            }

            Section("Window & Spacing") {
                HStack {
                    Text("Padding X")
                    Spacer()
                    Text("\(windowPaddingX) pt")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Stepper("", value: $windowPaddingX, in: 0...36, step: 2)
                        .onChange(of: windowPaddingX) { _, newPad in
                            GhosttyUserConfig.saveValues(["window-padding-x": "\(newPad)"])
                            SuqiWindowManager.shared.reloadAllWindows()
                        }
                }

                HStack {
                    Text("Padding Y")
                    Spacer()
                    Text("\(windowPaddingY) pt")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Stepper("", value: $windowPaddingY, in: 0...36, step: 2)
                        .onChange(of: windowPaddingY) { _, newPad in
                            GhosttyUserConfig.saveValues(["window-padding-y": "\(newPad)"])
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

            Section("Quick Terminal & Global Hotkey (⌃`)") {
                HStack {
                    Text("Accessibility Permission")
                    Spacer()
                    if isAccessibilityTrusted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Granted")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button("Request Permission") {
                            QuickTerminalController.requestAccessibilityPermissions()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isAccessibilityTrusted = QuickTerminalController.isAccessibilityTrusted
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 500)
        .navigationTitle("Settings")
    }
}
