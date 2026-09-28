//
//  GhosttyTabBar.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI

public struct GhosttyTabBar: View {
    @ObservedObject public var model: SuqiWindowModel
    @State private var hoveredTabId: UUID?

    public init(model: SuqiWindowModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 2) {
            // 红绿灯安全间距
            Spacer()
                .frame(width: 76)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(model.tabs) { tab in
                        let isActive = model.activeTabId == tab.id
                        let isHovered = hoveredTabId == tab.id

                        HStack(spacing: 6) {
                            Text(tab.displayDirectory.isEmpty ? tab.title : tab.displayDirectory)
                                .font(.system(size: 11, weight: isActive ? .medium : .regular, design: .monospaced))
                                .foregroundStyle(isActive ? Color.white.opacity(0.92) : Color.white.opacity(0.50))
                                .lineLimit(1)

                            if isHovered || isActive {
                                Button {
                                    model.closeTab(id: tab.id)
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
                            model.selectTab(id: tab.id)
                        }
                        .onHover { hovering in
                            hoveredTabId = hovering ? tab.id : nil
                        }
                    }

                    // 新建标签按钮
                    Button {
                        model.createNewTab()
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
