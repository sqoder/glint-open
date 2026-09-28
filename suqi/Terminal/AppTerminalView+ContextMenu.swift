//
//  AppTerminalView+ContextMenu.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit
import GhosttyTerminal

@MainActor
public final class TerminalContextMenuBridge: NSObject {
    public static let shared = TerminalContextMenuBridge()

    private weak var currentTerminalView: AppTerminalView?

    public func buildMenu(for view: AppTerminalView) -> NSMenu {
        self.currentTerminalView = view
        let menu = NSMenu(title: "Terminal Context")

        // 1. Copy
        let copyItem = NSMenuItem(title: "Copy", action: #selector(menuCopy), keyEquivalent: "")
        copyItem.target = self
        menu.addItem(copyItem)

        // 2. Paste
        let pasteItem = NSMenuItem(title: "Paste", action: #selector(menuPaste), keyEquivalent: "")
        pasteItem.target = self
        menu.addItem(pasteItem)

        // 3. Select All
        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(menuSelectAll), keyEquivalent: "")
        selectAllItem.target = self
        menu.addItem(selectAllItem)

        menu.addItem(NSMenuItem.separator())

        // 4. Split Right
        let splitRightItem = NSMenuItem(title: "Split Right", action: #selector(menuSplitRight), keyEquivalent: "")
        splitRightItem.target = self
        menu.addItem(splitRightItem)

        // 5. Split Down
        let splitDownItem = NSMenuItem(title: "Split Down", action: #selector(menuSplitDown), keyEquivalent: "")
        splitDownItem.target = self
        menu.addItem(splitDownItem)

        // Equalize Splits
        let equalizeItem = NSMenuItem(title: "Equalize Splits", action: #selector(menuEqualizeSplits), keyEquivalent: "")
        equalizeItem.target = self
        menu.addItem(equalizeItem)

        // Toggle Split Zoom
        let zoomItem = NSMenuItem(title: "Toggle Split Zoom", action: #selector(menuToggleZoom), keyEquivalent: "")
        zoomItem.target = self
        menu.addItem(zoomItem)

        menu.addItem(NSMenuItem.separator())

        // Find...
        let findItem = NSMenuItem(title: "Find...", action: #selector(menuFind), keyEquivalent: "")
        findItem.target = self
        menu.addItem(findItem)

        menu.addItem(NSMenuItem.separator())

        // 6. Clear Screen
        let clearItem = NSMenuItem(title: "Clear Screen", action: #selector(menuClear), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        // 7. New Tab
        let newTabItem = NSMenuItem(title: "New Tab", action: #selector(menuNewTab), keyEquivalent: "")
        newTabItem.target = self
        menu.addItem(newTabItem)

        // 8. New Window
        let newWindowItem = NSMenuItem(title: "New Window", action: #selector(menuNewWindow), keyEquivalent: "")
        newWindowItem.target = self
        menu.addItem(newWindowItem)

        menu.addItem(NSMenuItem.separator())

        // 9. Close Pane
        let closeItem = NSMenuItem(title: "Close Pane", action: #selector(menuClosePane), keyEquivalent: "")
        closeItem.target = self
        menu.addItem(closeItem)

        return menu
    }

    @objc private func menuCopy() {
        if let tv = currentTerminalView, tv.copySelectedTextToPasteboard() {
            // Copied
        } else {
            SuqiWindowManager.shared.activeWindowController?.handleCopy()
        }
    }

    @objc private func menuPaste() {
        SuqiWindowManager.shared.activeWindowController?.handlePaste()
    }

    @objc private func menuSelectAll() {
        _ = SuqiWindowManager.shared.activeWindowController?.model.activeSession?.state.performBindingAction("select_all")
    }

    @objc private func menuSplitRight() {
        SuqiWindowManager.shared.activeWindowController?.model.splitRight()
    }

    @objc private func menuSplitDown() {
        SuqiWindowManager.shared.activeWindowController?.model.splitDown()
    }

    @objc private func menuEqualizeSplits() {
        SuqiWindowManager.shared.activeWindowController?.model.equalizeSplits()
    }

    @objc private func menuToggleZoom() {
        SuqiWindowManager.shared.activeWindowController?.model.toggleZoom()
    }

    @objc private func menuFind() {
        if let model = SuqiWindowManager.shared.activeWindowController?.model {
            model.isSearching = true
        }
    }

    @objc private func menuClear() {
        SuqiWindowManager.shared.activeWindowController?.model.clearActiveSession()
    }

    @objc private func menuNewTab() {
        SuqiWindowManager.shared.activeWindowController?.model.createNewTab()
    }

    @objc private func menuNewWindow() {
        SuqiWindowManager.shared.createWindow()
    }

    @objc private func menuClosePane() {
        SuqiWindowManager.shared.activeWindowController?.closeCurrentTabOrWindow()
    }
}

extension AppTerminalView {
    /// 激活原生 Ghostty 右键上下文菜单流水线
    public static let enableContextMenuPipeline: Void = {
        // 1. Swizzle rightMouseDown
        if let originalMethod = class_getInstanceMethod(AppTerminalView.self, #selector(NSResponder.rightMouseDown(with:))) {
            let block: @convention(block) (AnyObject, NSEvent) -> Void = { target, event in
                guard let view = target as? AppTerminalView else { return }
                view.window?.makeFirstResponder(view)
                let menu = TerminalContextMenuBridge.shared.buildMenu(for: view)
                NSMenu.popUpContextMenu(menu, with: event, for: view)
            }
            let swizzledIMP = imp_implementationWithBlock(block)
            method_setImplementation(originalMethod, swizzledIMP)
        }

        // 2. Swizzle menu(for:)
        if let menuMethod = class_getInstanceMethod(AppTerminalView.self, #selector(NSView.menu(for:))) {
            let menuBlock: @convention(block) (AnyObject, NSEvent) -> NSMenu? = { target, event in
                guard let view = target as? AppTerminalView else { return nil }
                return TerminalContextMenuBridge.shared.buildMenu(for: view)
            }
            let swizzledIMP = imp_implementationWithBlock(menuBlock)
            method_setImplementation(menuMethod, swizzledIMP)
        }
    }()
}
