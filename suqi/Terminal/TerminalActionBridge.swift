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

        // 1. Check for file URLs first
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            return urls.contains { url in
                imageExtensions.contains(url.pathExtension.lowercased())
            }
        }

        // 2. Check for in-memory image data (e.g., screenshots, web browser copies)
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
            // Populate TIFF and PNG pasteboard representations if copied from Finder
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
            // Check if ordinary Finder files were copied; paste escaped file paths
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

    /// Unified key event dispatcher handling all core keyboard shortcuts
    public static func dispatchKeyEvent(
        event: NSEvent,
        window: NSWindow,
        model: SuqiWindowModel,
        onCloseRequested: @escaping () -> Void
    ) -> NSEvent? {
        let isRelevant = window.isKeyWindow || window.isMainWindow || event.window === window
        guard isRelevant else { return event }

        let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])

        // When text input cursor is inside a native text field (such as ⌘F search bar), pass ⌘C / ⌘V / ⌘A / ⌘X through
        if isTextInputFocused(in: window) {
            // Esc: close search bar and return focus to terminal
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
                    return event // Allow native text editing behavior
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

        // 1. ⌘V (Smart image or text paste)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "v" {
            handlePaste(in: window, model: model)
            return nil
        }

        // 2. ⌘C (Copy selected text)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "c" {
            handleCopy(in: window, model: model)
            return nil
        }

        // 3. ⌘A (Select all)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "a" {
            handleSelectAll(model: model)
            return nil
        }

        // 4. ⌘N (New standalone window)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "n" {
            SuqiWindowManager.shared.createWindow(workingDirectory: model.activeSession?.fullDirectory)
            return nil
        }

        // 5. ⌘T (New tab)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "t" {
            model.createNewTab()
            return nil
        }

        // 6. ⌘D (Split Right)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "d" {
            model.splitRight()
            return nil
        }

        // 7. ⌘Shift+D (Split Down)
        if flags == [.command, .shift] && event.charactersIgnoringModifiers?.lowercased() == "d" {
            model.splitDown()
            return nil
        }

        // 8. ⌃⌘= (Equalize Splits)
        if flags == [.control, .command] && (event.charactersIgnoringModifiers == "=" || event.charactersIgnoringModifiers == "+") {
            model.equalizeSplits()
            return nil
        }

        // 9. ⌘Shift+Enter (Toggle Split Zoom)
        if flags == [.command, .shift] && (event.keyCode == 36 || event.charactersIgnoringModifiers == "\r") {
            model.toggleZoom()
            return nil
        }

        // 10. ⌃⌘H / ⌃⌘J / ⌃⌘K / ⌃⌘L and ⌃⌘ Arrow keys (Directional pane navigation)
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

        // 11. ⌘F (Scrollback search)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "f" {
            model.isSearching.toggle()
            return nil
        }

        // 12. ⌥⌘Left / ⌥⌘Right (Pane navigation)
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

        // 13. ⌘W (Close active pane / tab / window)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "w" {
            model.closeActiveSession()
            return nil
        }

        // 14. ⌘Shift+W (Close entire window)
        if flags == [.command, .shift] && event.charactersIgnoringModifiers?.lowercased() == "w" {
            onCloseRequested()
            return nil
        }

        // 15. ⌘1 .. ⌘9 (Switch to tab)
        if flags == .command, let char = event.charactersIgnoringModifiers?.first, char >= "1" && char <= "9" {
            if let tabIndex = Int(String(char)) {
                model.selectTab(at: tabIndex - 1)
                return nil
            }
        }

        // 16. ⌘[ / ⌘] (Previous / Next tab)
        if flags == .command && event.charactersIgnoringModifiers == "[" {
            model.previousTab()
            return nil
        }
        if flags == .command && event.charactersIgnoringModifiers == "]" {
            model.nextTab()
            return nil
        }

        // 17. ⌘Shift+[ / ⌘Shift+] (Previous / Next tab variant)
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

        // 18. ⌘K (Clear scrollback)
        if flags == .command && event.charactersIgnoringModifiers?.lowercased() == "k" {
            model.clearActiveSession()
            return nil
        }

        // 19. ⌘+ / ⌘= / ⌘- / ⌘0 (Dynamic font size scaling)
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

        // 20. ⌘, (Open configuration file)
        if flags == .command && event.charactersIgnoringModifiers == "," {
            let (_, path) = GhosttyUserConfig.load()
            let target = path ?? NSString(string: "~/.config/ghostty/config").expandingTildeInPath
            NSWorkspace.shared.open(URL(fileURLWithPath: target))
            return nil
        }

        // 21. ⌘Shift+, (Reload configuration)
        if flags == [.command, .shift] && (event.charactersIgnoringModifiers == "<" || event.charactersIgnoringModifiers == ",") {
            SuqiWindowManager.shared.reloadAllWindows()
            return nil
        }

        return event
    }
}
