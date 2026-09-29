//
//  TerminalWindowController.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit
import SwiftUI
import GhosttyTerminal

public final class SuqiTerminalWindow: NSWindow {
    override public func layoutIfNeeded() {
        super.layoutIfNeeded()
        adjustTrafficLights()
    }

    override public func setFrame(_ frameRect: NSRect, display displayFlag: Bool) {
        super.setFrame(frameRect, display: displayFlag)
        adjustTrafficLights()
    }

    override public func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        adjustTrafficLights()
    }

    override public func orderFront(_ sender: Any?) {
        super.orderFront(sender)
        adjustTrafficLights()
    }

    public func adjustTrafficLights() {
        guard !styleMask.contains(.fullScreen) else { return }
        guard let close = standardWindowButton(.closeButton),
              let mini = standardWindowButton(.miniaturizeButton),
              let zoom = standardWindowButton(.zoomButton) else { return }

        // 对齐现代 macOS 呼吸感：下移左上角红绿灯（y 调至 4.0）并优化左边距，消除贴顶太高的紧绷感
        let targetY: CGFloat = 4.0
        let targetStartX: CGFloat = 13.0
        let spacing: CGFloat = 22.0

        close.setFrameOrigin(NSPoint(x: targetStartX, y: targetY))
        mini.setFrameOrigin(NSPoint(x: targetStartX + spacing, y: targetY))
        zoom.setFrameOrigin(NSPoint(x: targetStartX + spacing * 2, y: targetY))
    }
}

@MainActor
public final class TerminalWindowController: NSWindowController, NSWindowDelegate {
    public let model: SuqiWindowModel
    private var eventMonitor: Any?

    public init(model: SuqiWindowModel) {
        self.model = model

        let (userConfig, _) = GhosttyUserConfig.load()
        let isTranslucent = userConfig.backgroundOpacity < 1.0 || userConfig.backgroundBlur > 0

        // 支持从配置文件读取 window-width / window-height（支持像素或字符列数，默认对齐 Ghostty 终端网格）
        let initialWidth: CGFloat = {
            let font = NSFont(name: userConfig.fontFamily, size: userConfig.fontSize)
                ?? NSFont.monospacedSystemFont(ofSize: userConfig.fontSize, weight: .regular)
            let cellWidth = font.maximumAdvancement.width > 0 ? font.maximumAdvancement.width : (userConfig.fontSize * 0.60)
            let padding = CGFloat(userConfig.windowPaddingX * 2)
            if let w = userConfig.windowWidth {
                return w > 200 ? CGFloat(w) : CGFloat(w) * cellWidth + padding
            }
            return 100 * cellWidth + padding // 默认 100 列
        }()
        let initialHeight: CGFloat = {
            let font = NSFont(name: userConfig.fontFamily, size: userConfig.fontSize)
                ?? NSFont.monospacedSystemFont(ofSize: userConfig.fontSize, weight: .regular)
            let cellHeight = ceil(font.ascender - font.descender + font.leading) + CGFloat(userConfig.adjustCellHeight)
            let padding = CGFloat(userConfig.windowPaddingY * 2) + 32 // 32pt 标题栏
            if let h = userConfig.windowHeight {
                return h > 150 ? CGFloat(h) : CGFloat(h) * cellHeight + padding
            }
            return 30 * cellHeight + padding // 默认 30 行
        }()

        let window = SuqiTerminalWindow(
            contentRect: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight),
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

        window.title = "suqi"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        // 关键修复：关闭 isMovableByWindowBackground，使得鼠标拖拽能完全透传给 Ghostty Terminal 进行文本框选/复制；
        // 窗口移动由顶部 28pt 极简标题栏的 WindowDragArea 接管
        window.isMovableByWindowBackground = false
        if isTranslucent {
            window.isOpaque = false
            window.backgroundColor = .clear
        } else {
            window.backgroundColor = SuqiTheme.nsBackgroundColor(for: userConfig.themeName, customBackground: userConfig.background)
            window.isOpaque = true
        }
        window.hasShadow = true
        window.minSize = NSSize(width: 480, height: 280)
        window.isReleasedWhenClosed = false

        // 对齐 Ghostty 的 window-save-state：持久化记忆用户调整过的窗口大小与位置
        if userConfig.windowSaveState.lowercased() != "never" {
            window.setFrameAutosaveName("SuqiTerminalWindow")
        }

        let contentView = ContentView(model: model)
        window.contentView = NSHostingView(rootView: contentView)

        super.init(window: window)
        window.delegate = self

        // 绑定窗口关闭请求（如最后一个标签页被 ⌘W 关闭时，平滑关闭本窗口）
        model.onCloseWindowRequested = { [weak self] in
            self?.closeWindow()
        }

        setupKeyEventMonitor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupKeyEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let window = self.window else {
                return event
            }
            return TerminalActionBridge.dispatchKeyEvent(
                event: event,
                window: window,
                model: self.model,
                onCloseRequested: { [weak self] in
                    self?.closeWindow()
                }
            )
        }
    }

    public func getActiveTerminalView() -> AppTerminalView? {
        TerminalActionBridge.getActiveTerminalView(for: window)
    }

    public func handlePaste() {
        TerminalActionBridge.handlePaste(in: window, model: model)
    }

    public func handleCopy() {
        TerminalActionBridge.handleCopy(in: window, model: model)
    }

    public func handleSelectAll() {
        TerminalActionBridge.handleSelectAll(model: model)
    }

    public func closeCurrentTabOrWindow() {
        model.closeActiveSession()
    }

    public func closeWindow() {
        saveWindowFrameIfNeeded()
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        SuqiWindowManager.shared.removeWindow(self)
        window?.close()
    }

    public func saveWindowFrameIfNeeded() {
        guard let window = self.window else { return }
        let (userConfig, _) = GhosttyUserConfig.load()
        if userConfig.windowSaveState.lowercased() != "never" {
            window.saveFrame(usingName: "SuqiTerminalWindow")
        }
    }

    public func updateThemeBackground() {
        guard let window = self.window else { return }
        let (userConfig, _) = GhosttyUserConfig.load()
        let isTranslucent = userConfig.backgroundOpacity < 1.0 || userConfig.backgroundBlur > 0
        if isTranslucent {
            window.isOpaque = false
            window.backgroundColor = .clear
        } else {
            window.backgroundColor = SuqiTheme.nsBackgroundColor(for: userConfig.themeName, customBackground: userConfig.background)
            window.isOpaque = true
        }
    }

    public func showWindow() {
        guard let window = self.window else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    public func windowDidResize(_ notification: Notification) {
        saveWindowFrameIfNeeded()
        (window as? SuqiTerminalWindow)?.adjustTrafficLights()
    }

    public func windowDidMove(_ notification: Notification) {
        saveWindowFrameIfNeeded()
    }

    public func windowWillClose(_ notification: Notification) {
        saveWindowFrameIfNeeded()
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        SuqiWindowManager.shared.removeWindow(self)
    }

    public func windowDidBecomeKey(_ notification: Notification) {
        (window as? SuqiTerminalWindow)?.adjustTrafficLights()
        if let terminalView = getActiveTerminalView() {
            window?.makeFirstResponder(terminalView)
        }
    }
}
