//
//  SiqiApp.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI
import AppKit

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

                Button("垂直分屏新建 (Split Right)") {
                    SiqiSessionManager.shared.splitRight()
                }
                .keyboardShortcut("d", modifiers: .command)

                Button("水平分屏新建 (Split Down)") {
                    SiqiSessionManager.shared.splitDown()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Divider()

                Button("关闭当前分屏/标签页") {
                    SiqiSessionManager.shared.closeActiveSession()
                }
                .keyboardShortcut("w", modifiers: .command)
            }

            // MARK: - 编辑菜单 (支持 ⌘C / ⌘V / ⌘A / ⌘X / ⌘F)
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

                Divider()

                Button("查找...") {
                    if let active = SiqiSessionManager.shared.activeSession {
                        _ = active.state.performBindingAction("start_search")
                    }
                }
                .keyboardShortcut("f", modifiers: .command)
            }

            // MARK: - 终端操作菜单
            CommandMenu("终端") {
                Button("清空屏幕") {
                    SiqiSessionManager.shared.clearActiveSession()
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("重启当前会话") {
                    SiqiSessionManager.shared.restartActiveSession()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("重新加载 Ghostty 配置") {
                    SiqiSessionManager.shared.reloadAllSessions()
                    TerminalWindowController.shared.updateThemeBackground()
                }
                .keyboardShortcut(",", modifiers: [.command, .shift])

                Divider()

                Button("上一个标签页") {
                    SiqiSessionManager.shared.previousTab()
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Button("下一个标签页") {
                    SiqiSessionManager.shared.nextTab()
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Divider()

                // Ghostty 快捷键：⌘1 到 ⌘9 快速切 Tab
                ForEach(1...9, id: \.self) { index in
                    Button("跳转到标签页 \(index)") {
                        SiqiSessionManager.shared.selectTab(at: index - 1)
                    }
                    .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(0x30 + index)!)), modifiers: .command)
                }
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

                Divider()

                Button("打开 Ghostty 配置文件") {
                    let ghosttyPath = NSString(string: "~/.config/ghostty/config").expandingTildeInPath
                    let siqiPath = NSString(string: "~/.config/siqi/config").expandingTildeInPath
                    let target = FileManager.default.fileExists(atPath: siqiPath) ? siqiPath : ghosttyPath
                    NSWorkspace.shared.open(URL(fileURLWithPath: target))
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
