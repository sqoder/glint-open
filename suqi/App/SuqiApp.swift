//
//  SuqiApp.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit

@main
struct SuqiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
        .commands {
            // MARK: - 文件菜单
            CommandGroup(replacing: .newItem) {
                Button("新建窗口") {
                    SuqiWindowManager.shared.createWindow()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("新建标签页") {
                    SuqiWindowManager.shared.activeWindowController?.model.createNewTab()
                }
                .keyboardShortcut("t", modifiers: .command)

                Divider()

                Button("垂直分屏新建 (Split Right)") {
                    SuqiWindowManager.shared.activeWindowController?.model.splitRight()
                }
                .keyboardShortcut("d", modifiers: .command)

                Button("水平分屏新建 (Split Down)") {
                    SuqiWindowManager.shared.activeWindowController?.model.splitDown()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])

                Button("分屏最大化聚焦 (Toggle Split Zoom)") {
                    SuqiWindowManager.shared.activeWindowController?.model.toggleZoom()
                }
                .keyboardShortcut(.return, modifiers: [.command, .shift])

                Button("均等所有分屏 (Equalize Splits)") {
                    SuqiWindowManager.shared.activeWindowController?.model.equalizeSplits()
                }
                .keyboardShortcut("=", modifiers: [.command, .control])

                Divider()

                Button("关闭分屏 / 标签页") {
                    SuqiWindowManager.shared.activeWindowController?.closeCurrentTabOrWindow()
                }
                .keyboardShortcut("w", modifiers: .command)

                Button("关闭当前窗口") {
                    SuqiWindowManager.shared.activeWindowController?.closeWindow()
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }

            // MARK: - 编辑菜单 (支持 ⌘C / ⌘V / ⌘A / ⌘X / ⌘F)
            CommandMenu("编辑") {
                Button("剪切") {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("复制") {
                    if !NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) {
                        SuqiWindowManager.shared.activeWindowController?.handleCopy()
                    }
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("粘贴") {
                    SuqiWindowManager.shared.activeWindowController?.handlePaste()
                }
                .keyboardShortcut("v", modifiers: .command)

                Divider()

                Button("全选") {
                    if !NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) {
                        SuqiWindowManager.shared.activeWindowController?.handleSelectAll()
                    }
                }
                .keyboardShortcut("a", modifiers: .command)

                Divider()

                Button("查找...") {
                    SuqiWindowManager.shared.activeWindowController?.model.isSearching.toggle()
                }
                .keyboardShortcut("f", modifiers: .command)
            }

            // MARK: - 终端操作菜单
            CommandMenu("终端") {
                Button("随叫随到下拉终端 (Quick Terminal)") {
                    QuickTerminalController.shared.toggle()
                }
                .keyboardShortcut("`", modifiers: .control)

                Divider()

                Button("清空屏幕") {
                    SuqiWindowManager.shared.activeWindowController?.model.clearActiveSession()
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("重启当前会话") {
                    SuqiWindowManager.shared.activeWindowController?.model.restartActiveSession()
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("重新加载 Ghostty / suqi 配置") {
                    SuqiWindowManager.shared.reloadAllWindows()
                }
                .keyboardShortcut(",", modifiers: [.command, .shift])

                Divider()

                Button("上一个标签页") {
                    SuqiWindowManager.shared.activeWindowController?.model.previousTab()
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])

                Button("下一个标签页") {
                    SuqiWindowManager.shared.activeWindowController?.model.nextTab()
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                Divider()

                // Ghostty 快捷键：⌘1 到 ⌘9 快速切 Tab
                ForEach(1...9, id: \.self) { index in
                    Button("跳转到标签页 \(index)") {
                        SuqiWindowManager.shared.activeWindowController?.model.selectTab(at: index - 1)
                    }
                    .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(0x30 + index)!)), modifiers: .command)
                }
            }

            // MARK: - 视图与字号缩放
            CommandMenu("视图") {
                Button("放大字号") {
                    _ = SuqiWindowManager.shared.activeWindowController?.model.activeSession?.state.performBindingAction("increase_font_size:1")
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("缩小字号") {
                    _ = SuqiWindowManager.shared.activeWindowController?.model.activeSession?.state.performBindingAction("decrease_font_size:1")
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("恢复默认字号") {
                    _ = SuqiWindowManager.shared.activeWindowController?.model.activeSession?.state.performBindingAction("reset_font_size")
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()

                Button("打开 Ghostty / suqi 配置文件") {
                    let ghosttyPath = NSString(string: "~/.config/ghostty/config").expandingTildeInPath
                    let suqiPath = NSString(string: "~/.config/suqi/config").expandingTildeInPath
                    let target = FileManager.default.fileExists(atPath: suqiPath) ? suqiPath : ghosttyPath
                    NSWorkspace.shared.open(URL(fileURLWithPath: target))
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
