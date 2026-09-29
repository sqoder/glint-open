# suqi · GPU-Accelerated macOS Terminal

<p align="center">
  <img src="suqi/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="suqi icon" />
</p>

<p align="center">
  <b>A minimalist, ultra-fast macOS desktop terminal powered by Ghostty's Metal GPU engine.</b><br>
  Built specifically for modern developers and AI CLI workflows with seamless <code>⌘V</code> multimodal image pasting.
</p>

---

## Overview

**suqi** is an elegant, high-performance terminal emulator for macOS. Built with SwiftUI and powered by the Ghostty Metal GPU rendering core (`libghostty-spm`), `suqi` delivers 120 FPS buttery-smooth rendering, sub-millisecond keystroke latency, and a distraction-free aesthetic.

While modern AI command-line assistants—such as **Google Antigravity CLI (`agy`)**, **OpenAI Codex CLI**, **Claude Code**, and **OpenCode**—support multimodal image reasoning, standard terminal emulators silently drop non-text clipboard data when pressing `⌘V`. **suqi** bridges the macOS system clipboard directly into the terminal stream, enabling one-click image uploads right inside your AI CLI sessions.

---

## ✨ Key Features

### 🚀 Ghostty Metal GPU Core
- Embedded `libghostty-spm` (GhosttyTerminal) rendering engine.
- 120 FPS display refresh rate, hardware-accelerated text rasterization, and sub-millisecond input responsiveness.
- Complete modern terminal protocol support (TrueColor 24-bit RGB, kitty graphics protocol, SGR mouse tracking, bracketed paste, OSC 52 clipboard).

### 🖼 Seamless Image & File Pasting (`⌘V`)
- **Multimodal AI CLI Ready**: Automatically detects raw memory images (system screenshots, browser copies) and Finder image files on `⌘V`, converting them into terminal-compatible input sequences for **`agy`**, **`codex`**, **`claude`**, and other AI tools.
- **Smart Path Pasting**: Dragging or pasting Finder files automatically escapes paths for immediate shell execution.

### 🪟 Clean, Distraction-Free Aesthetic
- Completely borderless, seamless workspace with no ugly dividers or heavy chrome.
- Customizable translucency: supports solid background colors as well as macOS Acrylic / Vibrancy visual effect blur.
- Refined traffic lights with breathing space (comfortably inset from the top edge).
- Single-tab view displays an unobtrusive breadcrumb path; multi-tab view activates a minimalist tab bar with drag-and-drop reordering.

### 🗂 Advanced Multi-Tab & Split Panes
- **Splits**: Vertical split (`⌘D`) and horizontal split (`⇧⌘D`).
- **Directional Navigation**: Geometric spatial switching via `⌃⌘H / J / K / L` or `⌃⌘ Arrow keys`.
- **Split Zoom (`⇧⌘Enter`)**: Temporarily maximize the active pane for deep focus, and unzoom with the same shortcut.
- **Equalize (`⌃⌘=`)**: Instantly rebalance all pane dimensions.
- **Interactive Hairline Dividers**: Smooth AppKit draggable divider lines with native resize cursors.

### 🛸 Dropdown Quick Terminal (`⌃\``)
- System-wide global hotkey (`⌃\``) slides out an instant drop-down scratchpad terminal from the top of the screen.

### 📜 Interactive Scrollback & Search (`⌘F`)
- Built-in floating search bar to highlight and navigate matches across massive command scrollback history.
- Auto-hiding `#9D9FA2` scrollbar thumb that gracefully fades in during scrolling and stays invisible when reading.

### ⚙️ Ghostty Configuration & Hot Reloading
- Reads configuration from `~/.config/suqi/config` or fallback `~/.config/ghostty/config`.
- Real-time live configuration reloading (`⇧⌘,`) without interrupting running processes or shells.

### ⌨️ Native IME Support
- Custom window-level handling ensures macOS Chinese, Japanese, and Korean (CJK) input method candidate popups always appear above floating and tiled terminal windows.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action | Description |
|---|---|---|
| `⌘ V` | **Smart Paste** | Intelligently pastes text, file paths, or images (multimodal AI CLI support) |
| `⌘ C` | **Copy** | Copies selected terminal text to macOS clipboard |
| `⌘ A` | **Select All** | Selects all content in the active surface |
| `⌘ F` | **Find** | Opens scrollback search bar with match highlights |
| `⌘ D` | **Split Right** | Splits active pane vertically |
| `⇧ ⌘ D` | **Split Down** | Splits active pane horizontally |
| `⇧ ⌘ ↩` | **Toggle Zoom** | Maximizes current pane to full window size / restores |
| `⌃ ⌘ =` | **Equalize Splits** | Rebalances all split pane proportions evenly |
| `⌃ ⌘ H/J/K/L` | **Focus Pane** | Navigates focus geometrically (Left / Down / Up / Right) |
| `⌃ ⌘ Arrow` | **Focus Pane** | Navigates focus directionally |
| `⌥ ⌘ ←` / `⌥ ⌘ →`| **Cycle Panes** | Rotates through panes in active tab |
| `⌘ T` | **New Tab** | Opens a new tab (inherits working directory) |
| `⌘ W` | **Close** | Closes focused pane, tab, or window |
| `⇧ ⌘ W` | **Close Window** | Closes the current window |
| `⌘ 1` ~ `⌘ 9` | **Select Tab** | Switches directly to tab 1 through 9 |
| `⇧ ⌘ [` / `⇧ ⌘ ]` | **Previous / Next Tab** | Cycles to previous or next tab |
| `⌃ \`` | **Quick Terminal** | Toggles the drop-down slide-out terminal |
| `⌘ K` | **Clear Scrollback** | Clears terminal scrollback buffer |
| `⌘ +` / `⌘ -` / `⌘ 0` | **Font Size** | Increases, decreases, or resets font size |
| `⌘ ,` | **Open Settings / Config** | Opens configuration file |
| `⇧ ⌘ ,` | **Reload Configuration** | Hot-reloads themes, fonts, and settings |

---

## ⚙️ Configuration

`suqi` shares the clean, declarative configuration format of Ghostty. Place your configuration in `~/.config/suqi/config` or `~/.config/ghostty/config`:

```ini
# Theme
theme = Catppuccin Mocha

# Background & Opacity (0.0 to 1.0)
background-opacity = 0.92
background-blur = 20

# Typography
font-family = Maple Mono NF
font-size = 14
adjust-cell-height = 0
font-thicken = true

# Cursor
cursor-style = bar
cursor-style-blink = true

# Window Dimensions & State
window-width = 110
window-height = 32
window-padding-x = 12
window-padding-y = 10
window-save-state = always

# Clipboard
copy-on-select = clipboard
```

---

## 🛠 Building & Installation

### Prerequisites
- macOS 14.0 (Sonoma) or newer
- Xcode 15.0+ and Command Line Tools
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build Steps

```bash
# 1. Clone repository
git clone https://github.com/sqoder/glint.git suqi
cd suqi

# 2. Generate Xcode project
xcodegen generate

# 3. Build Release binary
xcodebuild -project suqi.xcodeproj -scheme suqi -configuration Release -destination 'platform=macOS' build

# 4. Install to /Applications
cp -R ~/Library/Developer/Xcode/DerivedData/suqi-*/Build/Products/Release/suqi.app /Applications/
```

Or open `suqi.xcodeproj` in Xcode and hit **⌘R** to build and run.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
