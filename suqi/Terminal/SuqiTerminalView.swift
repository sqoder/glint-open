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
