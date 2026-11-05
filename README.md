# BOZO EXECUTER — SS EDITION

**Made by c0oled. Official 2026. Non copyrighted.**

## Install
    curl -fsSL https://raw.githubusercontent.com/YOURUSER/bozo-executor/main/install.sh | sh

## How it runs
Bozo Executer connects to a local executor backend on 127.0.0.1.
Supported backends:
- Opiumware (ports 8390–8399)
- MacSploit (ports 5553–5563, 8765)

You must have one of these running with Roblox open. If neither is
installed, INJECT will fail — no backend, no execution.

"SS Edition" is a label. Roblox Luau runs on the client. There is no
server-side Luau on Roblox's servers. This app injects like every other
Mac executor on the market.

## Keys
Run `python3 genkey.py` on your build machine. It prints
`Cooled-Bozo-Key-########` and copies it to your clipboard.
Keys are stored in `active_keys.json` next to the app.
Client-side keys are crackable. This one is too.

## Signature
Unsigned. Built with py2app on macOS. Users download through install.sh,
which clears the quarantine flag via `xattr -dr com.apple.quarantine`.
No Developer ID. No notarization.
