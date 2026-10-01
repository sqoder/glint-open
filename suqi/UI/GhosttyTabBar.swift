//
//  GhosttyTabBar.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct GhosttyTabBar: View {
    @ObservedObject public var model: SuqiWindowModel
    @State private var hoveredTabId: UUID?
    @State private var draggingTabId: UUID?
    @State private var isPlusHovered: Bool = false

    public init(model: SuqiWindowModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 0) {
            // macOS traffic lights + pin button clearance (~92pt)
            Spacer()
                .frame(width: 92)

            // Equal-width ultra-refined capsule tab segments
            HStack(spacing: 4) {
                ForEach(Array(model.tabs.enumerated()), id: \.element.id) { index, tab in
                    tabItem(tab: tab, index: index)
                }

                plusButton
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            .padding(.trailing, 6)
        }
        .frame(height: 36)
        .background(Color.clear)
    }

    @ViewBuilder
    private func tabItem(tab: SuqiTab, index: Int) -> some View {
        let isActive = model.activeTabId == tab.id
        let isHovered = hoveredTabId == tab.id

        GhosttyTabItemView(
            tab: tab,
            index: index,
            isActive: isActive,
            isTabHovered: isHovered,
            onSelect: {
                model.selectTab(id: tab.id)
            },
            onClose: {
                model.closeTabWithConfirmation(id: tab.id, in: NSApp.keyWindow)
            }
        )
        .onHover { hovering in
            hoveredTabId = hovering ? tab.id : nil
        }
        .contextMenu {
            tabContextMenu(tab)
        }
        .onDrag {
            self.draggingTabId = tab.id
            return NSItemProvider(object: tab.id.uuidString as NSString)
        }
        .onDrop(
            of: [UTType.text],
            delegate: TabDropDelegate(
                destinationTab: tab,
                model: model,
                draggingTabId: $draggingTabId
            )
        )
    }

    @ViewBuilder
    private func tabContextMenu(_ tab: SuqiTab) -> some View {
        Button("New Tab") {
            model.createNewTab()
        }
        Button("Split Right") {
            model.splitRight()
        }
        Button("Split Down") {
            model.splitDown()
        }
        if model.tabs.count > 1 {
            Divider()
            Button("Move Tab to New Window") {
                model.detachTabToNewWindow(id: tab.id)
            }
            Button("Close Other Tabs") {
                for other in model.tabs where other.id != tab.id {
                    _ = model.closeTab(id: other.id)
                }
            }
        }
        Divider()
        Button("Close Tab") {
            model.closeTabWithConfirmation(id: tab.id, in: NSApp.keyWindow)
        }
    }

    private var plusButton: some View {
        Button {
            model.createNewTab()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(isPlusHovered ? Color.white.opacity(0.95) : Color.white.opacity(0.55))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(isPlusHovered ? Color.white.opacity(0.14) : Color.white.opacity(0.045))
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(isPlusHovered ? 0.12 : 0.03), lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isPlusHovered = $0 }
        .help("New Tab (⌘T)")
    }
}

// MARK: - Individual Ultra-Refined Apple Capsule Tab Item View

private struct GhosttyTabItemView: View {
    @ObservedObject var tab: SuqiTab
    let index: Int
    let isActive: Bool
    let isTabHovered: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isCloseHovered: Bool = false

    var body: some View {
        ZStack {
            // Perfect continuous capsule background
            backgroundView

            // Center: Tab title
            HStack(spacing: 0) {
                Spacer(minLength: 26)
                tabTitle
                Spacer(minLength: 26)
            }

            // Leading: active process indicator
            HStack {
                if tab.hasActiveProcess {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.65, blue: 0.25))
                        .frame(width: 4.5, height: 4.5)
                        .shadow(color: Color.orange.opacity(0.60), radius: 1.5)
                        .padding(.leading, 9)
                }
                Spacer()
            }

            // Trailing: shortcut badge (⌘N) or close button (on hover)
            HStack {
                Spacer()
                if isTabHovered {
                    closeButton
                        .padding(.trailing, 6)
                } else if index < 9 {
                    shortcutBadge
                        .padding(.trailing, 9)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 23)
        .contentShape(Capsule(style: .continuous))
        .onTapGesture {
            onSelect()
        }
    }

    private var tabTitle: some View {
        let title = tab.tabDisplayTitle.isEmpty ? tab.title : tab.tabDisplayTitle
        let textColor = isActive ? Color.white.opacity(0.96) : (isTabHovered ? Color.white.opacity(0.85) : Color.white.opacity(0.52))
        return Text(title)
            .font(.system(size: 11, weight: isActive ? .medium : .regular, design: .default))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .truncationMode(.middle)
    }

    private var shortcutBadge: some View {
        Text("⌘\(index + 1)")
            .font(.system(size: 9.5, weight: isActive ? .medium : .regular, design: .default))
            .foregroundStyle(isActive ? Color.white.opacity(0.65) : Color.white.opacity(0.32))
    }

    private var closeButton: some View {
        Button {
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 6.5, weight: .bold))
                .foregroundStyle(isCloseHovered ? Color.white.opacity(0.95) : Color.white.opacity(0.60))
                .frame(width: 14, height: 14)
                .background(
                    Circle()
                        .fill(isCloseHovered ? Color.white.opacity(0.24) : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
        .onHover { isCloseHovered = $0 }
        .help("Close Tab (⌘W)")
    }

    private var backgroundView: some View {
        let fillColor: Color = isActive
            ? Color.white.opacity(0.135)
            : (isTabHovered ? Color.white.opacity(0.07) : Color.white.opacity(0.025))

        let strokeColor: Color = isActive
            ? Color.white.opacity(0.18)
            : (isTabHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.015))

        let shadowColor: Color = isActive ? Color.black.opacity(0.15) : Color.clear

        return Capsule(style: .continuous)
            .fill(fillColor)
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: isActive ? 0.65 : 0.5)
            )
            .shadow(color: shadowColor, radius: 1.5, y: 0.5)
    }
}

// MARK: - Tab Drop Delegate (Reordering)

struct TabDropDelegate: DropDelegate {
    let destinationTab: SuqiTab
    let model: SuqiWindowModel
    @Binding var draggingTabId: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggingTabId,
              draggingTabId != destinationTab.id,
              let fromIndex = model.tabs.firstIndex(where: { $0.id == draggingTabId }),
              let toIndex = model.tabs.firstIndex(where: { $0.id == destinationTab.id })
        else { return }

        withAnimation(.easeInOut(duration: 0.15)) {
            model.moveTab(from: fromIndex, to: toIndex)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingTabId = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
