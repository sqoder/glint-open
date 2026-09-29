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
        guard let win = controller.window else {
            windowControllers.append(controller)
            controller.showWindow()
            return controller
        }

        let (cfg, _) = GhosttyUserConfig.load()
        let shouldSaveState = cfg.windowSaveState.lowercased() != "never"

        if windowControllers.isEmpty {
            // 首个窗口：优先从 window-save-state 恢复保存的尺寸与位置；无记录时居中
            var didRestore = false
            if shouldSaveState {
                didRestore = win.setFrameUsingName("SuqiTerminalWindow")
            }
            if !didRestore {
                win.center()
            }
            lastWindowTopLeft = win.frame.origin
            lastWindowTopLeft?.y += win.frame.height
        } else {
            // 后续新建窗口 (⌘N)：继承当前活跃窗口的尺寸，并级联 (Cascade) 错位布局，完全对齐 Ghostty / macOS 原生行为
            if let activeWin = activeWindowController?.window {
                var newFrame = win.frame
                newFrame.size = activeWin.frame.size
                win.setFrame(newFrame, display: false)
            }

            let refPoint = lastWindowTopLeft
                ?? activeWindowController?.window?.frame.origin.applying(.init(translationX: 0, y: activeWindowController?.window?.frame.height ?? 0))
                ?? win.frame.origin
            let nextPoint = win.cascadeTopLeft(from: refPoint)
            win.setFrameTopLeftPoint(nextPoint)
            lastWindowTopLeft = nextPoint
        }

        windowControllers.append(controller)
        controller.showWindow()

        // 窗口展示后同步记录
        if shouldSaveState {
            controller.saveWindowFrameIfNeeded()
        }

        return controller
    }

    /// 移除已关闭的窗口控制器
    public func removeWindow(_ controller: TerminalWindowController) {
        controller.saveWindowFrameIfNeeded()
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
