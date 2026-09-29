//
//  WindowDragArea.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit

/// Native AppKit window drag handle view
/// Enables smooth dragging from the top bar area to move the window,
/// and double-clicking triggers macOS window zoom (maximize/restore) or minimize.
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
