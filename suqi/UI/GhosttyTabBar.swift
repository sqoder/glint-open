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
            // macOS traffic lights clearance (~76pt)
            Spacer()
                .frame(width: 76)

            // Equal-width tab segments filling remaining horizontal space
            HStack(spacing: 4) {
                ForEach(Array(model.tabs.enumerated()), id: \.element.id) { index, tab in
                    tabItem(tab: tab, index: index)
                }

                plusButton
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 5)
            .padding(.trailing, 4)
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
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(isPlusHovered ? Color.white.opacity(0.95) : Color.white.opacity(0.60))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isPlusHovered ? Color.white.opacity(0.16) : Color.white.opacity(0.06))
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(isPlusHovered ? 0.14 : 0.04), lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isPlusHovered = $0 }
        .help("New Tab (⌘T)")
    }
}

// MARK: - Individual Apple/Ghostty Tab Item View

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
            // Background capsule
            backgroundView

            // Center: Tab title
            HStack(spacing: 0) {
                Spacer(minLength: 28)
                tabTitle
                Spacer(minLength: 28)
            }

            // Leading: active process indicator
            HStack {
                if tab.hasActiveProcess {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.65, blue: 0.25))
                        .frame(width: 5, height: 5)
                        .shadow(color: Color.orange.opacity(0.60), radius: 2)
                        .padding(.leading, 10)
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
                        .padding(.trailing, 10)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 26)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }

    private var tabTitle: some View {
        let title = tab.tabDisplayTitle.isEmpty ? tab.title : tab.tabDisplayTitle
        let textColor = isActive ? Color.white.opacity(0.96) : (isTabHovered ? Color.white.opacity(0.85) : Color.white.opacity(0.55))
        return Text(title)
            .font(.system(size: 11.5, weight: isActive ? .medium : .regular, design: .default))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .truncationMode(.middle)
    }

    private var shortcutBadge: some View {
        Text("⌘\(index + 1)")
            .font(.system(size: 10.5, weight: isActive ? .medium : .regular, design: .default))
            .foregroundStyle(isActive ? Color.white.opacity(0.70) : Color.white.opacity(0.38))
    }

    private var closeButton: some View {
        Button {
            onClose()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 7.5, weight: .bold))
                .foregroundStyle(isCloseHovered ? Color.white.opacity(0.95) : Color.white.opacity(0.65))
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(isCloseHovered ? Color.white.opacity(0.24) : Color.white.opacity(0.10))
                )
        }
        .buttonStyle(.plain)
        .onHover { isCloseHovered = $0 }
        .help("Close Tab (⌘W)")
    }

    private var backgroundView: some View {
        let fillColor: Color = isActive
            ? Color.white.opacity(0.16)
            : (isTabHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.035))

        let strokeColor: Color = isActive
            ? Color.white.opacity(0.20)
            : (isTabHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))

        let shadowColor: Color = isActive ? Color.black.opacity(0.18) : Color.clear

        return RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: isActive ? 0.75 : 0.5)
            )
            .shadow(color: shadowColor, radius: 2, y: 1)
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
