//
//  SuqiTerminalView.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit
import GhosttyTerminal

public struct SuqiTerminalView: View {
    @ObservedObject var session: SuqiTerminalSession
    @ObservedObject var model: SuqiWindowModel
    @FocusState private var isFocused: Bool

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
            TerminalSurfaceView(context: session.state)
                .terminalFocused($isFocused)
                .id(session.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transaction { $0.animation = nil }

            // 右侧原生交互式回滚导航滚动条 (Terminal Scrollbar)
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
            if model.activeSessionId == session.id {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isFocused = true
                }
            }
        }
        .onChange(of: model.activeSessionId) { _, newId in
            if newId == session.id {
                isFocused = true
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused && model.activeSessionId != session.id {
                model.activeSessionId = session.id
            }
        }
    }
}

// MARK: - 原生交互式终端滚动条 (Terminal Scrollbar)

struct TerminalScrollbarView: View {
    @ObservedObject var session: SuqiTerminalSession
    @State private var isHovering = false
    @State private var isDragging = false
    @State private var dragStartThumbY: CGFloat = 0

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

                let barWidth: CGFloat = (isHovering || isDragging) ? 8 : 4.5

                ZStack(alignment: .topTrailing) {
                    // 鼠标移入时显示的轻量响应背景轨道，支持点击页面快速跳转 (PageUp / PageDown)
                    Rectangle()
                        .fill(Color.black.opacity((isHovering || isDragging) ? 0.22 : 0.0))
                        .frame(width: 14)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            if location.y < currentThumbY {
                                let target = UInt(max(0, Int64(offset) - Int64(len)))
                                _ = session.state.scrollToRow(target)
                            } else if location.y > currentThumbY + thumbHeight {
                                let target = UInt(min(Int64(maxOffset), Int64(offset) + Int64(len)))
                                _ = session.state.scrollToRow(target)
                            }
                        }

                    // 滚动滑块 (Thumb)：支持鼠标拖拽上下平滑滚动
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(isDragging ? 0.75 : (isHovering ? 0.55 : 0.30)))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
                        )
                        .frame(width: barWidth, height: thumbHeight)
                        .offset(x: -2.5, y: currentThumbY)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if !isDragging {
                                        isDragging = true
                                        dragStartThumbY = currentThumbY
                                    }
                                    let deltaY = value.translation.height
                                    let newThumbY = min(max(0, dragStartThumbY + deltaY), trackDistance)
                                    let newProgress = trackDistance > 0 ? (newThumbY / trackDistance) : 1.0
                                    let targetRow = UInt(round(Double(newProgress) * Double(maxOffset)))
                                    _ = session.state.scrollToRow(targetRow)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovering = hovering
                    }
                }
            }
            .transition(.opacity)
        }
    }
}
