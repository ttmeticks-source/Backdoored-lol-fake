#!/bin/bash
set -euo pipefail
LABEL="com.c0oled.downloadguard"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
APP_DIR="$HOME/Library/Application Support/DownloadGuard"
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl disable "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
rm -f "$PLIST"
rm -rf "$APP_DIR/scanner.py" "$APP_DIR/freshclam.conf" "$APP_DIR/state.json"
echo "Download Guard monitor removed."
echo "Quarantined files and logs were kept at: $APP_DIR"
