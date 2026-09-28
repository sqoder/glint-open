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
            SettingsView()
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

            // MARK: - 编辑菜单 (支持 ⌘C / ⌘V / ⌘A / ⌘X)
            CommandMenu("编辑") {
                Button("剪切") {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("复制") {
                    if !NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) {
                        if let active = SiqiSessionManager.shared.activeSession {
                            _ = active.state.performBindingAction("copy_to_clipboard")
                        }
                    }
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("粘贴") {
                    TerminalWindowController.shared.handlePaste()
                }
                .keyboardShortcut("v", modifiers: .command)

                Divider()

                Button("全选") {
                    if !NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) {
                        if let active = SiqiSessionManager.shared.activeSession {
                            _ = active.state.performBindingAction("select_all")
                        }
                    }
                }
                .keyboardShortcut("a", modifiers: .command)
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
