//
//  SettingsView.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var settings = SuqiSettings.shared

    public init() {}

    public var body: some View {
        Form {
            Section("外观与配色") {
                Picker("主题配色", selection: $settings.themeName) {
                    ForEach(SuqiSettings.availableThemes, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .onChange(of: settings.themeName) { _, _ in
                    SuqiWindowManager.shared.reloadAllWindows()
                }

                Slider(value: $settings.backgroundOpacity, in: 0.5...1.0, step: 0.02) {
                    Text("背景不透明度")
                } minimumValueLabel: {
                    Text("50%")
                } maximumValueLabel: {
                    Text("100%")
                }
                .onChange(of: settings.backgroundOpacity) { _, _ in
                    SuqiWindowManager.shared.reloadAllWindows()
                }
            }

            Section("字体与排版") {
                Picker("等宽字体", selection: $settings.fontFamily) {
                    ForEach(SuqiSettings.availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .onChange(of: settings.fontFamily) { _, _ in
                    SuqiWindowManager.shared.reloadAllWindows()
                }

                HStack {
                    Text("字号大小")
                    Spacer()
                    Text("\(Int(settings.fontSize)) pt")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Stepper("", value: $settings.fontSize, in: 9...28, step: 1)
                        .onChange(of: settings.fontSize) { _, _ in
                            SuqiWindowManager.shared.reloadAllWindows()
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
                    SuqiWindowManager.shared.reloadAllWindows()
                }

                Toggle("光标闪烁", isOn: $settings.cursorBlink)
                    .onChange(of: settings.cursorBlink) { _, _ in
                        SuqiWindowManager.shared.reloadAllWindows()
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 380)
        .navigationTitle("设置")
    }
}
