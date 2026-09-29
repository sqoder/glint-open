//
//  SuqiWindowManager.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit
import SwiftUI

@MainActor
public final class SuqiWindowManager: ObservableObject {
    public static let shared = SuqiWindowManager()

    @Published public private(set) var windowControllers: [TerminalWindowController] = []
    private var lastWindowTopLeft: NSPoint?

    private init() {}

    /// 获取当前最前端（活跃）的终端窗口控制器
    public var activeWindowController: TerminalWindowController? {
        if let keyWindow = NSApp.keyWindow,
           let ctrl = windowControllers.first(where: { $0.window === keyWindow }) {
            return ctrl
        }
        if let mainWindow = NSApp.mainWindow,
           let ctrl = windowControllers.first(where: { $0.window === mainWindow }) {
            return ctrl
        }
        return windowControllers.last
    }

    /// 创建一个全新独立的终端窗口
    @discardableResult
    public func createWindow(workingDirectory: String? = nil) -> TerminalWindowController {
        let initialDir = workingDirectory
            ?? activeWindowController?.model.activeSession?.fullDirectory
            ?? NSHomeDirectory()

        let model = SuqiWindowModel(initialWorkingDirectory: initialDir)
        let controller = TerminalWindowController(model: model)

        // 首个窗口优先恢复用户上次调整过的大小与坐标 (window-save-state)，无历史记录时居中；
        // 后续窗口 (⌘N) 进行级联错位布局 (Cascade)，提供标准的 macOS 多窗口体验
        if windowControllers.isEmpty, let win = controller.window {
            let (cfg, _) = GhosttyUserConfig.load()
            var didRestore = false
            if cfg.windowSaveState.lowercased() != "never" {
                didRestore = win.setFrameUsingName("SuqiTerminalWindow")
            }
            if !didRestore {
                win.center()
            }
            lastWindowTopLeft = win.frame.origin
            lastWindowTopLeft?.y += win.frame.height
        } else if let lastPoint = lastWindowTopLeft, let win = controller.window {
            let nextPoint = win.cascadeTopLeft(from: lastPoint)
            win.setFrameTopLeftPoint(nextPoint)
            lastWindowTopLeft = nextPoint
        } else if let win = controller.window {
            win.center()
            lastWindowTopLeft = win.frame.origin
            lastWindowTopLeft?.y += win.frame.height
        }

        windowControllers.append(controller)
        controller.showWindow()
        return controller
    }

    /// 移除已关闭的窗口控制器
    public func removeWindow(_ controller: TerminalWindowController) {
        windowControllers.removeAll { $0 === controller }
        if windowControllers.isEmpty {
            lastWindowTopLeft = nil
        }
    }

    /// 重新加载所有窗口的主题与背景
    public func updateAllThemeBackgrounds() {
        for controller in windowControllers {
            controller.updateThemeBackground()
        }
    }

    /// 重载所有窗口中的终端配置与会话
    public func reloadAllWindows() {
        for controller in windowControllers {
            controller.model.reloadAllSessions()
            controller.updateThemeBackground()
        }
    }
}
