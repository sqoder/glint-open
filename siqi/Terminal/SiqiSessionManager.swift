//
//  SiqiSessionManager.swift
//  siqi
//
//  Created for siqi Terminal.
//

import SwiftUI
import Combine

// MARK: - PaneNode (分屏树节点)

public enum PaneNode: Identifiable, Equatable {
    case terminal(SiqiTerminalSession)
    indirect case split(id: UUID, axis: Axis, first: PaneNode, second: PaneNode)

    public var id: UUID {
        switch self {
        case .terminal(let session):
            return session.id
        case .split(let id, _, _, _):
            return id
        }
    }

    public static func == (lhs: PaneNode, rhs: PaneNode) -> Bool {
        lhs.id == rhs.id
    }

    public var allSessions: [SiqiTerminalSession] {
        switch self {
        case .terminal(let session):
            return [session]
        case .split(_, _, let first, let second):
            return first.allSessions + second.allSessions
        }
    }

    public func findSession(id: UUID) -> SiqiTerminalSession? {
        switch self {
        case .terminal(let s):
            return s.id == id ? s : nil
        case .split(_, _, let first, let second):
            return first.findSession(id: id) ?? second.findSession(id: id)
        }
    }

    public func split(targetSessionId: UUID, axis: Axis, newSession: SiqiTerminalSession) -> PaneNode {
        switch self {
        case .terminal(let s):
            if s.id == targetSessionId {
                return .split(id: UUID(), axis: axis, first: .terminal(s), second: .terminal(newSession))
            }
            return self
        case .split(let id, let currentAxis, let first, let second):
            let newFirst = first.split(targetSessionId: targetSessionId, axis: axis, newSession: newSession)
            let newSecond = second.split(targetSessionId: targetSessionId, axis: axis, newSession: newSession)
            return .split(id: id, axis: currentAxis, first: newFirst, second: newSecond)
        }
    }

    public func remove(sessionId: UUID) -> PaneNode? {
        switch self {
        case .terminal(let s):
            if s.id == sessionId {
                return nil
            }
            return self
        case .split(let id, let axis, let first, let second):
            let newFirst = first.remove(sessionId: sessionId)
            let newSecond = second.remove(sessionId: sessionId)
            if let newFirst, let newSecond {
                return .split(id: id, axis: axis, first: newFirst, second: newSecond)
            } else if let newFirst {
                return newFirst
            } else if let newSecond {
                return newSecond
            } else {
                return nil
            }
        }
    }
}

// MARK: - SiqiTab (标签页)

@MainActor
public final class SiqiTab: ObservableObject, Identifiable {
    public let id: UUID
    @Published public var rootPane: PaneNode
    @Published public var activeSessionId: UUID

    public init(session: SiqiTerminalSession) {
        self.id = UUID()
        self.rootPane = .terminal(session)
        self.activeSessionId = session.id
    }

    public var title: String {
        activeSession?.title ?? "zsh"
    }

    public var displayDirectory: String {
        activeSession?.displayDirectory ?? "~"
    }

    public var activeSession: SiqiTerminalSession? {
        rootPane.findSession(id: activeSessionId) ?? rootPane.allSessions.first
    }

    public var allSessions: [SiqiTerminalSession] {
        rootPane.allSessions
    }

    public func splitActive(axis: Axis, newSession: SiqiTerminalSession) {
        rootPane = rootPane.split(targetSessionId: activeSessionId, axis: axis, newSession: newSession)
        activeSessionId = newSession.id
    }

    public func closeSession(id: UUID) -> Bool {
        if let newRoot = rootPane.remove(sessionId: id) {
            rootPane = newRoot
            if activeSessionId == id {
                activeSessionId = rootPane.allSessions.first?.id ?? UUID()
            }
            return true
        }
        return false
    }
}

// MARK: - SiqiSessionManager (多标签与分屏管理器)

@MainActor
public final class SiqiSessionManager: ObservableObject {
    public static let shared = SiqiSessionManager()

    @Published public private(set) var tabs: [SiqiTab] = []
    @Published public var activeTabId: UUID?

    /// 兼容旧接口：返回所有活跃标签与分屏的会话集合
    public var sessions: [SiqiTerminalSession] {
        tabs.flatMap { $0.allSessions }
    }

    public var activeSessionId: UUID? {
        get { activeTab?.activeSessionId }
        set {
            if let val = newValue {
                activeTab?.activeSessionId = val
            }
        }
    }

    public var activeTab: SiqiTab? {
        guard let activeTabId else { return tabs.first }
        return tabs.first { $0.id == activeTabId } ?? tabs.first
    }

