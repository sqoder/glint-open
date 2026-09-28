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
    let model: SuqiWindowModel
    @FocusState private var isFocused: Bool

    public init(session: SuqiTerminalSession, model: SuqiWindowModel) {
        self.session = session
        self.model = model
    }

    public var body: some View {
        TerminalSurfaceView(context: session.state)
            .terminalFocused($isFocused)
            .id(session.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transaction { $0.animation = nil }
            .overlay(alignment: .topTrailing) {
                // Invisible overlay to catch right-click without blocking terminal interaction
                Color.clear
                    .contentShape(Rectangle())
                    .allowsHitTesting(false)
            }
            .contextMenu {
                Button("Copy") {
                    SuqiWindowManager.shared.activeWindowController?.handleCopy()
                }
                Button("Paste") {
                    SuqiWindowManager.shared.activeWindowController?.handlePaste()
                }
                Divider()
                Button("Select All") {
                    _ = session.state.performBindingAction("select_all")
                }
                Divider()
                Button("Clear Screen") {
                    model.clearActiveSession()
                }
                Divider()
                Button("Split Right") {
                    model.splitRight()
                }
                Button("Split Down") {
                    model.splitDown()
                }
                Divider()
                Button("New Tab") {
                    model.createNewTab()
                }
                Button("New Window") {
                    SuqiWindowManager.shared.createWindow(
                        workingDirectory: session.fullDirectory
                    )
                }
            }
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
    }
}
