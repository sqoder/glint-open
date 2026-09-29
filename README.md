# suqi (素气) 桌面终端 · v0.0.1

> 基于 Ghostty Metal GPU 硬件加速核心，视觉极致干净纯粹，彻底解决 Ghostty 痛点——直接用 `⌘V` (Cmd+V) 一键粘贴图片到 AI 命令行（Codex / agy / Claude Code）的独立 macOS 桌面终端。

---

## 🌟 核心特性与设计哲学

- ⚡️ **Ghostty Metal GPU 硬件加速基石**：内嵌 `libghostty-spm`（GhosttyTerminal 渲染内核），120 FPS 极速刷新率与亚毫秒级输入响应，全功能终端协议支持。
- 🖼 **彻底解决 Ghostty 图片粘贴痛点**：原生 Ghostty 在按下 `⌘V` 时仅读取文本，图片直接静默失效；**suqi** 深度桥接 macOS 系统剪贴板与现代 AI 终端工具协议，按下 `⌘V` 时自动识别系统截图、剪贴板图像或 Finder 图片文件，无缝转化为 `Control+V` 事件发送到 PTY。在 **Codex**、**agy (Google Antigravity CLI)**、**Claude Code** 中一键附带多模态图片！
- 🪟 **极致干净纯粹的视觉美学**：
  - 彻底消灭普通终端的割裂感与多余边框、横线与状态栏。
  - 支持实心纯色（如 `#2F343F`）与全幅毛玻璃背景，完美适配浅色/深色系统与 Ghostty 主题底色。
  - 红绿灯呼吸下移，告别紧绷贴顶感；单标签页时隐去所有冗余 UI，多标签页时展示极简无边框 Tab。
- 🗂 **灵活的多标签与分屏 (Tabs & Splits)**：
  - `⌘T` 新建标签页，支持鼠标拖拽换序。
  - `⌘D` 垂直分屏 (Split Right)，`⇧⌘D` 水平分屏 (Split Down)。
  - `⌃⌘H/J/K/L` 或 `⌃⌘方向键`：空间方位精准跳转分屏；`⌃⌘=` 均等所有分屏。
  - `⇧⌘Enter`：分屏最大化临时聚焦 (Split Zoom)。
  - 8pt 宽幅舒适手感分屏分割条，鼠标轻推即可自由拖拉调整宽高。
- 🔍 **终端回滚快速搜索 (`⌘F`)**：内置极简匹配搜索浮窗，快速查找过滤海量终端日志。
- 🛸 **随叫随到下拉终端 (Quick Terminal · `⌃\``)**：支持全局热键一键从屏幕顶部平滑呼出/隐藏。
- ⚙️ **无缝兼容 Ghostty 生态配置**：开箱即读 `~/.config/suqi/config` 或用户的 `~/.config/ghostty/config`，实时热重载。
- ⌨️ **系统级原生中文/CJK 输入法完美适配**：针对 Ghostty 原生 IME window level 进行底层修复，彻底杜绝输入法候选词浮窗被终端窗口遮挡问题。

---

## ⌨️ 常用快捷键

| 快捷键 | 功能 | 说明 |
|---|---|---|
| `⌘ V` | **智能粘贴（图片/文本）** | 剪贴板有图片时直达 AI 命令行 (Codex / agy / Claude Code) |
| `⌘ C` | 复制选中内容 | 快速复制终端选中文本 |
| `⌘ A` | 全选屏幕内容 | 快捷全选终端文本 |
| `⌘ F` | 终端内容查找 | 唤起快速搜索条并高亮匹配项 |
| `⌘ D` | 垂直分屏 (Split Right) | 左右分屏同时对照 |
| `⇧ ⌘ D` | 水平分屏 (Split Down) | 上下分屏同时查看 |
| `⇧ ⌘ ↩` | 分屏最大化聚焦 (Zoom) | 临时全屏单个窗格，再次按下还原 |
| `⌃ ⌘ =` | 均等所有分屏 (Equalize) | 均分当前所有窗格宽高 |
| `⌃ ⌘ H/J/K/L` | 空间几何定向聚焦 | 精准跳到指定方位的分屏 |
| `⌥ ⌘ ←` / `⌥ ⌘ →` | 切换分屏窗格 | 焦点快速轮转 |
| `⌘ T` | 新建终端标签页 | 快速开辟新上下文 |
| `⌘ W` | 关闭分屏/标签页 | 优先关闭当前窗格，全关后关闭标签 |
| `⌘ 1` ~ `⌘ 9` | 快速直达指定标签 | 精确 Tab 切换 |
| `⇧ ⌘ [` / `⇧ ⌘ ]` | 切换上一个/下一个标签 | 顺滑循环切页 |
| `⌃ \`` | 下拉浮动终端 (Quick Terminal) | 类似 Guake / iTerm 随叫随到呼出 |
| `⌘ K` | 清屏 (`clear`) | 快速恢复清爽界面 |
| `⌘ +` / `⌘ -` / `⌘ 0` | 字号放大 / 缩小 / 恢复 | 实时无损缩放渲染 |
| `⇧ ⌘ ,` | 热重载配置 | 重新加载 Ghostty / suqi 配置文件 |

---

## 🛠 构建与运行

工程使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 规范化管理：

```bash
# 1. 生成 suqi.xcodeproj
xcodegen generate

# 2. 编译调试
xcodebuild -project suqi.xcodeproj -scheme suqi -configuration Release build
```

或者直接双击打开 `suqi.xcodeproj` 在 Xcode 中运行与调试。

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 开源。