    public var activeSession: SiqiTerminalSession? {
        activeTab?.activeSession
    }

    public var activeIndex: Int {
        guard let activeTabId else { return 0 }
        return tabs.firstIndex { $0.id == activeTabId } ?? 0
    }

    private init() {
        let defaultSession = SiqiTerminalSession()
        let defaultTab = SiqiTab(session: defaultSession)
        self.tabs = [defaultTab]
        self.activeTabId = defaultTab.id
    }

    // ⌘T: 新建标签页
    @discardableResult
    public func createNewSession(workingDirectory: String? = nil) -> SiqiTerminalSession {
        let initialDir = workingDirectory ?? activeSession?.fullDirectory ?? NSHomeDirectory()
        let session = SiqiTerminalSession(workingDirectory: initialDir)
        let tab = SiqiTab(session: session)
        tabs.append(tab)
        activeTabId = tab.id
        return session
    }

    // ⌘D: 垂直分屏新建 (Split Right，左右分屏)
    @discardableResult
    public func splitRight(workingDirectory: String? = nil) -> SiqiTerminalSession {
        splitActivePane(axis: .horizontal, workingDirectory: workingDirectory)
    }

    // ⌘Shift+D: 水平分屏新建 (Split Down，上下分屏)
    @discardableResult
    public func splitDown(workingDirectory: String? = nil) -> SiqiTerminalSession {
        splitActivePane(axis: .vertical, workingDirectory: workingDirectory)
    }

    @discardableResult
    public func splitActivePane(axis: Axis, workingDirectory: String? = nil) -> SiqiTerminalSession {
        objectWillChange.send()
        let initialDir = workingDirectory ?? activeSession?.fullDirectory ?? NSHomeDirectory()
        let session = SiqiTerminalSession(workingDirectory: initialDir)
        if let currentTab = activeTab {
            currentTab.objectWillChange.send()
            currentTab.splitActive(axis: axis, newSession: session)
        } else {
            let tab = SiqiTab(session: session)
            tabs.append(tab)
            activeTabId = tab.id
        }
        return session
    }

    // ⌘W: 优先关闭当前活跃分屏，分屏全关后关闭标签页
    public func closeActiveSession() {
        objectWillChange.send()
        guard let currentTab = activeTab else { return }
        currentTab.objectWillChange.send()
        let currentSessionId = currentTab.activeSessionId
        let hasPanesRemaining = currentTab.closeSession(id: currentSessionId)
        if !hasPanesRemaining {
            closeTab(id: currentTab.id)
        }
    }

    public func closeSession(id: UUID) {
        closeActiveSession()
    }

    public func closeTab(id: UUID) {
        guard tabs.count > 1 else {
            activeSession?.restart()
            return
        }

        if let index = tabs.firstIndex(where: { $0.id == id }) {
            tabs.remove(at: index)
            if activeTabId == id {
                let newIndex = max(0, min(index, tabs.count - 1))
                activeTabId = tabs[newIndex].id
            }
        }
    }

    public func selectTab(id: UUID) {
        if tabs.contains(where: { $0.id == id }) {
            activeTabId = id
        }
    }

    public func selectTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }
        activeTabId = tabs[index].id
    }

    public func selectSession(id: UUID) {
        for tab in tabs {
            if tab.allSessions.contains(where: { $0.id == id }) {
                activeTabId = tab.id
                tab.activeSessionId = id
                return
            }
        }
    }

    public func notifySessionFocused(id: UUID) {
        selectSession(id: id)
    }

    public func nextTab() {
        guard !tabs.isEmpty else { return }
        let next = (activeIndex + 1) % tabs.count
        activeTabId = tabs[next].id
    }

    public func previousTab() {
        guard !tabs.isEmpty else { return }
        let prev = (activeIndex - 1 + tabs.count) % tabs.count
        activeTabId = tabs[prev].id
    }

    public func nextPane() {
        guard let currentTab = activeTab else { return }
        let all = currentTab.allSessions
        guard all.count > 1 else { return }
        if let idx = all.firstIndex(where: { $0.id == currentTab.activeSessionId }) {
            let next = (idx + 1) % all.count
            currentTab.activeSessionId = all[next].id
        }
    }

    public func previousPane() {
        guard let currentTab = activeTab else { return }
        let all = currentTab.allSessions
        guard all.count > 1 else { return }
        if let idx = all.firstIndex(where: { $0.id == currentTab.activeSessionId }) {
            let prev = (idx - 1 + all.count) % all.count
            currentTab.activeSessionId = all[prev].id
        }
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
