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
    @State private var draggingTabId: UUID?

    public init(model: SuqiWindowModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 2) {
            // Traffic lights inset
            Spacer()
                .frame(width: 82)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(model.tabs) { tab in
                        let isActive = model.activeTabId == tab.id
                        let isHovered = hoveredTabId == tab.id

                        HStack(spacing: 6) {
                            if tab.hasActiveProcess {
                                Circle()
                                    .fill(Color(red: 0.95, green: 0.65, blue: 0.25))
                                    .frame(width: 5, height: 5)
                            }

                            Text(tab.tabDisplayTitle.isEmpty ? tab.title : tab.tabDisplayTitle)
                                .font(.system(size: 11, weight: isActive ? .medium : .regular, design: .monospaced))
                                .foregroundStyle(isActive ? Color.white.opacity(0.92) : Color.white.opacity(0.50))
                                .lineLimit(1)

                            if isHovered || isActive {
                                Button {
                                    model.closeTabWithConfirmation(id: tab.id, in: NSApp.keyWindow)
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
                        .contextMenu {
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
                        // Support tab drag-and-drop reordering
                        .onDrag {
                            self.draggingTabId = tab.id
                            return NSItemProvider(object: tab.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: TabDropDelegate(
                                destinationTab: tab,
                                model: model,
                                draggingTabId: $draggingTabId
                            )
                        )
                    }

                    // New tab button
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
                    .help("New Tab (⌘T)")
                }
                .padding(.vertical, 3)
            }

            Spacer()
        }
        .frame(height: 32)
        .background(Color.clear)
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
