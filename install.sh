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

# Homebrew is installed only after an explicit confirmation. The installer is
# commonly piped into bash, so read the answer from the user's terminal.
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Download Guard needs it to install ClamAV."
  read -r -p "Install Homebrew now using the official installer? [y/N] " answer </dev/tty || answer="n"
  case "$answer" in
    [yY]|[yY][eE][sS])
      echo "Running the official Homebrew installer..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      ;;
    *)
      echo "No changes made. Install Homebrew from https://brew.sh, then rerun this command."
      exit 1
      ;;
  esac

  # Homebrew is not always added to PATH automatically in non-interactive shells.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew installation did not finish correctly."
  echo "Open a new Terminal window, then rerun the install command."
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

echo "[4/5] Creating Download Guard.app..."
mkdir -p "$HOME/Applications"
APPLESCRIPT="$APP_DIR/DownloadGuard.applescript"
cat > "$APPLESCRIPT" <<'APPLESCRIPT'
on run
    set userId to do shell script "/usr/bin/id -u"
    try
        do shell script "/bin/launchctl kickstart gui/" & userId & "/com.c0oled.downloadguard"
        display notification "Downloads are being monitored. New and changed files will be scanned." with title "Download Guard"
    on error errorMessage
        display dialog "Could not start the Download Guard monitor: " & errorMessage buttons {"OK"} default button "OK"
    end try
end run
APPLESCRIPT
if [[ -d "$HOME/Applications/Download Guard.app" ]]; then
  echo "Updating existing Download Guard.app"
fi
/usr/bin/osacompile -o "$HOME/Applications/Download Guard.app" "$APPLESCRIPT"
/usr/bin/plutil -replace CFBundleIdentifier -string com.c0oled.downloadguard.app "$HOME/Applications/Download Guard.app/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleName -string "Download Guard" "$HOME/Applications/Download Guard.app/Contents/Info.plist"

echo "[5/5] Done."
echo "Download Guard is watching: $HOME/Downloads"
echo "On its first start, it scans files already in Downloads."
echo "After that, it scans only new or changed files (scan history is saved)."
echo "Quarantine: $APP_DIR/Quarantine"
echo "Logs: $APP_DIR/Logs"
