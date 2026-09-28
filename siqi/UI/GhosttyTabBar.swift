//
//  GhosttyTabBar.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI

public struct GhosttyTabBar: View {
    @ObservedObject private var manager = SiqiSessionManager.shared
    @State private var hoveredTabId: UUID?

    public init() {}

    public var body: some View {
        HStack(spacing: 2) {
            // 红绿灯安全间距
            Spacer()
                .frame(width: 76)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(manager.sessions) { session in
                        let isActive = manager.activeSessionId == session.id
                        let isHovered = hoveredTabId == session.id

                        HStack(spacing: 6) {
                            Text(session.displayDirectory.isEmpty ? session.title : session.displayDirectory)
                                .font(.system(size: 11, weight: isActive ? .medium : .regular, design: .monospaced))
                                .foregroundStyle(isActive ? Color.white.opacity(0.92) : Color.white.opacity(0.50))
                                .lineLimit(1)

                            if isHovered || isActive {
                                Button {
                                    manager.closeSession(id: session.id)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 7.5, weight: .bold))
                                        .foregroundStyle(Color.white.opacity(0.6))
                                        .frame(width: 14, height: 14)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.08))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(isActive ? Color.white.opacity(0.12) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            manager.selectSession(id: session.id)
                        }
                        .onHover { hovering in
                            hoveredTabId = hovering ? session.id : nil
                        }
                    }

                    // 新建标签按钮
                    Button {
                        manager.createNewSession()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .frame(width: 20, height: 20)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("新建标签页 (⌘T)")
                }
                .padding(.vertical, 3)
            }

            Spacer()
        }
        .frame(height: 28)
        .background(Color.clear)
    }
}
