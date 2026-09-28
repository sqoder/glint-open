//
//  ContentView.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit

public struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    public init(material: NSVisualEffectView.Material = .underWindowBackground, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

public struct ContentView: View {
    @ObservedObject public var model: SuqiWindowModel
    @ObservedObject private var settings = SuqiSettings.shared

    public init(model: SuqiWindowModel) {
        self.model = model
    }

    private var userConfig: GhosttyUserConfig {
        GhosttyUserConfig.load().config
    }

    private var isTranslucent: Bool {
        userConfig.backgroundOpacity < 1.0 || userConfig.backgroundBlur > 0
    }

    private var themeBg: Color {
        SuqiTheme.backgroundColor(for: userConfig.themeName)
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // 背景底衬：根据 Ghostty 配置自适应纯色或毛玻璃模糊
            if isTranslucent {
                VisualEffectBackground()
                    .ignoresSafeArea()
                themeBg.opacity(userConfig.backgroundOpacity)
                    .ignoresSafeArea()
            } else {
                themeBg
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // 顶部标题/标签栏区域（高度 28）：底层承载原生可拖拽/双击缩放交互，上层渲染标签页
                ZStack(alignment: .center) {
                    WindowDragArea()
                        .frame(height: 28)

                    if model.tabs.count > 1 {
                        GhosttyTabBar(model: model)
                            .frame(height: 28)
                    } else if let activeTab = model.activeTab {
                        VStack(spacing: 1) {
                            Text(activeTab.displayPathFormatted)
                                .font(.system(size: 11.5, weight: .regular, design: .default))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineLimit(1)
                            Text("···")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.40))
                        }
                        .frame(maxWidth: .infinity, maxHeight: 28)
                        .allowsHitTesting(false)
                    }
                }
                .frame(height: 28)

                // 终端渲染工作区（全幅贴合，支持多标签与多分屏分格）
                if let activeTab = model.activeTab {
                    ActiveTabView(tab: activeTab, model: model)
                        .id(activeTab.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.clear
                }
            }
        }
        .frame(minWidth: 480, minHeight: 280)
        .ignoresSafeArea()
        .transaction { $0.animation = nil }
        // 支持将 Finder 文件直接拖拽至终端窗口自动填入转义路径
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let path = url?.path {
                        let escaped = path.replacingOccurrences(of: " ", with: "\\ ")
                        DispatchQueue.main.async {
                            model.activeSession?.send(escaped + " ")
                        }
                    }
                }
            }
            return true
        }
    }
}

public struct ActiveTabView: View {
    @ObservedObject var tab: SuqiTab
    let model: SuqiWindowModel

    public init(tab: SuqiTab, model: SuqiWindowModel) {
        self.tab = tab
        self.model = model
    }

    public var body: some View {
        PaneContainerView(node: tab.rootPane, model: model)
            .id("\(tab.id)-\(tab.paneVersion)")
    }
}

public struct PaneContainerView: View {
    let node: PaneNode
    let model: SuqiWindowModel

    public init(node: PaneNode, model: SuqiWindowModel) {
        self.node = node
        self.model = model
    }

