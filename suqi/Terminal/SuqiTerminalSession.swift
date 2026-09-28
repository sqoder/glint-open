//
//  SuqiTerminalSession.swift
//  suqi
//
//  Created for suqi Terminal.
//

import Foundation
import SwiftUI
import Combine
import GhosttyTerminal
import GhosttyTheme

@MainActor
public final class SuqiTerminalSession: ObservableObject, Identifiable, Equatable {
    public let id: UUID
    public let createdAt: Date

    @Published public private(set) var state: TerminalViewState
    @Published public var customTitle: String?
    public var initialWorkingDirectory: String
    public var onFocused: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()

    public static func == (lhs: SuqiTerminalSession, rhs: SuqiTerminalSession) -> Bool {
        lhs.id == rhs.id
    }

    public init(id: UUID = UUID(), workingDirectory: String? = nil) {
        self.id = id
        self.createdAt = Date()
        let initialDir = workingDirectory ?? NSHomeDirectory()
        self.initialWorkingDirectory = initialDir
        self.state = Self.buildTerminalViewState(workingDirectory: initialDir)
        bindState()
    }

    private func bindState() {
        cancellables.removeAll()
        state.$isFocused
            .filter { $0 }
            .sink { [weak self] _ in
                guard let self else { return }
                self.onFocused?()
            }
            .store(in: &cancellables)
        state.$workingDirectory
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        state.$title
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    public var title: String {
        if let customTitle, !customTitle.isEmpty {
            return customTitle
        }
        if !state.title.isEmpty {
            return state.title
        }
        return "zsh"
    }

    public var displayDirectory: String {
        if let cwd = state.workingDirectory, !cwd.isEmpty {
            if cwd == NSHomeDirectory() {
                return "~"
            }
            return URL(fileURLWithPath: cwd).lastPathComponent
        }
        if initialWorkingDirectory == NSHomeDirectory() {
            return "~"
        }
        return URL(fileURLWithPath: initialWorkingDirectory).lastPathComponent
    }

    public var displayPathFormatted: String {
        let full = fullDirectory
        let home = NSHomeDirectory()
        if full == home {
            return "~"
        }
        if full.hasPrefix(home + "/") {
            return "~" + full.dropFirst(home.count)
        }
        return full
    }

    public var fullDirectory: String {
        state.workingDirectory ?? initialWorkingDirectory
    }

    public func restart() {
        let currentCwd = state.workingDirectory ?? initialWorkingDirectory
        self.state = Self.buildTerminalViewState(workingDirectory: currentCwd)
        bindState()
    }

    public func send(_ text: String) {
        state.send(text)
    }

    public func clearScreen() {
        state.send("clear\n")
    }

    public static func buildTerminalViewState(workingDirectory: String) -> TerminalViewState {
        let (userConfig, resolvedPath) = GhosttyUserConfig.load()
        let theme = GhosttyThemeCatalog.theme(named: userConfig.themeName)?.toTerminalTheme() ?? .default

        let cursorStyle: TerminalCursorStyle
        switch userConfig.cursorStyle {
        case "block":
            cursorStyle = .block
        case "underline":
            cursorStyle = .underline
        default:
            cursorStyle = .bar
        }

        let config = TerminalConfiguration { builder in
            builder.withFontSize(Float(userConfig.fontSize))
            builder.withFontFamily(userConfig.fontFamily)
            builder.withCursorStyle(cursorStyle)
            builder.withCursorStyleBlink(userConfig.cursorBlink)
            // 将终端内部画布底色透明度设为 0，由 ContentView 全幅毛玻璃+主题底色统一提供，杜绝分层与色差
            builder.withBackgroundOpacity(0)
            builder.withWindowPaddingX(userConfig.windowPaddingX)
            builder.withWindowPaddingY(userConfig.windowPaddingY)
            // 关键修复：关闭 window-padding-balance，确保终端顶部内边距严格锚定固定值；
            // 彻底消除窗口拉伸缩放或分屏时，因行距余数均分导致的顶部命令提示符(Prompt)垂直跳动与抖动闪烁
            builder.withCustom("window-padding-balance", "false")
            builder.withCustom("window-padding-color", "extend")
            if userConfig.adjustCellHeight != 0 {
                builder.withCustom("adjust-cell-height", "\(userConfig.adjustCellHeight)")
            }
            if userConfig.fontThicken {
                builder.withCustom("font-thicken", "true")
            }
            if userConfig.copyOnSelect {
                builder.withCustom("copy-on-select", "clipboard")
            }
            builder.withCustom("keybind", "super+c=copy_to_clipboard")
            builder.withCustom("keybind", "super+a=select_all")
        }

        let configSource: TerminalController.ConfigSource = {
            if let resolvedPath {
                return .file(resolvedPath)
            }
            return .none
        }()

        let viewState = TerminalViewState(
            configSource: configSource,
            theme: theme,
            terminalConfiguration: config
        )

        let resolvedDir = FileManager.default.fileExists(atPath: workingDirectory)
            ? workingDirectory
            : NSHomeDirectory()

        viewState.configuration = TerminalSurfaceOptions(
            backend: .exec,
            workingDirectory: resolvedDir,
            envVars: [
                "TERM_PROGRAM": "ghostty",
                "TERM_PROGRAM_VERSION": "1.3.1"
            ]
        )

        return viewState
    }
}
