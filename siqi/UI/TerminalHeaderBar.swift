//
//  TerminalHeaderBar.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI
import AppKit

public struct TerminalHeaderBar: View {
    @ObservedObject private var manager = SiqiSessionManager.shared
    @State private var showingSettings: Bool = false

    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            // 为 macOS 左上角红绿灯留出安全间距
            Spacer()
                .frame(width: 68)

            // 标签栏
            TerminalTabBar()

            Spacer()

            // 当前目录胶囊徽章（点击在访达中打开）
            if let active = manager.activeSession {
                Button {
                    let path = active.fullDirectory
                    let url = URL(fileURLWithPath: path)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "folder")
                            .font(.system(size: 9.5))
                            .foregroundStyle(SiqiTheme.textSecondary)

                        Text(active.displayDirectory)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(SiqiTheme.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
                .help("在访达中打开当前目录")
            }

            // 清屏按钮 (⌘K)
            Button {
                manager.clearActiveSession()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10.5))
                    .foregroundStyle(SiqiTheme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .help("清空当前屏幕 (⌘K)")

            // 重启当前终端会话按钮 (⌘R)
            Button {
                manager.restartActiveSession()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10.5))
                    .foregroundStyle(SiqiTheme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .help("重启当前会话 (⌘R)")

            // 设置按钮 (齿轮)
            Button {
                showingSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 11))
                    .foregroundStyle(SiqiTheme.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .help("终端设置")
            .popover(isPresented: $showingSettings, arrowEdge: .bottom) {
                SettingsPopoverView()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(SiqiTheme.headerBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(SiqiTheme.borderColor)
                .frame(height: 0.5)
        }
    }
}