    public var body: some View {
        switch node {
        case .terminal(let session):
            SuqiTerminalView(session: session, model: model)
                .id(session.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .split(let splitId, let axis, let fraction, let first, let second):
            GeometryReader { proxy in
                let size = proxy.size
                if size.width > 20 && size.height > 20 {
                    if axis == .horizontal {
                        let availableWidth = max(0, size.width - 1)
                        let firstWidth = availableWidth * fraction
                        let secondWidth = max(0, availableWidth - firstWidth)

                        HStack(spacing: 0) {
                            PaneContainerView(node: first, model: model)
                                .frame(width: firstWidth, height: size.height)

                            SplitDividerView(
                                axis: .horizontal,
                                splitId: splitId,
                                currentFraction: fraction,
                                availableLength: availableWidth,
                                model: model
                            )
                            .frame(width: 1, height: size.height)

                            PaneContainerView(node: second, model: model)
                                .frame(width: secondWidth, height: size.height)
                        }
                        .frame(width: size.width, height: size.height)
                    } else {
                        let availableHeight = max(0, size.height - 1)
                        let firstHeight = availableHeight * fraction
                        let secondHeight = max(0, availableHeight - firstHeight)

                        VStack(spacing: 0) {
                            PaneContainerView(node: first, model: model)
                                .frame(width: size.width, height: firstHeight)

                            SplitDividerView(
                                axis: .vertical,
                                splitId: splitId,
                                currentFraction: fraction,
                                availableLength: availableHeight,
                                model: model
                            )
                            .frame(width: size.width, height: 1)

                            PaneContainerView(node: second, model: model)
                                .frame(width: size.width, height: secondHeight)
                        }
                        .frame(width: size.width, height: size.height)
                    }
                } else {
                    Color.clear
                }
            }
            .id(splitId)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - 可拖拽调整宽高的分屏分割条 (基于 AppKit NSView 实现极致跟手、抗穿透与原生光标)

public struct SplitDividerView: NSViewRepresentable {
    let axis: Axis
    let splitId: UUID
    let currentFraction: CGFloat
    let availableLength: CGFloat
    let model: SuqiWindowModel

    public init(axis: Axis, splitId: UUID, currentFraction: CGFloat, availableLength: CGFloat, model: SuqiWindowModel) {
        self.axis = axis
        self.splitId = splitId
        self.currentFraction = currentFraction
        self.availableLength = availableLength
        self.model = model
    }

    public func makeNSView(context: Context) -> SplitDividerNSView {
        let view = SplitDividerNSView()
        view.axis = axis
        view.splitId = splitId
        view.currentFraction = currentFraction
        view.availableLength = availableLength
        view.model = model
        return view
    }

    public func updateNSView(_ nsView: SplitDividerNSView, context: Context) {
        nsView.axis = axis
        nsView.splitId = splitId
        nsView.currentFraction = currentFraction
        nsView.availableLength = availableLength
        nsView.model = model
        nsView.window?.invalidateCursorRects(for: nsView)
    }
}

public final class SplitDividerNSView: NSView {
    var axis: Axis = .horizontal
    var splitId: UUID = UUID()
    var currentFraction: CGFloat = 0.5
    var availableLength: CGFloat = 100
    weak var model: SuqiWindowModel?

    private var isHovering = false {
        didSet {
            if oldValue != isHovering {
                needsDisplay = true
            }
        }
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.zPosition = 1000
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.zPosition = 1000
    }

    public override func resetCursorRects() {
        super.resetCursorRects()
        let cursor = (axis == .horizontal) ? NSCursor.resizeLeftRight : NSCursor.resizeUpDown
        let hitRect = (axis == .horizontal)
            ? bounds.insetBy(dx: -4, dy: 0)
            : bounds.insetBy(dx: 0, dy: -4)
        addCursorRect(hitRect, cursor: cursor)
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        let hitRect = (axis == .horizontal)
            ? bounds.insetBy(dx: -4, dy: 0)
            : bounds.insetBy(dx: 0, dy: -4)
        if hitRect.contains(point) {
            return self
        }
        return super.hitTest(point)
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let color = isHovering
            ? NSColor.white.withAlphaComponent(0.35)
            : NSColor.white.withAlphaComponent(0.12)
        color.setFill()
        bounds.fill()
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let hitRect = (axis == .horizontal)
            ? bounds.insetBy(dx: -4, dy: 0)
            : bounds.insetBy(dx: 0, dy: -4)
        let area = NSTrackingArea(
            rect: hitRect,
            options: [.mouseEnteredAndExited, .activeInActiveApp, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    public override func mouseEntered(with event: NSEvent) {
        isHovering = true
    }

    public override func mouseExited(with event: NSEvent) {
        isHovering = false
    }

    public override func cursorUpdate(with event: NSEvent) {
        let cursor = (axis == .horizontal) ? NSCursor.resizeLeftRight : NSCursor.resizeUpDown
        cursor.set()
    }

    public override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            model?.updateSplitFraction(splitId: splitId, fraction: 0.5)
            return
        }

        guard availableLength > 0 else { return }
        let startLocation = event.locationInWindow
        let startFraction = currentFraction

        guard let window = self.window else { return }
        while true {
            guard let nextEvent = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { break }
            if nextEvent.type == .leftMouseUp {
                break
            }
            let currentLocation = nextEvent.locationInWindow
            let delta = (axis == .horizontal)
                ? (currentLocation.x - startLocation.x)
                : -(currentLocation.y - startLocation.y)
            let newFraction = min(max(startFraction + delta / availableLength, 0.05), 0.95)
            model?.updateSplitFraction(splitId: splitId, fraction: newFraction)
        }
    }
}
