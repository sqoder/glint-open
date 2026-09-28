//
//  WindowDragArea.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit

/// 原生 AppKit 窗口拖拽响应视图
/// 允许用户在顶部无边框栏区域通过鼠标左键拖拽平滑移动窗口，
/// 双击可触发 macOS 系统的窗口缩放（最大化/还原）或最小化行为。
public final class WindowDragHandleView: NSView {
    public override var mouseDownCanMoveWindow: Bool {
        true
    }

    public override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            let action = UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick")
            if action == "Minimize" {
                window?.miniaturize(nil)
                return
            } else if action != "None" {
                window?.zoom(nil)
                return
            }
        }
        window?.performDrag(with: event)
    }
}

public struct WindowDragArea: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> WindowDragHandleView {
        let view = WindowDragHandleView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    public func updateNSView(_ nsView: WindowDragHandleView, context: Context) {}
}
