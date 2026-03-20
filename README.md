<div align="center">

<img src="AppBundle/AppIcon.png" width="128" height="128" alt="Therma — macOS Menu Bar Monitor">

# Therma

**RAM & CPU temperature monitor for macOS. Lives in your menu bar. Zero bloat.**

[![macOS](https://img.shields.io/badge/macOS-14%2B-black?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/jayzzjay98-stack/Therma?color=00C853&label=latest)](https://github.com/jayzzjay98-stack/Therma/releases/latest)
[![Tests](https://img.shields.io/badge/tests-65%20passing-brightgreen)](#build-from-source)

[**Download**](https://github.com/jayzzjay98-stack/Therma/releases/latest) · [Features](#features) · [Build from Source](#build-from-source) · [Auto-Update](#auto-update) · [Contributing](#contributing)

</div>

---

Therma gives you a permanent, low-overhead view of your Mac's memory and thermals — right in the menu bar. No subscription, no analytics, no Electron, no bloat.

```
Memory  63%  ·  CPU  54°C
```

That's it. One line. Always there.

---

## Features

### Menu Bar
- Live **RAM usage %** and/or **CPU temperature** in the status bar
- Adjustable icon size, text size, and display mode (RAM · CPU · Both)
- 35 built-in color **themes** — Amber, Arctic, Cosmic, Matrix, Lava, and more

### Memory
- Used / free / wired / compressed breakdown
- Memory pressure ring with gradient stroke
- **One-click RAM purge** — sends memory pressure signal to encourage apps to release caches
- **Deep Clean** — clears Xcode DerivedData, Gradle, JetBrains caches + purge

### CPU Temperature
- Real-time per-sensor readings via IOKit / SMC (Apple Silicon & Intel)
- Color-coded thermal zones: 🔵 cool → 🟢 normal → 🟡 warm → 🟠 hot → 🔴 critical
- Historical bar chart (last 20 readings)

### Alerts
- Local notifications when RAM or CPU crosses your custom threshold
- 5-minute cooldown to prevent notification spam

### General
- **Launch at Login** via ServiceManagement
- Temperature unit: **°C** or **°F**
- **In-app updates** via GitHub Releases — one click, no appcast server needed

---

## Requirements

| | |
|---|---|
| **macOS** | 14.0 Sonoma or later |
| **Architecture** | Apple Silicon (arm64) |
| **Build tools** | Xcode Command Line Tools (for source builds) |

---

## Installation

### Download (recommended)

1. Go to [**Releases**](https://github.com/jayzzjay98-stack/Therma/releases/latest)
2. Download `Therma-<version>.zip`
3. Unzip → drag **Therma.app** to `/Applications`
4. Open Therma and grant the accessibility permission if prompted

### Homebrew _(coming soon)_

```bash
brew install --cask therma
```

---

## Build from Source

```bash
# Clone
git clone https://github.com/jayzzjay98-stack/Therma.git
cd Therma

# Build, bundle, and install to /Applications
bash install.sh
```

The `install.sh` script:
1. Compiles a release binary via Swift Package Manager
2. Assembles the `.app` bundle with `Info.plist` and `AppIcon.icns`
3. Copies the bundle to `/Applications/Therma.app`
4. Registers a Login Item and launches the app

**Run tests:**
```bash
swift test
# → 65 tests, 0 failures
```

**Regenerate the app icon:**
```bash
bash scripts/build_icon.sh
# Draws a 1024×1024 PNG with NSBezierPath → sips → iconutil → AppIcon.icns
```

---

## Auto-Update

Therma updates itself from GitHub Releases with no external server needed.

**For users:**
Settings → About → **Check for Updates** → Download → **Install & Relaunch**

**For maintainers — publishing a release:**

```bash
# 1. Bump CFBundleShortVersionString in Info.plist (e.g. "1.1")
# 2. Build a release zip containing Therma.app at the root
bash create_dmg.sh

# 3. Create a GitHub Release tagged vX.Y.Z and attach the zip
gh release create v1.1 Therma-1.1.zip \
  --title "Therma 1.1" \
  --notes "What changed."
```

The zip **must** be named `Therma-<version>.zip` and contain `Therma.app` at its root. The updater downloads, unzips, ad-hoc codesigns, and hot-swaps the running app.

---

## Project Structure

```
Therma/
├── Sources/Therma/
│   │
│   ├── ThermaApp.swift              # @main — app entry point
│   ├── AppContext.swift             # Shared singletons (monitors, prefs, updater)
│   ├── StatusBarController.swift   # Menu bar item, popover, right-click menu
│   │
│   ├── RAMMonitor.swift             # Memory stats via Mach host_statistics64
│   ├── CPUMonitor.swift             # Temperatures via IOKit / SMC
│   ├── CPUSensorPolicy.swift        # Sensor ranking & selection
│   ├── MemoryStatsProvider.swift    # vm_statistics64 abstraction
│   │
│   ├── MenuBarView.swift            # SwiftUI popover root
│   ├── MenuBarComponents.swift      # CPU cards, stat boxes, history bars
│   ├── MenuBarLabel.swift           # Status bar text rendering
│   │
│   ├── SettingsView.swift           # Settings window (sidebar layout)
│   ├── SettingsViewComponents.swift # Sidebar items, pref rows, sliders
│   ├── MenuBarPreferences.swift     # All preferences (UserDefaults-backed)
│   ├── LayoutMetrics.swift          # Window & layout constants
│   ├── ThemeRegistry.swift          # 35 built-in color themes
│   │
│   ├── UpdateManager.swift          # GitHub Releases auto-updater
│   ├── AlertManager.swift           # UNUserNotificationCenter alerts
│   ├── PurgeManager.swift           # Privileged RAM purge
│   ├── CacheManager.swift           # Developer cache sweep
│   │
│   ├── ProcessManager.swift         # Top-process listing
│   ├── ProcessCore.swift
│   ├── ProcessProtectionPolicy.swift
│   ├── ProcessSnapshotReader.swift
│   ├── LeftoverProcessDetector.swift
│   ├── AppLifecycleTracker.swift
│   │
│   ├── ChipDetector.swift
│   ├── LaunchAtLoginManager.swift
│   ├── MonitorDisplayMode.swift
│   └── Constants.swift
│
├── Tests/ThermaTests/               # 65 unit tests
│
├── scripts/
│   ├── generate_app_icon.swift      # Programmatic icon (NSBezierPath)
│   └── build_icon.sh                # PNG → iconset → .icns
│
├── .github/workflows/ci.yml         # Build + test on every push / PR
│
├── install.sh                        # Build + install to /Applications
├── uninstall.sh                      # Remove app, sudoers rule, login item
├── create_dmg.sh                     # Package a release DMG
├── notarize.sh                       # Apple notarization workflow
├── Info.plist
├── Package.swift
└── AppIcon.icns
```

---

## Permissions

| Permission | Reason |
|---|---|
| Accessibility | Reading CPU temperature sensors via IOKit |
| Notifications | RAM / CPU threshold alerts |
| Login Items | Launch at login (off by default) |

Therma makes **no network requests** except when you explicitly click **Check for Updates**.

---

## CI

Every push and pull request to `main` runs the full test suite via GitHub Actions (`.github/workflows/ci.yml`):

- Debug build + 65 unit tests
- Release binary (arm64) on `main` pushes
- DMG artifact uploaded to workflow artifacts

---

## Contributing

1. Fork the repo and create a branch: `git checkout -b feature/my-change`
2. Make your changes
3. Run `swift test` — all 65 tests must pass
4. Commit with a [Conventional Commit](https://www.conventionalcommits.org) message
5. Open a pull request

Bug reports and feature ideas are welcome via [Issues](https://github.com/jayzzjay98-stack/Therma/issues).

---

## License

[MIT](LICENSE) © 2025 jayzzjay98-stack
