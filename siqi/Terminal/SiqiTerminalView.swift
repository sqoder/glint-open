//
//  SiqiTerminalView.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI
import AppKit
import GhosttyTerminal

public struct SiqiTerminalView: View {
    @ObservedObject var session: SiqiTerminalSession
    @ObservedObject private var manager = SiqiSessionManager.shared
    @FocusState private var isFocused: Bool

    public init(session: SiqiTerminalSession) {
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
