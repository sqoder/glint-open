//
//  SettingsPopoverView.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI

public struct SettingsPopoverView: View {
    @ObservedObject private var settings = SiqiSettings.shared
    @ObservedObject private var sessionManager = SiqiSessionManager.shared
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("终端设置", systemImage: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SiqiTheme.textPrimary)
                Spacer()
            }

            Divider()
                .opacity(0.3)

            // 1. 主题选择
            VStack(alignment: .leading, spacing: 6) {
                Text("主题配色")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SiqiTheme.textSecondary)

                Picker("", selection: $settings.themeName) {
                    ForEach(SiqiSettings.availableThemes, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            // 2. 字体选择
            VStack(alignment: .leading, spacing: 6) {
                Text("等宽字体")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SiqiTheme.textSecondary)

                Picker("", selection: $settings.fontFamily) {
                    ForEach(SiqiSettings.availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            // 3. 字号调整
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("字号大小")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SiqiTheme.textSecondary)
                    Spacer()
                    Text("\(Int(settings.fontSize)) pt")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(SiqiTheme.textPrimary)
                }

                HStack(spacing: 8) {
                    Button {
                        settings.decreaseFontSize()
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 24, height: 20)
                    }
                    .buttonStyle(.bordered)

                    Slider(value: $settings.fontSize, in: 10...24, step: 0.5)

                    Button {
                        settings.increaseFontSize()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 24, height: 20)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // 4. 背景不透明度
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("背景毛玻璃浓度")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SiqiTheme.textSecondary)
                    Spacer()
                    Text("\(Int(settings.backgroundOpacity * 100))%")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(SiqiTheme.textPrimary)
                }

                Slider(value: $settings.backgroundOpacity, in: 0.5...1.0, step: 0.02)
            }

            Divider()
                .opacity(0.3)

            HStack {
                Text("修改配置后重启会话生效")
                    .font(.system(size: 10))
                    .foregroundStyle(SiqiTheme.textTertiary)

                Spacer()

                Button {
                    sessionManager.restartActiveSession()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("立即重载会话")
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(SiqiTheme.accentColor.opacity(0.8))
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}
