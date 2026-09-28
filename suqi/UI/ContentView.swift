//
//  ContentView.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit

public struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    public init(material: NSVisualEffectView.Material = .underWindowBackground, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

public struct ContentView: View {
    @ObservedObject private var manager = SuqiSessionManager.shared
    @ObservedObject private var settings = SuqiSettings.shared

    public init() {}

    private var userConfig: GhosttyUserConfig {
        GhosttyUserConfig.load().config
    }

    private var isTranslucent: Bool {
        userConfig.backgroundOpacity < 1.0 || userConfig.backgroundBlur > 0
    }

    private var themeBg: Color {
        SuqiTheme.backgroundColor(for: userConfig.themeName)
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // 背景底衬：根据 Ghostty 配置自适应纯色或毛玻璃模糊
            if isTranslucent {
                VisualEffectBackground()
                    .ignoresSafeArea()
                themeBg.opacity(userConfig.backgroundOpacity)
                    .ignoresSafeArea()
            } else {
                themeBg
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // 仅当多标签页时显示极简无边框标签；单标签时无任何多余元素，仅留出红绿灯呼吸间距
                if manager.tabs.count > 1 {
                    GhosttyTabBar()
                        .frame(height: 28)
                } else {
                    Color.clear
                        .frame(height: 28)
                }

                // 终端渲染工作区（全幅贴合，支持多标签与多分屏分格）
                if let activeTab = manager.activeTab {
                    ActiveTabView(tab: activeTab)
                        .id(activeTab.id)
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

public struct ActiveTabView: View {
    @ObservedObject var tab: SuqiTab

    public init(tab: SuqiTab) {
        self.tab = tab
    }

    public var body: some View {
        PaneContainerView(node: tab.rootPane)
    }
}

public struct PaneContainerView: View {
    let node: PaneNode
    @ObservedObject private var manager = SuqiSessionManager.shared

    public init(node: PaneNode) {
        self.node = node
    }

    public var body: some View {
        switch node {
        case .terminal(let session):
            SuqiTerminalView(session: session)
                .id(session.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    manager.selectSession(id: session.id)
                }

        case .split(_, let axis, let first, let second):
            if axis == .horizontal {
                HStack(spacing: 0) {
                    PaneContainerView(node: first)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1)
                    PaneContainerView(node: second)
                }
            } else {
                VStack(spacing: 0) {
                    PaneContainerView(node: first)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                    PaneContainerView(node: second)
                }
            }
        }
    }
}
