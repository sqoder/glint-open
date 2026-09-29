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
            let padding = CGFloat(userConfig.windowPaddingY * 2) + 28 // 28pt 标题栏
            if let h = userConfig.windowHeight {
                return h > 150 ? CGFloat(h) : CGFloat(h) * cellHeight + padding
            }
            return 30 * cellHeight + padding // 默认 30 行
        }()

        let window = NSWindow(
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

            let isRelevant = window.isKeyWindow || window.isMainWindow || event.window === window
            let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])

            guard isRelevant else {
                return event
            }

            // 1. 处理 ⌘V (Cmd+V 粘贴图片/文本至本窗口当前活跃窗格)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "v" {
                self.handlePaste()
                return nil
            }

            // 2. 处理 ⌘C (Cmd+C 复制选中文本)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "c" {
                self.handleCopy()
                return nil
            }

            // 3. 处理 ⌘N (新建独立窗口)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "n" {
                SuqiWindowManager.shared.createWindow(workingDirectory: self.model.activeSession?.fullDirectory)
                return nil
            }

            // 4. 处理 ⌘T (新建标签页)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "t" {
                self.model.createNewTab()
                return nil
            }

            // 5. 处理 ⌘D (垂直分屏 Split Right)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "d" {
                self.model.splitRight()
                return nil
            }

            // 6. 处理 ⌘Shift+D (水平分屏 Split Down)
            if flags == [.command, .shift] && event.charactersIgnoringModifiers?.lowercased() == "d" {
                self.model.splitDown()
                return nil
            }

            // 6.5. 处理 ⌃⌘= (均等所有分屏 Equalize Splits)
            if flags == [.control, .command] && (event.charactersIgnoringModifiers == "=" || event.charactersIgnoringModifiers == "+") {
                self.model.equalizeSplits()
                return nil
            }

            // 6.6. 处理 ⌘Shift+Enter (分屏最大化聚焦 Toggle Split Zoom)
            if flags == [.command, .shift] && (event.keyCode == 36 || event.charactersIgnoringModifiers == "\r") {
                self.model.toggleZoom()
                return nil
            }

            // 6.7. 处理 ⌃⌘H / ⌃⌘J / ⌃⌘K / ⌃⌘L 以及 ⌃⌘方向键 (空间几何方向分屏聚焦 Goto Split)
            if flags == [.control, .command] {
                let char = event.charactersIgnoringModifiers?.lowercased()
                if char == "h" || event.specialKey == .leftArrow {
                    self.model.focusPane(in: .left)
                    return nil
                }
                if char == "l" || event.specialKey == .rightArrow {
                    self.model.focusPane(in: .right)
                    return nil
                }
                if char == "k" || event.specialKey == .upArrow {
                    self.model.focusPane(in: .up)
                    return nil
                }
                if char == "j" || event.specialKey == .downArrow {
                    self.model.focusPane(in: .down)
                    return nil
                }
            }

            // 6.8. 处理 ⌘F (终端回滚内容原生查找)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "f" {
                self.model.isSearching.toggle()
                return nil
            }

            // 6.9. 处理 ⌃` (下拉式浮动终端 Quick Terminal)
            if flags == .control && (event.charactersIgnoringModifiers == "`" || event.charactersIgnoringModifiers == "~") {
                QuickTerminalController.shared.toggle()
                return nil
            }

            // 7. 处理 ⌘Option+Left / ⌘Option+Right (分屏切换)
            if flags == [.command, .option] {
                if event.specialKey == .leftArrow || event.specialKey == .upArrow {
                    self.model.previousPane()
                    return nil
                }
                if event.specialKey == .rightArrow || event.specialKey == .downArrow {
                    self.model.nextPane()
                    return nil
                }
            }

            // 8. 处理 ⌘W (优先关闭当前分屏或当前 Tab；若全关则关闭本窗口)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "w" {
                self.closeCurrentTabOrWindow()
                return nil
            }

            // 9. 处理 ⌘Shift+W (直接关闭整个窗口)
            if flags == [.command, .shift] && event.charactersIgnoringModifiers?.lowercased() == "w" {
                self.closeWindow()
                return nil
            }

            // 10. 处理 ⌘1 .. ⌘9 (切换标签页)
            if flags == .command, let char = event.charactersIgnoringModifiers?.first, char >= "1" && char <= "9" {
                if let tabIndex = Int(String(char)) {
                    self.model.selectTab(at: tabIndex - 1)
                    return nil
                }
            }

            // 11. 处理 ⌘[ / ⌘] (标签页前后切换)
            if flags == .command && event.charactersIgnoringModifiers == "[" {
                self.model.previousTab()
                return nil
            }
            if flags == .command && event.charactersIgnoringModifiers == "]" {
                self.model.nextTab()
                return nil
            }

            // 12. 处理 ⌘Shift+[ / ⌘Shift+] (标签页切换快捷键变体)
            if flags == [.command, .shift] {
                if event.charactersIgnoringModifiers == "{" || event.charactersIgnoringModifiers == "[" {
                    self.model.previousTab()
                    return nil
                }
                if event.charactersIgnoringModifiers == "}" || event.charactersIgnoringModifiers == "]" {
                    self.model.nextTab()
                    return nil
                }
            }

            // 13. 处理 ⌘K (清屏)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "k" {
                self.model.clearActiveSession()
                return nil
            }

            // 14. 处理 ⌘+ / ⌘= / ⌘- / ⌘0 (Ghostty 字号动态缩放)
            if flags == .command || flags == [.command, .shift] {
                let char = event.charactersIgnoringModifiers
                if char == "=" || char == "+" {
                    _ = self.model.activeSession?.state.performBindingAction("increase_font_size:1")
                    return nil
                } else if char == "-" {
                    _ = self.model.activeSession?.state.performBindingAction("decrease_font_size:1")
                    return nil
                } else if char == "0" {
                    _ = self.model.activeSession?.state.performBindingAction("reset_font_size")
                    return nil
                }
            }

            // 15. 处理 ⌘F (搜索)
            if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "f" {
                _ = self.model.activeSession?.state.performBindingAction("start_search")
                return nil
            }

            // 16. 处理 ⌘, (打开配置文件)
            if flags == .command && event.charactersIgnoringModifiers == "," {
                let (_, path) = GhosttyUserConfig.load()
                let target = path ?? NSString(string: "~/.config/ghostty/config").expandingTildeInPath
                NSWorkspace.shared.open(URL(fileURLWithPath: target))
                return nil
            }

            // 17. 处理 ⌘Shift+, (重载配置)
            if flags == [.command, .shift] && (event.charactersIgnoringModifiers == "<" || event.charactersIgnoringModifiers == ",") {
                SuqiWindowManager.shared.reloadAllWindows()
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

    public func getActiveTerminalView() -> AppTerminalView? {
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

        // 2. 无文件 URL 时，检查是否包含纯内存图片数据 (如系统原生截屏、浏览器复制图片等)
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
            // 若从 Finder 复制了图片文件，补全内存 TIFF 和 PNG 格式，确保 CLI 工具都能无缝读取
            if !pb.canReadObject(forClasses: [NSImage.self], options: nil) {
                let imageExtensions: Set<String> = [
                    "png", "jpg", "jpeg", "gif", "webp", "bmp", "heic", "tiff", "svg", "ico"
                ]
                if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
                   let firstImgUrl = urls.first(where: { imageExtensions.contains($0.pathExtension.lowercased()) }),
                   let img = NSImage(contentsOf: firstImgUrl) {
                    if let tiffData = img.tiffRepresentation {
                        pb.setData(tiffData, forType: .tiff)
                        if let rep = NSBitmapImageRep(data: tiffData),
                           let pngData = rep.representation(using: .png, properties: [:]) {
                            pb.setData(pngData, forType: .png)
                        }
                    }
                }
            }

            if let terminalView {
                terminalView.triggerImagePasteShortcut()
            }
        } else {
            if let session = model.activeSession {
                _ = session.state.performBindingAction("paste_from_clipboard")
            }
        }
    }

    public func handleCopy() {
        if let terminalView = getActiveTerminalView(), terminalView.copySelectedTextToPasteboard() {
            return
        }
        if let session = model.activeSession {
            _ = session.state.performBindingAction("copy_to_clipboard")
        }
    }

    public func handleSelectAll() {
        if let session = model.activeSession {
            _ = session.state.performBindingAction("select_all")
        }
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
        if let terminalView = getActiveTerminalView() {
            window?.makeFirstResponder(terminalView)
        }
    }
}
