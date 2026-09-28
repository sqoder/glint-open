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
    @ObservedObject public var model: SuqiWindowModel
    @ObservedObject private var settings = SuqiSettings.shared

    public init(model: SuqiWindowModel) {
        self.model = model
    }

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
                // 顶部标题/标签栏区域（高度 28）：底层承载原生可拖拽/双击缩放交互，上层渲染标签页
                ZStack(alignment: .center) {
                    WindowDragArea()
                        .frame(height: 28)

                    if model.tabs.count > 1 {
                        GhosttyTabBar(model: model)
                            .frame(height: 28)
                    } else if let activeTab = model.activeTab {
                        VStack(spacing: 1) {
                            Text(activeTab.displayPathFormatted)
                                .font(.system(size: 11.5, weight: .regular, design: .default))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineLimit(1)
                            Text("···")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.40))
                        }
                        .frame(maxWidth: .infinity, maxHeight: 28)
                        .allowsHitTesting(false)
                    }
                }
                .frame(height: 28)

                // 终端渲染工作区（全幅贴合，支持多标签与多分屏分格）
                if let activeTab = model.activeTab {
                    ActiveTabView(tab: activeTab, model: model)
                        .id(activeTab.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.clear
                }
            }
        }
        .frame(minWidth: 480, minHeight: 280)
        .ignoresSafeArea()
        .transaction { $0.animation = nil }
        // 支持将 Finder 文件直接拖拽至终端窗口自动填入转义路径
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let path = url?.path {
                        let escaped = path.replacingOccurrences(of: " ", with: "\\ ")
                        DispatchQueue.main.async {
                            model.activeSession?.send(escaped + " ")
                        }
                    }
                }
            }
            return true
        }
    }
}

public struct ActiveTabView: View {
    @ObservedObject var tab: SuqiTab
    let model: SuqiWindowModel

    public init(tab: SuqiTab, model: SuqiWindowModel) {
        self.tab = tab
        self.model = model
    }

    public var body: some View {
        PaneContainerView(node: tab.rootPane, model: model)
            .id("\(tab.id)-\(tab.paneVersion)")
    }
}

public struct PaneContainerView: View {
    let node: PaneNode
    let model: SuqiWindowModel

    public init(node: PaneNode, model: SuqiWindowModel) {
        self.node = node
        self.model = model
    }

    public var body: some View {
        switch node {
        case .terminal(let session):
            SuqiTerminalView(session: session, model: model)
                .id(session.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .split(let splitId, let axis, let first, let second):
            if axis == .horizontal {
                HStack(spacing: 0) {
                    PaneContainerView(node: first, model: model)
                        .id(first.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1)
                    PaneContainerView(node: second, model: model)
                        .id(second.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .id(splitId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    PaneContainerView(node: first, model: model)
                        .id(first.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                    PaneContainerView(node: second, model: model)
                        .id(second.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .id(splitId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
