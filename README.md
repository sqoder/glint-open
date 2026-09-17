# Glint (macOS)

<p align="center">
  <img src="assets/logo.png" width="128" height="128" alt="Glint Logo" />
</p>

<p align="center">
  <strong>专为 macOS 深度打造的次世代原生生产力工具箱</strong>
  <br />
  <em>Next-Gen Native macOS Productivity Workstation</em>
</p>

<p align="center">
  <a href="#-dmg-安装包下载--download">DMG 下载</a> •
  <a href="#-核心特性--features">核心功能</a> •
  <a href="#-快捷键指引--shortcuts">快捷键</a> •
  <a href="#-隐私与安全说明--privacy--security">隐私与安全</a> •
  <a href="#-常见问题--faq">常见问题</a>
</p>

---

## 📥 DMG 安装包下载 / Download

Glint 现已发布最新版本，免去源码编译，开箱即用：

| 平台 | 架构 | 系统要求 | 下载链接 |
|---|---|---|---|
| **macOS** | Universal (Apple Silicon / Intel) | macOS 14.0 (Sonoma) 及以上 | [**下载 Glint.dmg (v0.0.341)**](./Glint.dmg) |

### 安装方法
1. 点击并下载仓库中的 [**`Glint.dmg`**](./Glint.dmg)；
2. 双击打开 `Glint.dmg`，将 **`Glint.app`** 拖拽至 **`Applications`**（应用程序）文件夹；
3. 打开 Launchpad 或访达中的 `Glint` 即可启动。

### 首次运行权限配置
由于 Glint 深度集成了屏幕截图、录屏声音内录、全局快捷键与语音听写能力，初次启动时请根据系统提示在 **系统设置 → 隐私与安全性** 中授予以下权限：
- **屏幕录制 (Screen Recording)**：用于截图、录屏与 OCR 取词。
- **辅助功能 (Accessibility)**：用于全局快捷键与无感模拟粘贴。
- **麦克风 (Microphone)**：用于语音听写与录屏声音采集。

---

## ✨ 核心特性 / Features

### 1. 📸 智能截图与屏幕录制 (Capture & Recording)
- **智能吸附与像素放大镜**：拖拽选区亚像素对齐，实时呈现放大镜与 RGB / HEX 拾色器。
- **12+ 种专业标注工具**：矩形、椭圆、高亮笔、画笔、智能箭头、自增步骤序号、马赛克、高斯模糊、聚光灯遮罩等。
- **智能长截图 (Scroll Capture)**：平滑滚动自动注入与图像亚像素拼接，一键抓取完整长网页、代码与聊天记录。
- **高性能录屏与实时标注**：支持系统声音内录 + 麦克风录音，支持实时悬浮画笔涂鸦，支持一键导出高清 GIF。
- **隐私自动脱敏 (Auto Redact)**：离线 Vision OCR 结合正则引擎，一键智能识别并模糊手机号、身份证、银行卡、API Key 等敏感隐私。
- **一键置顶贴图 (Pin on Screen)**：截图即刻钉在屏幕最上层，支持透明度调整、缩放与多桌面悬浮。
- **截图美化**：内置自适应渐变衬底、液态毛玻璃、超大圆角与柔和弥散阴影。

### 2. 🏝️ 物理刘海与灵动岛面板 (Dynamic Island & Atoll Hub)
- **原生贴合硬件刘海**：支持 MacBook Pro 物理硬件刘海与外接屏幕胶囊形态，支持纯黑与 Metal Shader 液态玻璃材质。
- **实时音乐实况**：实时同步网易云音乐、QQ音乐、Spotify、Apple Music 歌名、专辑封面、动态律动声波与切歌控制。
- **全屏应用智能感知**：在全屏应用、游戏或视频播放时自动隐藏刘海，鼠标轻触屏幕顶端平滑渐显，离开后优雅回缩。
- **Atoll 效率组件库**：
  - **应用启动器 (Apps Grid)**：快速聚合呼出常用工具。
  - **日历与今日日程 (Calendar)**：一览待办与系统日历。
  - **实时天气 (Weather)**：气温、天气状况与趋势预测。
  - **Ghostty 原生终端 (Terminal)**：内嵌 Ghostty GPU 终端内核，刘海下拉即出命令行。
  - **防休眠神器 (Caffeine)**：基于 IOKit 电源断言，一键阻止 Mac 息屏睡眠。
  - **随手便签 (Notes)**：轻量速记，数据实时本地落盘。

