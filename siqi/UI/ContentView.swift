//
//  ContentView.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI

public struct ContentView: View {
    @ObservedObject private var manager = SiqiSessionManager.shared
    @ObservedObject private var settings = SiqiSettings.shared

    public init() {}

    private var themeBg: Color {
        SiqiTheme.backgroundColor(for: settings.themeName)
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // 全窗口一体化纯正深色底衬（完全统一，绝对无任何分层、无横线、无色差）
            themeBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 仅当多标签页时显示极简无边框标签；单标签时无任何多余元素，仅留出红绿灯呼吸间距
                if manager.sessions.count > 1 {
                    GhosttyTabBar()
                        .frame(height: 28)
                } else {
                    Color.clear
                        .frame(height: 28)
                }

                // 终端渲染工作区（全幅贴合，与底色 100% 一体化融合）
                if let active = manager.activeSession {
                    SiqiTerminalView(session: active)
                        .id(active.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.clear
                }
            }
        }
        .frame(minWidth: 480, minHeight: 280)
        .ignoresSafeArea()
    }
}
