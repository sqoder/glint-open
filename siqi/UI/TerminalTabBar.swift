//
//  TerminalTabBar.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI

public struct TerminalTabBar: View {
    @ObservedObject private var manager = SiqiSessionManager.shared
    @State private var hoveredTabId: UUID?

    public init() {}

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(manager.sessions.enumerated()), id: \.element.id) { index, session in
                    let isActive = manager.activeSessionId == session.id
                    let isHovered = hoveredTabId == session.id

                    HStack(spacing: 6) {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(isActive ? SiqiTheme.accentColor : SiqiTheme.textTertiary)

                        Text(session.displayDirectory.isEmpty ? session.title : session.displayDirectory)
                            .font(.system(size: 11, weight: isActive ? .medium : .regular, design: .monospaced))
                            .foregroundStyle(isActive ? SiqiTheme.textPrimary : SiqiTheme.textSecondary)
                            .lineLimit(1)

                        if manager.sessions.count > 1 && (isActive || isHovered) {
                            Button {
                                manager.closeSession(id: session.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(SiqiTheme.textSecondary)
                                    .frame(width: 14, height: 14)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                            .help("关闭标签页 (⌘W)")
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isActive ? SiqiTheme.activeTabBackground : (isHovered ? SiqiTheme.hoverBackground : Color.clear))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(isActive ? Color.white.opacity(0.15) : Color.clear, lineWidth: 0.5)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        manager.selectSession(id: session.id)
                    }
                    .onHover { hovering in
                        hoveredTabId = hovering ? session.id : nil
                    }
                }

                // 新建标签页按钮
                Button {
                    manager.createNewSession()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SiqiTheme.textSecondary)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .help("新建标签页 (⌘T)")
            }
            .padding(.vertical, 2)
        }
    }
}
