//
//  SiqiTerminalSession.swift
//  siqi
//
//  Created for siqi Terminal.
//

import Foundation
import SwiftUI
import GhosttyTerminal
import GhosttyTheme

@MainActor
public final class SiqiTerminalSession: ObservableObject, Identifiable {
    public let id: UUID
    public let createdAt: Date

    @Published public private(set) var state: TerminalViewState
    @Published public var customTitle: String?
    public var initialWorkingDirectory: String

    public init(id: UUID = UUID(), workingDirectory: String? = nil) {
        self.id = id
        self.createdAt = Date()
        let initialDir = workingDirectory ?? NSHomeDirectory()
        self.initialWorkingDirectory = initialDir
        self.state = Self.buildTerminalViewState(workingDirectory: initialDir)
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

    public var fullDirectory: String {
        state.workingDirectory ?? initialWorkingDirectory
    }

    public func restart() {
        let currentCwd = state.workingDirectory ?? initialWorkingDirectory
        self.state = Self.buildTerminalViewState(workingDirectory: currentCwd)
    }

    public func send(_ text: String) {
        state.send(text)
    }

    public func clearScreen() {
        state.send("clear\n")
    }

    public static func buildTerminalViewState(workingDirectory: String) -> TerminalViewState {
        let settings = SiqiSettings.shared
        let theme = GhosttyThemeCatalog.theme(named: settings.themeName)?.toTerminalTheme() ?? .default

        let cursorStyle: TerminalCursorStyle
        switch settings.cursorStyle {
        case "block":
            cursorStyle = .block
        case "underline":
            cursorStyle = .underline
        default:
            cursorStyle = .bar
        }

        let config = TerminalConfiguration { builder in
            builder.withFontSize(Float(settings.fontSize))
            builder.withFontFamily(settings.fontFamily)
            builder.withCursorStyle(cursorStyle)
            builder.withCursorStyleBlink(settings.cursorBlink)
            builder.withBackgroundOpacity(settings.backgroundOpacity)
            builder.withWindowPaddingX(14)
            builder.withWindowPaddingY(12)
            builder.withCustom("window-padding-balance", "true")
            builder.withCustom("window-padding-color", "extend")
        }

        let viewState = TerminalViewState(
            configSource: .none,
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
                "TERM_PROGRAM": "siqi",
                "TERM_PROGRAM_VERSION": "0.1.0"
            ]
        )

        return viewState
    }
}
