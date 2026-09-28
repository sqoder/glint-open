//
//  AppTerminalView+SmoothResize.swift
//  suqi
//
//  Created for suqi Terminal.
//

import AppKit
import GhosttyTerminal

extension AppTerminalView {
    private static var originalSetFrameSizeIMP: IMP?

    /// 对齐 Ghostty 官方 macOS 原生渲染流水线：
    /// 1. 彻底跳过 libghostty-spm 中的 capturePresentationFrame 截图图层黑魔法与 4 帧强制同步阻塞渲染
    /// 2. 贯彻 Ghostty 官方 IOSurfaceLayer 的 contentsGravity = .topLeft 原生机制，杜绝 Core Animation 在实时拉伸时拉扯形变终端网格
    /// 3. 设置 layerContentsRedrawPolicy = .never，阻止 AppKit 在 Live Resize 期间清空或重绘图层
    /// 4. 纯净调用 fitToSize()，与 Ghostty 官方的 sizeDidChange 流水线完全对齐
    public static let enableSmoothResizePipeline: Void = {
        guard let method = class_getInstanceMethod(AppTerminalView.self, #selector(NSView.setFrameSize(_:))) else {
            return
        }

        guard let superMethod = class_getInstanceMethod(NSView.self, #selector(NSView.setFrameSize(_:))) else {
            return
        }

        originalSetFrameSizeIMP = method_getImplementation(superMethod)

        let swizzledBlock: @convention(block) (AnyObject, NSSize) -> Void = { target, newSize in
            guard let view = target as? AppTerminalView else { return }

            let sizeChanged = (newSize.width != view.frame.size.width || newSize.height != view.frame.size.height)

            // 1. 调用 NSView 原生底层 setFrameSize
            if let originalIMP = AppTerminalView.originalSetFrameSizeIMP {
                typealias Fn = @convention(c) (AnyObject, Selector, NSSize) -> Void
                let fn = unsafeBitCast(originalIMP, to: Fn.self)
                fn(view, #selector(NSView.setFrameSize(_:)), newSize)
            }

            // 2. 严格对齐 Ghostty 官方设计：锚定 top-left，防止缩放帧间隔内的位图拉伸变形
            view.layer?.contentsGravity = .topLeft
            if let sublayers = view.layer?.sublayers {
                for sub in sublayers {
                    sub.contentsGravity = .topLeft
                }
            }
            view.layerContentsRedrawPolicy = .never

            // 3. 尺寸变更时，直接通知 Ghostty 核心同步最新尺寸并安排下一帧 DisplayLink 刷新
            if sizeChanged {
                view.fitToSize()
            }
        }

        let swizzledIMP = imp_implementationWithBlock(swizzledBlock)
        method_setImplementation(method, swizzledIMP)
    }()
}
