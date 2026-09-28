//
//  SiqiSessionManager.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI
import Combine

@MainActor
public final class SiqiSessionManager: ObservableObject {
    public static let shared = SiqiSessionManager()

    @Published public private(set) var sessions: [SiqiTerminalSession] = []
    @Published public var activeSessionId: UUID?

    private init() {
        let defaultSession = SiqiTerminalSession()
        self.sessions = [defaultSession]
        self.activeSessionId = defaultSession.id
    }

    public var activeSession: SiqiTerminalSession? {
        guard let activeSessionId else { return sessions.first }
        return sessions.first { $0.id == activeSessionId } ?? sessions.first
    }

    public var activeIndex: Int {
        guard let activeSessionId else { return 0 }
        return sessions.firstIndex { $0.id == activeSessionId } ?? 0
    }

    @discardableResult
    public func createNewSession(workingDirectory: String? = nil) -> SiqiTerminalSession {
        let initialDir = workingDirectory ?? activeSession?.fullDirectory ?? NSHomeDirectory()
        let session = SiqiTerminalSession(workingDirectory: initialDir)
        sessions.append(session)
        activeSessionId = session.id
        return session
    }

    public func closeSession(id: UUID) {
        guard sessions.count > 1 else {
            // 如果只剩一个标签页，重启当前会话
            activeSession?.restart()
            return
        }

        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions.remove(at: index)
            if activeSessionId == id {
                let newIndex = max(0, min(index, sessions.count - 1))
                activeSessionId = sessions[newIndex].id
            }
        }
    }

    public func closeActiveSession() {
        if let activeSessionId {
            closeSession(id: activeSessionId)
        }
    }

    public func selectSession(id: UUID) {
        if sessions.contains(where: { $0.id == id }) {
            activeSessionId = id
        }
    }

    public func selectTab(at index: Int) {
        guard index >= 0, index < sessions.count else { return }
        activeSessionId = sessions[index].id
    }

    public func nextTab() {
        guard !sessions.isEmpty else { return }
        let next = (activeIndex + 1) % sessions.count
        activeSessionId = sessions[next].id
    }

    public func previousTab() {
        guard !sessions.isEmpty else { return }
        let prev = (activeIndex - 1 + sessions.count) % sessions.count
        activeSessionId = sessions[prev].id
    }

    public func restartActiveSession() {
        activeSession?.restart()
    }

    public func clearActiveSession() {
        activeSession?.clearScreen()
    }

    public func reloadAllSessions() {
        for session in sessions {
            session.restart()
        }
    }
}
