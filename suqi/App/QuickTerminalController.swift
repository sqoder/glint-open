//
//  QuickTerminalController.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit
import SwiftUI

private final class QuickTerminalPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
public final class QuickTerminalController: ObservableObject {
    public static let shared = QuickTerminalController()

    private var panel: QuickTerminalPanel?
    private var model: SuqiWindowModel?
    @Published public private(set) var isVisible: Bool = false

    private init() {
        setupLocalShortcut()
    }

    private func setupLocalShortcut() {
        // 1. 本地键盘监听：在 suqi 处于活跃状态时响应 ⌃`，以及在 Quick Terminal 处于焦点时分发所有快捷键 (⌘V / ⌘D / ⌘W 等)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == .control && (event.charactersIgnoringModifiers == "`" || event.charactersIgnoringModifiers == "~") {
                self.toggle()
                return nil
            }
            if self.isVisible, let panel = self.panel, let model = self.model, (panel.isKeyWindow || event.window === panel) {
                if event.keyCode == 53 && model.isSearching != true {
                    self.hide()
                    return nil
                }
                return TerminalActionBridge.dispatchKeyEvent(
                    event: event,
                    window: panel,
                    model: model,
                    onCloseRequested: { [weak self] in
                        self?.hide()
                    }
                )
            }
            return event
        }

        // 2. 全局键盘监听：当用户在任意其他 App 界面时，按下 ⌃` 自动滑出下拉终端
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == .control && (event.charactersIgnoringModifiers == "`" || event.charactersIgnoringModifiers == "~") {
                Task { @MainActor in
                    self?.toggle()
                }
            }
        }
    }

    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    public func show() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        if panel == nil {
            let model = SuqiWindowModel()
            self.model = model

            model.onCloseWindowRequested = { [weak self] in
                self?.hide()
            }

            let width = min(screenFrame.width * 0.96, 1200)
            let height = screenFrame.height * 0.50
            let x = screenFrame.minX + (screenFrame.width - width) / 2
            let y = screenFrame.maxY - height

            let panel = QuickTerminalPanel(
                contentRect: NSRect(x: x, y: y, width: width, height: height),
                styleMask: [.borderless, .resizable],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.isMovableByWindowBackground = false

            let contentView = ContentView(model: model)
            let hosting = NSHostingView(rootView: contentView)
            hosting.wantsLayer = true
            hosting.layer?.cornerRadius = 10
            hosting.layer?.masksToBounds = true
            panel.contentView = hosting

            self.panel = panel
        }

        guard let panel = self.panel else { return }

        let width = min(screenFrame.width * 0.96, 1200)
        let height = screenFrame.height * 0.50
        let x = screenFrame.minX + (screenFrame.width - width) / 2
        let targetY = screenFrame.maxY - height
        let targetFrame = NSRect(x: x, y: targetY, width: width, height: height)

        panel.setFrame(NSRect(x: x, y: screenFrame.maxY, width: width, height: height), display: false)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.20
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self] in
            self?.isVisible = true
        }
    }

    public func hide() {
        guard let panel = self.panel, isVisible else { return }
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let curFrame = panel.frame
        let targetFrame = NSRect(x: curFrame.minX, y: screenFrame.maxY, width: curFrame.width, height: curFrame.height)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.16
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.isVisible = false
        }
    }
}