### 3. 🎙️ 语音听写与语体智能润色 (Voice & Dictation)
- **三引擎智能适配**：SenseVoice 离线低延迟模型 / Apple Speech 本地识别 / Whisper 云端转写。
- **前台 App 语体自适应 (Per-App Auto Tone)**：自动感知前台应用（Xcode / VS Code / Cursor 自动切换代码风格，飞书 / 邮件切换公文风格，日常聊天切换口语）。
- **口头禅与语气词清洗**：智能剔除口语赘字，保留精确专业书面意图。
- **无感光标注入**：剪贴板状态深度保护，光标所在处一键安全精准输入。

### 4. 🌐 屏幕取词翻译 (Translate)
- **原位覆盖翻译**：划选屏幕区域后自动 OCR 并把译文贴回原图对应坐标。
- **多翻译引擎自由接入**：支持 DeepL / OpenAI 兼容接口 / Google / 百度 / 有道 等服务商。

### 5. 📋 剪贴板历史管理 (Clipboard History)
- **多模态分类归档**：富文本、高清截图、代码片段、色彩 HEX、URL 自动识别归类。
- **超大容量与自动淘汰**：最高支持 500 条历史缓存，未置顶记录支持自定义保留周期。

---

## ⌨️ 常用快捷键指引 / Shortcuts

| 功能 | 默认快捷键 | 说明 |
|---|---|---|
| **区域截图** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>A</kbd> | 唤起全功能截图标注遮罩 |
| **一键全屏截图** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>1</kbd> | 立即截取全屏并复制到剪贴板 |
| **活动窗口截图** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>2</kbd> | 自动识别并截取当前活动窗口 |
| **屏幕录制** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>R</kbd> | 开启区域或全屏录像（支持内录音频） |
| **长截图** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>L</kbd> | 启动滚动拼接长截图 |
| **屏幕取词翻译** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>T</kbd> | 框选区域 OCR 并原地翻译 |
| **语音听写** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>D</kbd> | 按住或单击唤起听写悬浮实况卡 |
| **展开/收起灵动岛** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>N</kbd> | 展开刘海面板 (或直接点击屏幕顶端刘海) |
| **剪贴板历史** | <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>V</kbd> | 呼出历史剪贴板悬浮面板 |
| **偏好设置** | <kbd>⌘</kbd> <kbd>,</kbd> | 打开全功能自定义设置中心 |

*所有快捷键均可在应用内「设置 → 快捷键」中进行个性化修改。*

---

## 🔒 隐私与安全性 / Privacy & Security

- **无网络遥测**：不收集任何用户使用数据、屏幕数据或隐私记录。
- **离线优先**：OCR 文字识别、长截图算法、隐私脱敏、剪贴板管理与防休眠全部在本地 CPU / GPU 完成。
- **安全加密存储**：所有用户自填的第三方 API 密钥均安全存放在 macOS 系统的 Keychain 钥匙串中。

---

## ❓ 常见问题 / FAQ

### Q1: 打开时提示"已损坏，无法打开"？
这是 macOS 对未上架 App Store 应用的 Gatekeeper 拦截机制。在终端执行以下命令即可正常打开：
```bash
sudo xattr -rd com.apple.quarantine /Applications/Glint.app
```

### Q2: 为什么截图是黑屏或提示权限拒绝？
打开 **系统设置 → 隐私与安全性 → 屏幕录制**，找到 `Glint`，先关闭再重新打开开关即可刷新 TCC 权限缓存。
