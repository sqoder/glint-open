//
//  SuqiWindowModel.swift
//  suqi
//
//  Created for suqi Terminal.
//

import SwiftUI
import Combine

// MARK: - PaneNode (分屏树节点)

public enum PaneNode: Identifiable, Equatable {
    case terminal(SuqiTerminalSession)
    indirect case split(id: UUID, axis: Axis, fraction: CGFloat, first: PaneNode, second: PaneNode)

    public var id: UUID {
        switch self {
        case .terminal(let session):
            return session.id
        case .split(let id, _, _, _, _):
            return id
        }
    }

    public static func == (lhs: PaneNode, rhs: PaneNode) -> Bool {
        switch (lhs, rhs) {
        case (.terminal(let s1), .terminal(let s2)):
            return s1.id == s2.id
        case (.split(let id1, let axis1, let frac1, let f1, let s1), .split(let id2, let axis2, let frac2, let f2, let s2)):
            return id1 == id2 && axis1 == axis2 && abs(frac1 - frac2) < 0.0001 && f1 == f2 && s1 == s2
        default:
            return false
        }
    }

    public var allSessions: [SuqiTerminalSession] {
        switch self {
        case .terminal(let session):
            return [session]
        case .split(_, _, _, let first, let second):
            return first.allSessions + second.allSessions
        }
    }

    public func findSession(id: UUID) -> SuqiTerminalSession? {
        switch self {
        case .terminal(let s):
            return s.id == id ? s : nil
        case .split(_, _, _, let first, let second):
            return first.findSession(id: id) ?? second.findSession(id: id)
        }
    }

    public func split(targetSessionId: UUID, axis: Axis, newSession: SuqiTerminalSession) -> PaneNode {
        switch self {
        case .terminal(let s):
            if s.id == targetSessionId {
                return .split(id: UUID(), axis: axis, fraction: 0.5, first: .terminal(s), second: .terminal(newSession))
            }
            return self
        case .split(let id, let currentAxis, let fraction, let first, let second):
            let newFirst = first.split(targetSessionId: targetSessionId, axis: axis, newSession: newSession)
            let newSecond = second.split(targetSessionId: targetSessionId, axis: axis, newSession: newSession)
            if newFirst != first || newSecond != second {
                return .split(id: UUID(), axis: currentAxis, fraction: fraction, first: newFirst, second: newSecond)
            }
            return self
        }
    }

    public func remove(sessionId: UUID) -> PaneNode? {
        switch self {
        case .terminal(let s):
            if s.id == sessionId {
                return nil
            }
            return self
        case .split(let id, let axis, let fraction, let first, let second):
            let newFirst = first.remove(sessionId: sessionId)
            let newSecond = second.remove(sessionId: sessionId)
            if let newFirst, let newSecond {
                if newFirst != first || newSecond != second {
                    return .split(id: UUID(), axis: axis, fraction: fraction, first: newFirst, second: newSecond)
                }
                return self
            } else if let newFirst {
                return newFirst
            } else if let newSecond {
                return newSecond
            } else {
                return nil
            }
        }
    }

    public func updatingFraction(splitId: UUID, fraction: CGFloat) -> PaneNode {
        switch self {
        case .terminal:
            return self
        case .split(let id, let axis, let currentFraction, let first, let second):
            if id == splitId {
                let clamped = min(max(fraction, 0.05), 0.95)
                return .split(id: id, axis: axis, fraction: clamped, first: first, second: second)
            }
            let newFirst = first.updatingFraction(splitId: splitId, fraction: fraction)
            let newSecond = second.updatingFraction(splitId: splitId, fraction: fraction)
            if newFirst != first || newSecond != second {
                return .split(id: id, axis: axis, fraction: currentFraction, first: newFirst, second: newSecond)
            }
            return self
        }
    }

    public func equalized() -> PaneNode {
        switch self {
        case .terminal:
            return self
        case .split(let id, let axis, _, let first, let second):
            return .split(id: id, axis: axis, fraction: 0.5, first: first.equalized(), second: second.equalized())
        }
    }
}

// MARK: - SuqiTab (标签页)

@MainActor
public final class SuqiTab: ObservableObject, Identifiable {
    public let id: UUID
    @Published public var rootPane: PaneNode
    @Published public var activeSessionId: UUID
    /// Monotonically increasing counter — forces SwiftUI to see pane tree mutations
    @Published public var paneVersion: Int = 0

    public init(session: SuqiTerminalSession) {
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

    public var displayPathFormatted: String {
        activeSession?.displayPathFormatted ?? "~"
    }

    public var activeSession: SuqiTerminalSession? {
        rootPane.findSession(id: activeSessionId) ?? rootPane.allSessions.first
    }

    public var allSessions: [SuqiTerminalSession] {
        rootPane.allSessions
    }

    public func splitActive(axis: Axis, newSession: SuqiTerminalSession) {
        let targetId = (rootPane.findSession(id: activeSessionId) != nil)
            ? activeSessionId
            : (rootPane.allSessions.first?.id ?? activeSessionId)
        rootPane = rootPane.split(targetSessionId: targetId, axis: axis, newSession: newSession)
        activeSessionId = newSession.id
        paneVersion += 1
    }

    public func closeSession(id: UUID) -> Bool {
        if let newRoot = rootPane.remove(sessionId: id) {
            rootPane = newRoot
            if activeSessionId == id {
                activeSessionId = rootPane.allSessions.first?.id ?? UUID()
            }
            paneVersion += 1
            return true
        }
        return false
    }

    public func updateSplitFraction(splitId: UUID, fraction: CGFloat) {
        rootPane = rootPane.updatingFraction(splitId: splitId, fraction: fraction)
    }

    public func equalizeSplits() {
        rootPane = rootPane.equalized()
        paneVersion += 1
    }
}

// MARK: - SuqiWindowModel (单窗口独立状态模型)

@MainActor
public final class SuqiWindowModel: ObservableObject {
    @Published public private(set) var tabs: [SuqiTab] = []
    @Published public var activeTabId: UUID?

