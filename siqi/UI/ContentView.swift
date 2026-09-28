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
        ZStack {
            // 背景层：当透明度 < 1.0 时呈现深色毛玻璃，否则呈现纯粹扎实的主题深色底色
            if settings.backgroundOpacity < 1.0 {
                VisualEffectBackgroundView(material: .hudWindow, blendingMode: .behindWindow)
                themeBg.opacity(settings.backgroundOpacity)
            } else {
                themeBg
            }

            VStack(spacing: 0) {
                // 仅当开启多个标签页时显示极简 Tab 栏；单标签时仅预留红绿灯拖拽安全高度
                if manager.sessions.count > 1 {
                    GhosttyTabBar()
                } else {
                    Color.clear
                        .frame(height: 24)
                }

                // 纯粹的终端工作区
                if let active = manager.activeSession {
                    SiqiTerminalView(session: active)
                        .id(active.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.clear
                }
            }
        }
        .frame(minWidth: 500, minHeight: 300)
        .ignoresSafeArea()
    }
}

// MARK: - NSVisualEffectView Wrapper

struct VisualEffectBackgroundView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}
