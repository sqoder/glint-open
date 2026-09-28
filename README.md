# siqi 桌面终端

> 基于 Ghostty Metal GPU 硬件加速渲染内核与现代 macOS 液态毛玻璃美学的极速、轻量桌面终端。

---

## 🌟 核心特性

- ⚡️ **Metal GPU 极速渲染**：内嵌 `libghostty-spm`（GhosttyTerminal 引擎），带来 120 FPS 丝滑刷新率与极低输入延迟。
- 🧊 **深色微透毛玻璃质感**：原生 `NSVisualEffectView` 配合沉浸式标题栏与窗口微光轮廓，支持自由调节背景浓度。
- 🗂 **多标签页 (Tabs) 支持**：随时通过 `⌘T` 新建标签、`⌘W` 关闭标签、`⇧⌘[` 与 `⇧⌘]` 快速切换会话。
- ⌨️ **系统级原生中文/CJK 输入法完美适配**：针对 Ghostty 原生 IME window level 进行修复，彻底杜绝候选词弹窗被遮挡问题。
- 🎨 **开箱即用丰富配色**：内置 Tokyo Night、Catppuccin、Dracula、Nord、One Dark 等经典主题，并支持字号即时缩放。
- 🧱 **极简易扩展**：代码结构清晰紧凑，易于在此基础上逐步叠加专属功能（如 Quake 下拉刘海模式、AI 辅助行、分屏、会话持久化等）。

---

## ⌨️ 常用快捷键

| 快捷键 | 功能 |
|---|---|
| `⌘ T` | 新建终端标签页 |
| `⌘ W` | 关闭当前标签页 |
| `⌘ N` | 呼出/激活终端窗口 |
| `⌘ K` | 清屏 (`clear`) |
| `⌘ R` | 重启当前终端会话 |
| `⇧ ⌘ [` | 切换到上一个标签页 |
| `⇧ ⌘ ]` | 切换到下一个标签页 |
| `⌘ +` | 放大终端字体 |
| `⌘ -` | 缩小终端字体 |
| `⌘ 0` | 恢复默认字体大小 |

---

## 🛠 构建与运行

工程使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 规范化管理：

```bash
# 1. 生成 siqi.xcodeproj
xcodegen generate

# 2. 编译调试
xcodebuild -project siqi.xcodeproj -scheme siqi -configuration Debug build
```

也可以直接在 Xcode 中双击打开 `siqi.xcodeproj` 进行运行与调试。
