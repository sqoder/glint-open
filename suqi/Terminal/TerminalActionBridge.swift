//
//  TerminalActionBridge.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit
import GhosttyTerminal

@MainActor
public enum TerminalActionBridge {
    public static func findTerminalView(in view: NSView) -> AppTerminalView? {
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

    public static func getActiveTerminalView(for window: NSWindow?) -> AppTerminalView? {
        guard let window else { return nil }
        if let tv = window.firstResponder as? AppTerminalView {
            return tv
        }
        if let contentView = window.contentView, let tv = findTerminalView(in: contentView) {
            return tv
        }
        return nil
    }

    public static func isTextInputFocused(in window: NSWindow?) -> Bool {
        guard let window, let responder = window.firstResponder else { return false }
        if responder is NSText || responder is NSTextField || responder is NSSearchField {
            if responder is AppTerminalView { return false }
            return true
        }
        return false
    }

    public static func pasteboardContainsImage(_ pb: NSPasteboard) -> Bool {
        let imageExtensions: Set<String> = [
            "png", "jpg", "jpeg", "gif", "webp", "bmp", "heic", "tiff", "svg", "ico"
        ]

        // 1. 优先检查是否有文件 URL
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            return urls.contains { url in
                imageExtensions.contains(url.pathExtension.lowercased())
            }
        }

        // 2. 无文件 URL 时，检查是否包含纯内存图片数据 (如系统截屏、浏览器复制图片等)
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

    public static func handlePaste(in window: NSWindow?, model: SuqiWindowModel) {
        guard let window else { return }
        let terminalView = getActiveTerminalView(for: window)

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
            // 检查剪贴板是否复制了 Finder 普通文件，若有则贴入转义文件路径
            if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
                let paths = urls.map { $0.path.replacingOccurrences(of: " ", with: "\\ ") }
                let text = paths.joined(separator: " ") + " "
                model.activeSession?.send(text)
                return
            }

            if let session = model.activeSession {
                _ = session.state.performBindingAction("paste_from_clipboard")
            }
        }
    }

    public static func handleCopy(in window: NSWindow?, model: SuqiWindowModel) {
        if let terminalView = getActiveTerminalView(for: window), terminalView.copySelectedTextToPasteboard() {
            return
        }
        if let session = model.activeSession {
            _ = session.state.performBindingAction("copy_to_clipboard")
        }
    }

    public static func handleSelectAll(model: SuqiWindowModel) {
        if let session = model.activeSession {
            _ = session.state.performBindingAction("select_all")
        }
    }

    /// 统一按键分发器：处理普通窗口和 Quick Terminal 的所有核心快捷键
    public static func dispatchKeyEvent(
        event: NSEvent,
        window: NSWindow,
        model: SuqiWindowModel,
        onCloseRequested: @escaping () -> Void
    ) -> NSEvent? {
        let isRelevant = window.isKeyWindow || window.isMainWindow || event.window === window
        guard isRelevant else { return event }

        let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])

        // 若当前输入光标正在 ⌘F 搜索框等原生输入框中，放行 ⌘C / ⌘V / ⌘A / ⌘X，不抢占焦点！
        if isTextInputFocused(in: window) {
            // Esc: 关闭搜索框并将焦点还给终端
            if event.keyCode == 53 && model.isSearching {
                model.isSearching = false
                if let tv = getActiveTerminalView(for: window) {
                    window.makeFirstResponder(tv)
                }
                return nil
            }
            if flags == .command {
                let char = event.charactersIgnoringModifiers?.lowercased()
                if char == "c" || char == "v" || char == "a" || char == "x" {
                    return event // 放行原生编辑行为
                }
                if char == "f" {
                    model.isSearching = false
                    if let tv = getActiveTerminalView(for: window) {
                        window.makeFirstResponder(tv)
                    }
                    return nil
                }
            }
        }

        // 1. 处理 ⌘V (智能粘贴图片或文本)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "v" {
            handlePaste(in: window, model: model)
            return nil
        }

        // 2. 处理 ⌘C (复制选中文本)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "c" {
            handleCopy(in: window, model: model)
            return nil
        }

        // 3. 处理 ⌘A (全选)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "a" {
            handleSelectAll(model: model)
            return nil
        }

        // 4. 处理 ⌘N (新建独立窗口)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "n" {
            SuqiWindowManager.shared.createWindow(workingDirectory: model.activeSession?.fullDirectory)
            return nil
        }

        // 5. 处理 ⌘T (新建标签页)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "t" {
            model.createNewTab()
            return nil
        }

        // 6. 处理 ⌘D (垂直分屏 Split Right)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "d" {
            model.splitRight()
            return nil
        }

        // 7. 处理 ⌘Shift+D (水平分屏 Split Down)
        if flags == [.command, .shift] && event.charactersIgnoringModifiers?.lowercased() == "d" {
            model.splitDown()
            return nil
        }

        // 8. 处理 ⌃⌘= (均等所有分屏 Equalize Splits)
        if flags == [.control, .command] && (event.charactersIgnoringModifiers == "=" || event.charactersIgnoringModifiers == "+") {
            model.equalizeSplits()
            return nil
        }

        // 9. 处理 ⌘Shift+Enter (分屏最大化聚焦 Toggle Split Zoom)
        if flags == [.command, .shift] && (event.keyCode == 36 || event.charactersIgnoringModifiers == "\r") {
            model.toggleZoom()
            return nil
        }

        // 10. 处理 ⌃⌘H / ⌃⌘J / ⌃⌘K / ⌃⌘L 以及 ⌃⌘方向键 (空间几何方向分屏聚焦)
        if flags == [.control, .command] {
            let char = event.charactersIgnoringModifiers?.lowercased()
            if char == "h" || event.specialKey == .leftArrow {
                model.focusPane(in: .left)
                return nil
            }
            if char == "l" || event.specialKey == .rightArrow {
                model.focusPane(in: .right)
                return nil
            }
            if char == "k" || event.specialKey == .upArrow {
                model.focusPane(in: .up)
                return nil
            }
            if char == "j" || event.specialKey == .downArrow {
                model.focusPane(in: .down)
                return nil
            }
        }

        // 11. 处理 ⌘F (终端回滚内容原生查找)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "f" {
            model.isSearching.toggle()
            return nil
        }

        // 12. 处理 ⌥⌘Left / ⌥⌘Right (分屏切换)
        if flags == [.command, .option] {
            if event.specialKey == .leftArrow || event.specialKey == .upArrow {
                model.previousPane()
                return nil
            }
            if event.specialKey == .rightArrow || event.specialKey == .downArrow {
                model.nextPane()
                return nil
            }
        }

        // 13. 处理 ⌘W (优先关闭当前分屏或当前 Tab；若全关则请求关闭)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "w" {
            model.closeActiveSession()
            return nil
        }

        // 14. 处理 ⌘Shift+W (直接关闭整个窗口)
        if flags == [.command, .shift] && event.charactersIgnoringModifiers?.lowercased() == "w" {
            onCloseRequested()
            return nil
        }

        // 15. 处理 ⌘1 .. ⌘9 (切换标签页)
        if flags == .command, let char = event.charactersIgnoringModifiers?.first, char >= "1" && char <= "9" {
            if let tabIndex = Int(String(char)) {
                model.selectTab(at: tabIndex - 1)
                return nil
            }
        }

        // 16. 处理 ⌘[ / ⌘] (标签页前后切换)
        if flags == .command && event.charactersIgnoringModifiers == "[" {
            model.previousTab()
            return nil
        }
        if flags == .command && event.charactersIgnoringModifiers == "]" {
            model.nextTab()
            return nil
        }

        // 17. 处理 ⌘Shift+[ / ⌘Shift+] (标签页前后切换变体)
        if flags == [.command, .shift] {
            if event.charactersIgnoringModifiers == "{" || event.charactersIgnoringModifiers == "[" {
                model.previousTab()
                return nil
            }
            if event.charactersIgnoringModifiers == "}" || event.charactersIgnoringModifiers == "]" {
                model.nextTab()
                return nil
            }
        }

        // 18. 处理 ⌘K (清屏)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "k" {
            model.clearActiveSession()
            return nil
        }

        // 19. 处理 ⌘+ / ⌘= / ⌘- / ⌘0 (Ghostty 字号动态缩放)
        if flags == .command || flags == [.command, .shift] {
            let char = event.charactersIgnoringModifiers
            if char == "=" || char == "+" {
                _ = model.activeSession?.state.performBindingAction("increase_font_size:1")
                return nil
            } else if char == "-" {
                _ = model.activeSession?.state.performBindingAction("decrease_font_size:1")
                return nil
            } else if char == "0" {
                _ = model.activeSession?.state.performBindingAction("reset_font_size")
                return nil
            }
        }

        // 20. 处理 ⌘, (打开配置文件)
        if flags == .command && event.charactersIgnoringModifiers == "," {
            let (_, path) = GhosttyUserConfig.load()
            let target = path ?? NSString(string: "~/.config/ghostty/config").expandingTildeInPath
            NSWorkspace.shared.open(URL(fileURLWithPath: target))
            return nil
        }

        // 21. 处理 ⌘Shift+, (重载配置)
        if flags == [.command, .shift] && (event.charactersIgnoringModifiers == "<" || event.charactersIgnoringModifiers == ",") {
            SuqiWindowManager.shared.reloadAllWindows()
            return nil
        }

        return event
    }
}
