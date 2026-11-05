# Download Guard for macOS

A local Downloads monitor for macOS. It scans files already in `~/Downloads` the first time it starts, then scans only new or changed files. Detections are moved into a private quarantine folder; files are not permanently deleted.

## Install

Requires macOS. If Homebrew is missing, the installer asks before running Homebrew's official installer. You can decline and install it yourself from https://brew.sh.

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/install.sh | bash
```

The installer installs ClamAV, downloads its malware signatures, and registers a per-user LaunchAgent so the monitor starts when you log in.

## Scan behavior

- **First launch:** scans files already present in Downloads, waiting for files to stop changing.
- **Later launches:** uses a saved local scan history and skips files whose size and modification time have not changed.
- **New or changed files:** scanned automatically.
- Scan errors are not treated as clean results; affected files are left untouched and retried.
- Detected files are moved to `~/Library/Application Support/DownloadGuard/Quarantine`.
- The macOS alert text says “Deleted 1 malware!”, but the file is actually quarantined so it can be reviewed or restored if it was a false positive.
- Files are scanned locally; they are not uploaded by this tool.

No antivirus can guarantee detection of every threat. Keep macOS and ClamAV signatures updated.

## Logs and quarantine

- Logs: `~/Library/Application Support/DownloadGuard/Logs`
- Quarantine: `~/Library/Application Support/DownloadGuard/Quarantine`

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main/uninstall.sh | bash
```

Uninstall removes the LaunchAgent and app files. Quarantined files and logs are retained for review.
