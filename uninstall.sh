#!/bin/bash
set -euo pipefail
LABEL="com.c0oled.protecter"
launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl disable "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -rf "$HOME/Applications/Protecter.app"
rm -rf "$HOME/Library/Application Support/Protecter/scanner.py" "$HOME/Library/Application Support/Protecter/state.json"
echo "Protecter was removed. Quarantine and logs were kept in ~/Library/Application Support/Protecter."