    /// 窗口关闭回调
    public var onCloseWindowRequested: (() -> Void)?

    public var sessions: [SuqiTerminalSession] {
        tabs.flatMap { $0.allSessions }
    }

    public var activeTab: SuqiTab? {
        guard let activeTabId else { return tabs.first }
        return tabs.first { $0.id == activeTabId } ?? tabs.first
    }

    public var activeSession: SuqiTerminalSession? {
        activeTab?.activeSession
    }

    public var activeSessionId: UUID? {
        get { activeTab?.activeSessionId }
        set {
            if let val = newValue {
                activeTab?.activeSessionId = val
            }
        }
    }

    public var activeIndex: Int {
        guard let activeTabId else { return 0 }
        return tabs.firstIndex { $0.id == activeTabId } ?? 0
    }

    public init(initialWorkingDirectory: String? = nil) {
        let dir = initialWorkingDirectory ?? NSHomeDirectory()
        let session = SuqiTerminalSession(workingDirectory: dir)
        let tab = SuqiTab(session: session)
        self.tabs = [tab]
        self.activeTabId = tab.id
        attachSessionCallbacks(session)
    }

    private func attachSessionCallbacks(_ session: SuqiTerminalSession) {
        session.onFocused = { [weak self, weak session] in
            guard let self, let session else { return }
            self.selectSession(id: session.id)
        }
    }

    // ⌘T: 新建标签页 (自动继承当前活跃会话的工作目录)
    @discardableResult
    public func createNewTab(workingDirectory: String? = nil) -> SuqiTerminalSession {
        objectWillChange.send()
        let initialDir = workingDirectory ?? activeSession?.fullDirectory ?? NSHomeDirectory()
        let session = SuqiTerminalSession(workingDirectory: initialDir)
        attachSessionCallbacks(session)
        let tab = SuqiTab(session: session)
        tabs.append(tab)
        activeTabId = tab.id
        return session
    }

    // ⌘D: 垂直分屏新建 (Split Right，左右分屏)
    @discardableResult
    public func splitRight(workingDirectory: String? = nil) -> SuqiTerminalSession {
        splitActivePane(axis: .horizontal, workingDirectory: workingDirectory)
    }

    // ⌘Shift+D: 水平分屏新建 (Split Down，上下分屏)
    @discardableResult
    public func splitDown(workingDirectory: String? = nil) -> SuqiTerminalSession {
        splitActivePane(axis: .vertical, workingDirectory: workingDirectory)
    }

    @discardableResult
    public func splitActivePane(axis: Axis, workingDirectory: String? = nil) -> SuqiTerminalSession {
        objectWillChange.send()
        let initialDir = workingDirectory ?? activeSession?.fullDirectory ?? NSHomeDirectory()
        let session = SuqiTerminalSession(workingDirectory: initialDir)
        attachSessionCallbacks(session)

        if let currentTab = activeTab {
            currentTab.objectWillChange.send()
            currentTab.splitActive(axis: axis, newSession: session)
        } else {
            let tab = SuqiTab(session: session)
            tabs.append(tab)
            activeTabId = tab.id
        }
        return session
    }

    // ⌘W: 优先关闭当前活跃分屏；窗格全关后关闭标签页；若为最后标签页，通知关闭窗口
    @discardableResult
    public func closeActiveSession() -> Bool {
        objectWillChange.send()
        guard let currentTab = activeTab else {
            onCloseWindowRequested?()
            return false
        }

        currentTab.objectWillChange.send()
        let currentSessionId = currentTab.activeSessionId
        let hasPanesRemaining = currentTab.closeSession(id: currentSessionId)

        if !hasPanesRemaining {
            return closeTab(id: currentTab.id)
        }
        return true
    }

    @discardableResult
    public func closeTab(id: UUID) -> Bool {
        objectWillChange.send()
        guard tabs.count > 1 else {
            // 当前窗口最后一个 Tab 已被关闭，通知关闭此独立窗口！
            onCloseWindowRequested?()
            return false
        }

        if let index = tabs.firstIndex(where: { $0.id == id }) {
            tabs.remove(at: index)
            if activeTabId == id {
                let newIndex = max(0, min(index, tabs.count - 1))
                activeTabId = tabs[newIndex].id
            }
        }
        return true
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

    public func updateSplitFraction(splitId: UUID, fraction: CGFloat) {
        activeTab?.updateSplitFraction(splitId: splitId, fraction: fraction)
    }

    public func equalizeSplits() {
        activeTab?.equalizeSplits()
    }
}
