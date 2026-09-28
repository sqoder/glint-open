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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isFocused = true
                }
            }
    }
}
