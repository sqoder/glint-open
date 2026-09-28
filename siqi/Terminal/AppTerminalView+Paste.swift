//
//  AppTerminalView+Paste.swift
//  siqi
//
//  Created for siqi Terminal.
//

import AppKit
import GhosttyTerminal

// MARK: - AppTerminalView Image Paste Extension

extension AppTerminalView {
    /// 触发与用户在物理键盘上按下 Control+V 完全一致的终端按键事件。
    ///
    /// 现代 AI 终端 CLI（如 agy / Claude Code / Codex / OpenCode 等）在接收到 Control+V 时，
    /// 会主动调用 macOS 原生剪贴板 API 读取图片并生成上传附件。
    public func triggerImagePasteShortcut() {
        let timestamp = ProcessInfo.processInfo.systemUptime
        let windowNum = window?.windowNumber ?? 0

        guard let downEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: .control,
            timestamp: timestamp,
            windowNumber: windowNum,
            context: nil,
            characters: "\u{16}",
            charactersIgnoringModifiers: "v",
            isARepeat: false,
            keyCode: 0x09
        ) else { return }

        guard let upEvent = NSEvent.keyEvent(
            with: .keyUp,
            location: .zero,
            modifierFlags: .control,
            timestamp: timestamp + 0.005,
            windowNumber: windowNum,
            context: nil,
            characters: "\u{16}",
            charactersIgnoringModifiers: "v",
            isARepeat: false,
            keyCode: 0x09
        ) else { return }

        self.keyDown(with: downEvent)
        self.keyUp(with: upEvent)
    }
}
