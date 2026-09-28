//
//  TerminalWindowController.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit
import SwiftUI
import GhosttyTerminal

@MainActor
public final class TerminalWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = TerminalWindowController()
    private var eventMonitor: Any?

    private init() {
        let (userConfig, _) = GhosttyUserConfig.load()
        let isTranslucent = userConfig.backgroundOpacity < 1.0 || userConfig.backgroundBlur > 0

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

        window.title = "suqi"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        if isTranslucent {
            window.isOpaque = false
            window.backgroundColor = .clear
        } else {
            window.backgroundColor = SuqiTheme.nsBackgroundColor(for: userConfig.themeName)
            window.isOpaque = true
        }
        window.hasShadow = true
        window.minSize = NSSize(width: 480, height: 280)
        window.setFrameAutosaveName("suqi.terminal.main.window")

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
            guard let self, let window = self.window, (window.isKeyWindow || window.isMainWindow || event.window === window) else {
                return event
            }

            let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])

            // 1. 处理 ⌘V (Cmd+V 粘贴图片/文本)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "v" {
                self.handlePaste()
                return nil // 消费此事件，拦截系统蜂鸣与默认冒泡
            }

            // 2. 处理 ⌘C (Cmd+C 复制选中文本)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "c" {
                if let session = SuqiSessionManager.shared.activeSession {
                    _ = session.state.performBindingAction("copy_to_clipboard")
                    return nil
                }
            }

            // 3. 处理 ⌘1 .. ⌘9 (切换标签页)
            if flags == .command, let char = event.charactersIgnoringModifiers?.first, char >= "1" && char <= "9" {
                if let tabIndex = Int(String(char)) {
                    SuqiSessionManager.shared.selectTab(at: tabIndex - 1)
                    return nil
                }
            }

            // 4. 处理 ⌘[ / ⌘] (标签页前后切换)
            if flags == .command && event.charactersIgnoringModifiers == "[" {
                SuqiSessionManager.shared.previousTab()
                return nil
            }
            if flags == .command && event.charactersIgnoringModifiers == "]" {
                SuqiSessionManager.shared.nextTab()
                return nil
            }

            // 5. 处理 ⌘T (新建标签页)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "t" {
                SuqiSessionManager.shared.createNewSession()
                return nil
            }

            // 5.1 处理 ⌘D (垂直分屏新建 Split Right)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "d" {
                SuqiSessionManager.shared.splitRight()
                return nil
            }

            // 5.2 处理 ⌘Shift+D (水平分屏新建 Split Down)
            if flags == [.command, .shift] && event.charactersIgnoringModifiers?.lowercased() == "d" {
                SuqiSessionManager.shared.splitDown()
                return nil
            }

            // 5.3 处理 ⌘Option+Left / ⌘Option+Right (分屏切换)
            if flags == [.command, .option] {
                if event.specialKey == .leftArrow || event.specialKey == .upArrow {
                    SuqiSessionManager.shared.previousPane()
                    return nil
                }
                if event.specialKey == .rightArrow || event.specialKey == .downArrow {
                    SuqiSessionManager.shared.nextPane()
                    return nil
                }
            }

            // 6. 处理 ⌘W (关闭当前分屏或标签页)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "w" {
                SuqiSessionManager.shared.closeActiveSession()
                return nil
            }

            // 7. 处理 ⌘K (清屏)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "k" {
                SuqiSessionManager.shared.clearActiveSession()
                return nil
            }

            // 8. 处理 ⌘+ / ⌘= / ⌘- / ⌘0 (Ghostty 字号动态缩放)
            if flags == .command || flags == [.command, .shift] {
                let char = event.charactersIgnoringModifiers
                if char == "=" || char == "+" {
                    _ = SuqiSessionManager.shared.activeSession?.state.performBindingAction("increase_font_size:1")
                    return nil
                } else if char == "-" {
                    _ = SuqiSessionManager.shared.activeSession?.state.performBindingAction("decrease_font_size:1")
                    return nil
                } else if char == "0" {
                    _ = SuqiSessionManager.shared.activeSession?.state.performBindingAction("reset_font_size")
                    return nil
                }
            }

            // 9. 处理 ⌘Shift+[ / ⌘Shift+] (标签页切换快捷键变体)
            if flags == [.command, .shift] {
                if event.charactersIgnoringModifiers == "{" || event.charactersIgnoringModifiers == "[" {
                    SuqiSessionManager.shared.previousTab()
                    return nil
                }
                if event.charactersIgnoringModifiers == "}" || event.charactersIgnoringModifiers == "]" {
                    SuqiSessionManager.shared.nextTab()
                    return nil
                }
            }

            // 10. 处理 ⌘F (搜索)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "f" {
                _ = SuqiSessionManager.shared.activeSession?.state.performBindingAction("start_search")
                return nil
            }

            // 11. 处理 ⌘, (打开配置文件)
            if flags == .command && event.charactersIgnoringModifiers == "," {
                let (_, path) = GhosttyUserConfig.load()
                let target = path ?? NSString(string: "~/.config/ghostty/config").expandingTildeInPath
                NSWorkspace.shared.open(URL(fileURLWithPath: target))
                return nil
            }

            // 12. 处理 ⌘Shift+, (重载配置)
            if flags == [.command, .shift] && (event.charactersIgnoringModifiers == "<" || event.charactersIgnoringModifiers == ",") {
                SuqiSessionManager.shared.reloadAllSessions()
                self.updateThemeBackground()
                return nil
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
            // 若从 Finder 复制了图片文件，补全内存 TIFF 格式，确保 CLI 都能无缝读取
            if !pb.canReadObject(forClasses: [NSImage.self], options: nil) {
                let imageExtensions: Set<String> = [
                    "png", "jpg", "jpeg", "gif", "webp", "bmp", "heic", "tiff", "svg", "ico"
                ]
                if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
                   let firstImgUrl = urls.first(where: { imageExtensions.contains($0.pathExtension.lowercased()) }),
                   let img = NSImage(contentsOf: firstImgUrl),
                   let tiffData = img.tiffRepresentation {
                    pb.setData(tiffData, forType: .tiff)
                }
            }

            if let terminalView {
                terminalView.triggerImagePasteShortcut()
            }
        } else {
            if let session = SuqiSessionManager.shared.activeSession {
                _ = session.state.performBindingAction("paste_from_clipboard")
            }
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
            window.backgroundColor = SuqiTheme.nsBackgroundColor(for: userConfig.themeName)
            window.isOpaque = true
        }
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
