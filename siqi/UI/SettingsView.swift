//
//  SettingsView.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var settings = SiqiSettings.shared
    @ObservedObject private var sessionManager = SiqiSessionManager.shared

    public init() {}

    public var body: some View {
        Form {
            Section("外观与配色") {
                Picker("主题配色", selection: $settings.themeName) {
                    ForEach(SiqiSettings.availableThemes, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .onChange(of: settings.themeName) { _, _ in
                    TerminalWindowController.shared.updateThemeBackground()
                    sessionManager.restartActiveSession()
                }

                Slider(value: $settings.backgroundOpacity, in: 0.5...1.0, step: 0.02) {
                    Text("背景不透明度")
                } minimumValueLabel: {
                    Text("50%")
                } maximumValueLabel: {
                    Text("100%")
                }
                .onChange(of: settings.backgroundOpacity) { _, _ in
                    sessionManager.restartActiveSession()
                }
            }

            Section("字体与排版") {
                Picker("等宽字体", selection: $settings.fontFamily) {
                    ForEach(SiqiSettings.availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .onChange(of: settings.fontFamily) { _, _ in
                    sessionManager.restartActiveSession()
                }

                HStack {
                    Text("字号大小")
                    Spacer()
                    Text("\(Int(settings.fontSize)) pt")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Stepper("", value: $settings.fontSize, in: 9...28, step: 1)
                        .onChange(of: settings.fontSize) { _, _ in
                            sessionManager.restartActiveSession()
                        }
                }
            }

            Section("光标") {
                Picker("光标样式", selection: $settings.cursorStyle) {
                    Text("条状 (Bar)").tag("bar")
                    Text("方块 (Block)").tag("block")
                    Text("下划线 (Underline)").tag("underline")
                }
                .onChange(of: settings.cursorStyle) { _, _ in
                    sessionManager.restartActiveSession()
                }

                Toggle("光标闪烁", isOn: $settings.cursorBlink)
                    .onChange(of: settings.cursorBlink) { _, _ in
                        sessionManager.restartActiveSession()
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
        .navigationTitle("设置")
    }
}
