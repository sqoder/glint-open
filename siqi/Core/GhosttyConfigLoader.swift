//
//  GhosttyConfigLoader.swift
//  siqi
//
//  Created for siqi Terminal.
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

    public static func load() -> (config: GhosttyUserConfig, filePath: String?) {
        let ghosttyPath = NSString(string: "~/.config/ghostty/config").expandingTildeInPath
        let siqiPath = NSString(string: "~/.config/siqi/config").expandingTildeInPath

        let targetPath: String? = {
            if FileManager.default.fileExists(atPath: siqiPath) {
                return siqiPath
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
