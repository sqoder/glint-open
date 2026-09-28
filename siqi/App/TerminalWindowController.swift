//
//  TerminalWindowController.swift
//  siqi
//
//  Created for siqi Terminal.
//

import AppKit
import SwiftUI
import GhosttyTerminal

@MainActor
public final class TerminalWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = TerminalWindowController()
    private var eventMonitor: Any?

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
        setupKeyEventMonitor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupKeyEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let window = self.window, window.isKeyWindow else {
                return event
            }

            let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])

            // 1. 处理 ⌘V (Cmd+V 粘贴图片/文本)
            if flags == .command && event.charactersIgnoringModifiers == "v" {
                self.handlePaste()
                return nil // 消费此事件，拦截系统蜂鸣与默认冒泡
            }

            // 2. 处理 ⌘C (Cmd+C 复制选中文本)
            if flags == .command && event.charactersIgnoringModifiers == "c" {
                if let session = SiqiSessionManager.shared.activeSession {
                    _ = session.state.performBindingAction("copy_to_clipboard")
                    return nil
                }
            }

            return event
        }
    }

    private func findTerminalView(in view: NSView) -> AppTerminalView? {
        if let tv = view as? AppTerminalView {
            return tv
        }
        for subview in view.subviews {
            if let found = findTerminalView(in: subview) {
                return found
            }
        }
        return nil
    }

    private func getActiveTerminalView() -> AppTerminalView? {
        guard let window = self.window else { return nil }
        if let tv = window.firstResponder as? AppTerminalView {
            return tv
        }
        if let contentView = window.contentView, let tv = findTerminalView(in: contentView) {
            return tv
        }
        return nil
    }

    private func pasteboardContainsImage(_ pb: NSPasteboard) -> Bool {
        let imageExtensions: Set<String> = [
            "png", "jpg", "jpeg", "gif", "webp", "bmp", "heic", "tiff", "svg", "ico"
        ]

        // 1. 优先检查是否有文件 URL
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            return urls.contains { url in
                imageExtensions.contains(url.pathExtension.lowercased())
            }
        }

        // 2. 无文件 URL 时，检查是否包含纯内存图片数据 (如浏览器右键复制图片、系统剪贴板原生截图等)
        if pb.canReadObject(forClasses: [NSImage.self], options: nil) {
            return true
        }

        if let types = pb.types {
            let imageTypes: Set<NSPasteboard.PasteboardType> = [.png, .tiff]
            if types.contains(where: { imageTypes.contains($0) || $0.rawValue.lowercased().contains("image") || $0.rawValue.lowercased().contains("png") }) {
                return true
            }
        }

        return false
    }

    /// 统一粘贴入口：智能区分图片与纯文本
    public func handlePaste() {
        guard let window = self.window else { return }
        let terminalView = getActiveTerminalView()

        if let terminalView, window.firstResponder !== terminalView {
            window.makeFirstResponder(terminalView)
        }

        let pb = NSPasteboard.general
        let isImage = pasteboardContainsImage(pb)

        if isImage {
            if let terminalView {
                terminalView.triggerImagePasteShortcut()
            }
        } else {
            if let session = SiqiSessionManager.shared.activeSession {
                _ = session.state.performBindingAction("paste_from_clipboard")
            }
        }
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
