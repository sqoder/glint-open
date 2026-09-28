//
//  TerminalWindowController.swift
//  siqi
//
//  Created for siqi Terminal.
//

import AppKit
import SwiftUI

@MainActor
public final class TerminalWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = TerminalWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 540),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        window.title = "siqi"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = SiqiTheme.nsBackgroundColor(for: SiqiSettings.shared.themeName)
        window.isOpaque = true
        window.hasShadow = true
        window.minSize = NSSize(width: 480, height: 280)
        window.setFrameAutosaveName("siqi.terminal.main.window")

        let contentView = ContentView()
        window.contentView = NSHostingView(rootView: contentView)
        window.center()

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateThemeBackground() {
        guard let window = self.window else { return }
        window.backgroundColor = SiqiTheme.nsBackgroundColor(for: SiqiSettings.shared.themeName)
    }

    public func showWindow() {
        guard let window = self.window else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func toggleWindow() {
        guard let window = self.window else { return }
        if window.isVisible && window.isKeyWindow {
            window.orderOut(nil)
        } else {
            showWindow()
        }
    }

    // MARK: - NSWindowDelegate

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 关闭窗口时隐藏，而非直接销毁进程（对齐 macOS 终端习惯）
        sender.orderOut(nil)
        return false
    }
}
