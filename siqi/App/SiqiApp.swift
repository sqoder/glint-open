//
//  SiqiApp.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI

@main
struct SiqiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsPopoverView()
        }
        .commands {
            // MARK: - 文件菜单
            CommandGroup(replacing: .newItem) {
                Button("新建标签页") {
                    SiqiSessionManager.shared.createNewSession()
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("新建窗口") {
                    TerminalWindowController.shared.showWindow()
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("关闭标签页") {
                    SiqiSessionManager.shared.closeActiveSession()
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            // MARK: - 终端操作菜单
            CommandMenu("终端") {
                Button("清空屏幕") {
                    SiqiSessionManager.shared.clearActiveSession()
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("重启会话") {
                    SiqiSessionManager.shared.restartActiveSession()
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("上一个标签页") {
                    SiqiSessionManager.shared.previousTab()
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Button("下一个标签页") {
                    SiqiSessionManager.shared.nextTab()
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])
            }

            // MARK: - 视图与字号缩放
            CommandMenu("视图") {
                Button("放大字号") {
                    SiqiSettings.shared.increaseFontSize()
                    SiqiSessionManager.shared.restartActiveSession()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("缩小字号") {
                    SiqiSettings.shared.decreaseFontSize()
                    SiqiSessionManager.shared.restartActiveSession()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("恢复默认字号") {
                    SiqiSettings.shared.resetFontSize()
                    SiqiSessionManager.shared.restartActiveSession()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}
