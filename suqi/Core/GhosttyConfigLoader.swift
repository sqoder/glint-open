//
//  GhosttyConfigLoader.swift
//  suqi
//
//  Created for suqi Terminal.
//

import Foundation
import SwiftUI
import AppKit

public struct GhosttyUserConfig: Sendable {
    public var themeName: String = "Catppuccin Mocha"
    public var fontFamily: String = "Maple Mono NF"
    public var fontSize: Double = 13.0
    public var fontThicken: Bool = true
    public var backgroundOpacity: Double = 0.60
    public var backgroundBlur: Int = 20
    public var windowPaddingX: Int = 12
    public var windowPaddingY: Int = 8
    public var cursorStyle: String = "bar"
    public var cursorBlink: Bool = true
    public var copyOnSelect: Bool = true
    public var adjustCellHeight: Int = 0
    public var macosTitlebarStyle: String = "tabs"
    public var shellIntegration: String = "zsh"
    public var windowSaveState: String = "always"
    public var windowWidth: Int? = nil
    public var windowHeight: Int? = nil

    public static func load() -> (config: GhosttyUserConfig, filePath: String?) {
        let ghosttyPath = NSString(string: "~/.config/ghostty/config").expandingTildeInPath
        let suqiPath = NSString(string: "~/.config/suqi/config").expandingTildeInPath

        let targetPath: String? = {
            if FileManager.default.fileExists(atPath: suqiPath) {
                return suqiPath
            } else if FileManager.default.fileExists(atPath: ghosttyPath) {
                return ghosttyPath
            }
            return nil
        }()

        var cfg = GhosttyUserConfig()
        guard let path = targetPath, let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return (cfg, nil)
        }

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            let key = parts[0]
            let val = parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"\'"))

            switch key {
            case "theme":
                cfg.themeName = val
            case "font-family":
                cfg.fontFamily = val
            case "font-size":
                if let v = Double(val) { cfg.fontSize = v }
            case "font-thicken":
                cfg.fontThicken = (val.lowercased() == "true")
            case "adjust-cell-height":
                if let v = Int(val) { cfg.adjustCellHeight = v }
            case "background-opacity":
                if let v = Double(val) { cfg.backgroundOpacity = v }
            case "background-blur":
                if let v = Int(val) { cfg.backgroundBlur = v }
                else if val.lowercased() == "true" { cfg.backgroundBlur = 20 }
            case "window-padding-x":
                if let v = Int(val) { cfg.windowPaddingX = v }
            case "window-padding-y":
                if let v = Int(val) { cfg.windowPaddingY = v }
            case "macos-titlebar-style":
                cfg.macosTitlebarStyle = val
            case "window-save-state":
                cfg.windowSaveState = val
            case "window-width":
                if let v = Int(val) { cfg.windowWidth = v }
            case "window-height":
                if let v = Int(val) { cfg.windowHeight = v }
            case "cursor-style":
                cfg.cursorStyle = val
            case "cursor-style-blink":
                cfg.cursorBlink = (val.lowercased() == "true")
            case "copy-on-select":
                cfg.copyOnSelect = (val.lowercased() == "clipboard" || val.lowercased() == "true")
            case "shell-integration":
                cfg.shellIntegration = val
            default:
                break
            }
        }

        return (cfg, targetPath)
    }
}

extension Notification.Name {
    public static let ghosttyConfigDidChange = Notification.Name("GhosttyConfigDidChange")
}

// MARK: - 配置文件热重载监听器 (自动监控 ~/.config/ghostty/config 或 ~/.config/suqi/config 变动)

@MainActor
public final class GhosttyConfigFileWatcher: ObservableObject {
    public static let shared = GhosttyConfigFileWatcher()

    private var fileSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1

    public init() {
        startWatching()
    }

    public func startWatching() {
        stopWatching()

        let (_, resolvedPath) = GhosttyUserConfig.load()
        guard let path = resolvedPath else { return }

        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            NotificationCenter.default.post(name: .ghosttyConfigDidChange, object: nil)
            // 重新挂载监控（兼容 Vim/VSCode 等编辑器的原子重命名写入机制）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.startWatching()
            }
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
            }
        }

        source.resume()
        self.fileSource = source
    }

    public func stopWatching() {
        fileSource?.cancel()
        fileSource = nil
        fileDescriptor = -1
    }
}
