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
    @ObservedObject private var manager = SuqiSessionManager.shared
    @FocusState private var isFocused: Bool

    public init(session: SuqiTerminalSession) {
        self.session = session
    }

    public var body: some View {
        TerminalSurfaceView(context: session.state)
            .terminalFocused($isFocused)
            .id(session.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transaction { $0.animation = nil }
            .onAppear {
                if manager.activeSessionId == session.id {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isFocused = true
                    }
                }
            }
            .onChange(of: manager.activeSessionId) { _, newId in
                if newId == session.id {
                    isFocused = true
                }
            }
    }
}
