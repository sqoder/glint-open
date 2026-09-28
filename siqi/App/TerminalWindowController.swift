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

    /// 统一粘贴入口：智能区分图片与纯文本
    public func handlePaste() {
        guard let session = SiqiSessionManager.shared.activeSession else { return }

        let pb = NSPasteboard.general
        var hasImage = pb.canReadObject(forClasses: [NSImage.self], options: nil)
            || (pb.types?.contains { $0 == .png || $0 == .tiff || $0.rawValue.contains("image") || $0.rawValue.contains("png") } ?? false)

        // 检测剪贴板是否拷贝了图片类文件 URL (如截屏生成的临时 png 文件)
        if !hasImage, let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], let first = urls.first {
            let ext = first.pathExtension.lowercased()
            if ["png", "jpg", "jpeg", "gif", "webp", "bmp", "heic"].contains(ext) {
                hasImage = true
            }
        }

        if hasImage {
            // 向终端 PTY 发送 ASCII 22 (\u{16}，即 Control+V) 字节！
            // Claude Code / Codex / Antigravity CLI 等终端工具检测到 Control+V 会立即读取系统剪贴板中的图片并完成图片粘贴！
            session.send("\u{16}")
        } else {
            // 纯文本：使用 Ghostty 的 paste_from_clipboard 执行标准终端粘贴（支持括号粘贴防错）
            _ = session.state.performBindingAction("paste_from_clipboard")
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
