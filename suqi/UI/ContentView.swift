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
    @State private var configReloadToken = UUID()

    public init(model: SuqiWindowModel) {
        self.model = model
    }

    private var userConfig: GhosttyUserConfig {
        _ = configReloadToken
        return GhosttyUserConfig.load().config
    }

    private var isTranslucent: Bool {
        userConfig.backgroundOpacity < 1.0 || userConfig.backgroundBlur > 0
    }

    private var themeBg: Color {
        SuqiTheme.backgroundColor(for: userConfig.themeName, customBackground: userConfig.background)
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
                // 顶部标题/标签栏区域（高度 32）：底层承载原生可拖拽/双击缩放交互，上层渲染标签页
                ZStack(alignment: .center) {
                    WindowDragArea()
                        .frame(height: 32)

                    if model.tabs.count > 1 {
                        GhosttyTabBar(model: model)
                            .frame(height: 32)
                    } else if let activeTab = model.activeTab {
                        VStack(spacing: 2) {
                            Text(activeTab.displayPathFormatted)
                                .font(.system(size: 11.5, weight: .regular, design: .default))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineLimit(1)
                            Text("···")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.40))
                        }
                        .offset(y: 6.5)
                        .frame(maxWidth: .infinity, maxHeight: 32)
                        .allowsHitTesting(false)
                    }
                }
                .frame(height: 32)

                // 终端渲染工作区（全幅贴合，支持多标签、多分屏、全屏聚焦与滚动搜索）
                ZStack(alignment: .topTrailing) {
                    if let activeTab = model.activeTab {
                        ActiveTabView(tab: activeTab, model: model)
                            .id(activeTab.id)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Color.clear
                    }

                    if model.isSearching {
                        TerminalSearchBar(model: model)
                            .padding(.top, 6)
                            .padding(.trailing, 14)
                            .transition(.opacity)
                            .zIndex(999)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .onReceive(NotificationCenter.default.publisher(for: .ghosttyConfigDidChange)) { _ in
            configReloadToken = UUID()
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
        ZStack(alignment: .topTrailing) {
            if tab.isZoomed, let activeSession = tab.activeSession {
                SuqiTerminalView(session: activeSession, model: model)
                    .id(activeSession.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 极简全屏/缩放徽标 (Ghostty 风格)
                HStack(spacing: 5) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 9, weight: .bold))
                    Text("ZOOMED · ⌘⇧↩ 还原")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.60))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
                .padding(.top, 6)
                .padding(.trailing, 10)
                .onTapGesture {
                    tab.toggleZoom()
                }
            } else {
                PaneContainerView(node: tab.rootPane, model: model)
                    .id(tab.id)
            }
        }
    }
}

public struct TerminalSearchBar: View {
    @ObservedObject var model: SuqiWindowModel
    @State private var query: String = ""

    public init(model: SuqiWindowModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 6) {
            SearchFieldRepresentable(
                text: $query,
                onCommit: {
                    _ = model.activeSession?.state.surface?.navigateSearch(forward: true)
                },
                onCancel: {
                    closeSearch()
                }
            )
            .frame(width: 180, height: 22)
            .onChange(of: query) { _, newQuery in
                _ = model.activeSession?.state.surface?.search(newQuery)
            }

            // Prev Match
            Button {
                _ = model.activeSession?.state.surface?.navigateSearch(forward: false)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(width: 16, height: 16)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("上一个匹配项 (⇧Enter)")

            // Next Match
            Button {
                _ = model.activeSession?.state.surface?.navigateSearch(forward: true)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(width: 16, height: 16)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("下一个匹配项 (Enter)")

            // Close Search
            Button {
                closeSearch()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .help("关闭搜索 (Esc)")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
        .onAppear {
            _ = model.activeSession?.state.surface?.startSearch()
        }
    }

    private func closeSearch() {
        model.isSearching = false
        _ = model.activeSession?.state.surface?.endSearch()
    }
}

// MARK: - AppKit 原生搜索输入框 (保证 ⌘F 唤起时 100% 抢占 First Responder)

struct SearchFieldRepresentable: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    var onCancel: () -> Void

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = "查找回滚内容..."
        field.font = .monospacedSystemFont(ofSize: 11.5, weight: .regular)
        field.delegate = context.coordinator
        field.focusRingType = .none
        field.isBordered = false
        field.backgroundColor = .clear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            field.window?.makeFirstResponder(field)
        }
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: SearchFieldRepresentable

        init(_ parent: SearchFieldRepresentable) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSSearchField {
                parent.text = field.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit()
                return true
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onCancel()
                return true
            }
            return false
        }
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
                        let dividerThickness: CGFloat = 8
                        let availableWidth = max(0, size.width - dividerThickness)
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
                            .frame(width: dividerThickness, height: size.height)

                            PaneContainerView(node: second, model: model)
                                .frame(width: secondWidth, height: size.height)
                        }
                        .frame(width: size.width, height: size.height)
                    } else {
                        let dividerThickness: CGFloat = 8
                        let availableHeight = max(0, size.height - dividerThickness)
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
                            .frame(width: size.width, height: dividerThickness)

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
        addCursorRect(bounds, cursor: cursor)
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        if bounds.contains(point) {
            return self
        }
        return super.hitTest(point)
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // 居中绘制 1pt 精准发丝分割线，其余区域保持透明作为跟手缓冲响应区
        let lineRect: NSRect = {
            if axis == .horizontal {
                return NSRect(x: (bounds.width - 1) / 2.0, y: 0, width: 1, height: bounds.height)
            } else {
                return NSRect(x: 0, y: (bounds.height - 1) / 2.0, width: bounds.width, height: 1)
            }
        }()

        let color = isHovering
            ? NSColor.white.withAlphaComponent(0.45)
            : NSColor.white.withAlphaComponent(0.12)
        color.setFill()
        lineRect.fill()
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let area = NSTrackingArea(
            rect: bounds,
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
