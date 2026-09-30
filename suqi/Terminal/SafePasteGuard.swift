//
//  SafePasteGuard.swift
//  suqi
//
//  Created for suqi Terminal.
//

import Foundation

public struct SafePasteRequest: Identifiable {
    public let id = UUID()
    public let text: String
    public let lineCount: Int
    public let isDangerous: Bool
    public let reason: String

    public init(text: String, lineCount: Int, isDangerous: Bool, reason: String) {
        self.text = text
        self.lineCount = lineCount
        self.isDangerous = isDangerous
        self.reason = reason
    }
}

public enum SafePasteGuard {
    private static let dangerousPatterns: [(NSRegularExpression, String)] = [
        (try! NSRegularExpression(pattern: #"\brm\s+-[a-zA-Z]*[rf][a-zA-Z]*\b"#, options: [.caseInsensitive]), "高危删除命令 (rm -rf)"),
        (try! NSRegularExpression(pattern: #"\bsudo\s+rm\b"#, options: [.caseInsensitive]), "Root权限删除命令 (sudo rm)"),
        (try! NSRegularExpression(pattern: #"\bmkfs\b"#, options: [.caseInsensitive]), "磁盘格式化命令 (mkfs)"),
        (try! NSRegularExpression(pattern: #"\bdd\s+if="#, options: [.caseInsensitive]), "底层磁盘覆写命令 (dd)"),
        (try! NSRegularExpression(pattern: #":\(\)\s*\{\s*:\|:&\s*\};:"#, options: []), "Fork 炸弹"),
        (try! NSRegularExpression(pattern: #"\b(curl|wget)\s+.*\|\s*(sh|bash|zsh)\b"#, options: [.caseInsensitive]), "远程脚本管道执行 (curl | bash)"),
        (try! NSRegularExpression(pattern: #">\s*/dev/(sd[a-z]|nvme[0-9])"#, options: [.caseInsensitive]), "直接覆写物理磁盘块设备")
    ]

    public static func evaluate(text: String) -> SafePasteRequest? {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        // Check dangerous command patterns
        for (regex, description) in dangerousPatterns {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return SafePasteRequest(
                    text: text,
                    lineCount: max(1, lines.count),
                    isDangerous: true,
                    reason: "检测到\(description)，可能对系统产生不可逆影响"
                )
            }
        }

        return nil
    }
}
