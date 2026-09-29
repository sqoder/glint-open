//
//  TerminalWindowController.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit
import SwiftUI
import GhosttyTerminal

public final class SuqiHostingView<Content: View>: NSHostingView<Content> {
    public override var intrinsicContentSize: NSSize {
        NSSize(width: 80, height: 32)
    }

    public override var fittingSize: NSSize {
        NSSize(width: 80, height: 32)
    }
}

public final class SuqiTerminalWindow: NSWindow {
    public var isFullScreenTransitioning: Bool = false

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
        guard !styleMask.contains(.fullScreen), !isFullScreenTransitioning else { return }
        guard let close = standardWindowButton(.closeButton),
              let mini = standardWindowButton(.miniaturizeButton),
              let zoom = standardWindowButton(.zoomButton) else { return }

        // Modern macOS breathing room: center traffic light buttons vertically in 32pt titlebar
        let superHeight = close.superview?.frame.height ?? 32.0
        let targetY: CGFloat = max(0, (superHeight - 14.0) / 2.0)
        let targetStartX: CGFloat = 13.0
        let spacing: CGFloat = 20.0

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

        // Parse initial window size from window-width / window-height config
        let initialWidth: CGFloat = {
            let font = NSFont(name: userConfig.fontFamily, size: userConfig.fontSize)
                ?? NSFont.monospacedSystemFont(ofSize: userConfig.fontSize, weight: .regular)
            let cellWidth = font.maximumAdvancement.width > 0 ? font.maximumAdvancement.width : (userConfig.fontSize * 0.60)
            let padding = CGFloat(userConfig.windowPaddingX * 2)
            if let w = userConfig.windowWidth {
                return w > 200 ? CGFloat(w) : CGFloat(w) * cellWidth + padding
            }
            return 100 * cellWidth + padding // Default 100 columns
        }()
        let initialHeight: CGFloat = {
            let font = NSFont(name: userConfig.fontFamily, size: userConfig.fontSize)
                ?? NSFont.monospacedSystemFont(ofSize: userConfig.fontSize, weight: .regular)
            let cellHeight = ceil(font.ascender - font.descender + font.leading) + CGFloat(userConfig.adjustCellHeight)
            let padding = CGFloat(userConfig.windowPaddingY * 2) + 32 // 32pt titlebar
            if let h = userConfig.windowHeight {
                return h > 150 ? CGFloat(h) : CGFloat(h) * cellHeight + padding
            }
            return 30 * cellHeight + padding // Default 30 rows
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
        // Disable isMovableByWindowBackground so mouse dragging passes cleanly to Ghostty Terminal for text selection
        window.isMovableByWindowBackground = false
        if isTranslucent {
            window.isOpaque = false
            window.backgroundColor = .clear
        } else {
            window.backgroundColor = SuqiTheme.nsBackgroundColor(for: userConfig.themeName, customBackground: userConfig.background)
            window.isOpaque = true
        }
        window.hasShadow = true
        window.minSize = NSSize(width: 80, height: 32)
        window.contentMinSize = NSSize(width: 80, height: 32)
        window.isReleasedWhenClosed = false

        // Align with Ghostty window-save-state: persist window size and position
        if userConfig.windowSaveState.lowercased() != "never" {
            window.setFrameAutosaveName("SuqiTerminalWindow")
        }

        let contentView = ContentView(model: model)
        window.contentView = SuqiHostingView(rootView: contentView)

        super.init(window: window)
        window.delegate = self

        // Bind window close request (smoothly close window when last tab is closed)
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

    public func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        NSSize(
            width: max(80, frameSize.width),
            height: max(32, frameSize.height)
        )
    }

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

    public func windowWillEnterFullScreen(_ notification: Notification) {
        (window as? SuqiTerminalWindow)?.isFullScreenTransitioning = true
    }

    public func windowDidEnterFullScreen(_ notification: Notification) {
        (window as? SuqiTerminalWindow)?.isFullScreenTransitioning = false
    }

    public func windowWillExitFullScreen(_ notification: Notification) {
        (window as? SuqiTerminalWindow)?.isFullScreenTransitioning = true
    }

    public func windowDidExitFullScreen(_ notification: Notification) {
        let terminalWin = window as? SuqiTerminalWindow
        terminalWin?.isFullScreenTransitioning = false
        DispatchQueue.main.async {
            terminalWin?.adjustTrafficLights()
        }
    }
}
