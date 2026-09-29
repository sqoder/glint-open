//
//  SuqiTerminalView.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit
import GhosttyTerminal

public struct PersistentTerminalSurfaceView: NSViewRepresentable {
    let session: SuqiTerminalSession

    public func makeNSView(context: Context) -> AppTerminalView {
        session.terminalView.removeFromSuperview()
        return session.terminalView
    }

    public func updateNSView(_ nsView: AppTerminalView, context: Context) {}
}

public struct SuqiTerminalView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var session: SuqiTerminalSession
    @ObservedObject var model: SuqiWindowModel

    public init(session: SuqiTerminalSession, model: SuqiWindowModel) {
        self.session = session
        self.model = model
    }

    private var isMultiPane: Bool {
        (model.activeTab?.allSessions.count ?? 1) > 1
    }

    private var isActivePane: Bool {
        model.activeSessionId == session.id
    }

    public var body: some View {
        ZStack(alignment: .trailing) {
            PersistentTerminalSurfaceView(session: session)
                .id(session.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transaction { $0.animation = nil }

            // 右侧原生极简滚动条 (仅 #9D9FA2 单一滑块，无任何背景范围条，默认隐藏，滑动时渐显)
            TerminalScrollbarView(session: session)

            // 分屏模式下的活跃窗格微光细边框指示
            if isMultiPane && isActivePane {
                Rectangle()
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            session.state.adopt(colorScheme: colorScheme)
            if model.activeSessionId == session.id {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    session.terminalView.window?.makeFirstResponder(session.terminalView)
                }
            }
        }
        .onChange(of: colorScheme) { _, newScheme in
            session.state.adopt(colorScheme: newScheme)
        }
        .onChange(of: model.activeSessionId) { _, newId in
            if newId == session.id {
                session.terminalView.window?.makeFirstResponder(session.terminalView)
            }
        }
    }
}

// MARK: - 极简终端滚动条 (#9D9FA2，无背景范围条，平时完全隐藏，仅上下滑动/拖拽时出现)

struct TerminalScrollbarView: View {
    @ObservedObject var session: SuqiTerminalSession
    @State private var isVisible: Bool = false
    @State private var isDragging: Bool = false
    @State private var isHovering: Bool = false
    @State private var dragStartThumbY: CGFloat = 0
    @State private var hideTask: DispatchWorkItem? = nil

    // 用户指定专属颜色 #9D9FA2
    private let thumbColor = Color(red: 157/255.0, green: 159/255.0, blue: 162/255.0)

    var body: some View {
        if let scrollbar = session.state.scrollbar, scrollbar.total > scrollbar.len {
            GeometryReader { proxy in
                let height = proxy.size.height
                let total = max(1, scrollbar.total)
                let len = scrollbar.len
                let offset = scrollbar.offset
                let maxOffset = max(1, total - len)

                let visibleRatio = CGFloat(len) / CGFloat(total)
                let thumbHeight = max(28, min(height, height * visibleRatio))
                let trackDistance = max(0, height - thumbHeight)

                let progress = CGFloat(min(offset, maxOffset)) / CGFloat(maxOffset)
                let currentThumbY = trackDistance * progress

                let barWidth: CGFloat = (isHovering || isDragging) ? 6.5 : 4.5

                ZStack(alignment: .topTrailing) {
                    // 透明手势响应区域（无任何背景颜色与视觉范围条，不遮挡终端内容）
                    Color.clear
                        .frame(width: 16)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        dragStartThumbY = currentThumbY
                                    }
                                    showScrollbar()
                                    let deltaY = value.translation.height
                                    let newThumbY = min(max(0, dragStartThumbY + deltaY), trackDistance)
                                    let newProgress = trackDistance > 0 ? (newThumbY / trackDistance) : 1.0
                                    let targetRow = UInt(round(Double(newProgress) * Double(maxOffset)))
                                    _ = session.state.scrollToRow(targetRow)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    scheduleHide()
                                }
                        )

                    // 仅单独渲染 #9D9FA2 滚动滑块，默认隐藏，滑动时平滑显示
                    Capsule(style: .continuous)
                        .fill(thumbColor)
                        .frame(width: barWidth, height: thumbHeight)
                        .offset(x: -2.5, y: currentThumbY)
                        .opacity(isVisible ? (isDragging ? 1.0 : (isHovering ? 0.95 : 0.85)) : 0.0)
                        .animation(.easeInOut(duration: 0.25), value: isVisible)
                        .animation(.easeInOut(duration: 0.15), value: barWidth)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .onHover { hovering in
                    isHovering = hovering
                    if hovering {
                        showScrollbar()
                    } else if !isDragging {
                        scheduleHide()
                    }
                }
            }
            .onChange(of: session.state.scrollbar?.offset) { _, _ in
                showAndScheduleHide()
            }
            .onChange(of: session.state.scrollbar?.total) { _, _ in
                showAndScheduleHide()
            }
        }
    }

    private func showScrollbar() {
        hideTask?.cancel()
        hideTask = nil
        withAnimation(.easeInOut(duration: 0.15)) {
            isVisible = true
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        let task = DispatchWorkItem {
            guard !isHovering && !isDragging else { return }
            withAnimation(.easeInOut(duration: 0.40)) {
                isVisible = false
            }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: task)
    }

    private func showAndScheduleHide() {
        showScrollbar()
        if !isHovering && !isDragging {
            scheduleHide()
        }
    }
}
