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

    public var body: some View {
        ZStack {
            // 背景毛玻璃沉浸层（可调浓度）
            VisualEffectBackgroundView(material: .underWindowBackground, blendingMode: .behindWindow)
                .opacity(settings.backgroundOpacity)

            Color.black.opacity(1.0 - settings.backgroundOpacity * 0.7)

            VStack(spacing: 0) {
                // 1. 顶部 Header / Tab 栏
                TerminalHeaderBar()

                // 2. 终端工作区
                if let active = manager.activeSession {
                    SiqiTerminalView(session: active)
                        .id(active.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.clear
                }
            }
        }
        .frame(minWidth: 520, minHeight: 320)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(SiqiTheme.borderColor, lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .ignoresSafeArea()
    }
}

// MARK: - NSVisualEffectView Wrapper

struct VisualEffectBackgroundView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
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
