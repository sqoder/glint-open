//
//  AppTerminalView+IME.swift
//  siqi
//
//  Created for siqi Terminal.
//

import AppKit
import GhosttyTerminal

// MARK: - AppTerminalView IME Window Level Extension

extension AppTerminalView {
    /// 告知系统输入法（如 macOS 原生中文拼音、搜狗输入法等）当前输入视图所在窗口的层级。
    /// AppTerminalView 默认未实现 NSTextInputClient.windowLevel()，
    /// WindowServer 默认兜底层级为 0（NSNormalWindowLevel），
    /// 显式实现该方法后，系统会自动将输入法候选窗准确提升到当前终端窗口之上。
    @objc open func windowLevel() -> Int {
        if let window {
            return Int(window.level.rawValue)
        }
        return Int(NSWindow.Level.normal.rawValue)
    }
}
