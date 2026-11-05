#!/usr/bin/python3
"""c0oled Scanner: local, heuristic Downloads monitor for macOS.

This is a lightweight warning tool, not a replacement for XProtect or antivirus.
It never deletes files. High-confidence heuristic matches are moved to quarantine.
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

HOME = Path.home()
ROOT = HOME / "Library" / "Application Support" / "c0oled-Scanner"
DOWNLOADS = HOME / "Downloads"
QUARANTINE = ROOT / "Quarantine"
LOGS = ROOT / "Logs"
STATE_FILE = ROOT / "state.json"
POLL = 4
STABLE = 5
MAX_READ = 2 * 1024 * 1024

# Intentionally require multiple suspicious indicators to reduce false positives.
PATTERNS = [
    re.compile(rb"curl.{0,160}\|\s*(?:bash|sh)", re.I),
    re.compile(rb"base64\s+--decode|base64\s+-d", re.I),
    re.compile(rb"osascript\s+-e", re.I),
    re.compile(rb"launchctl\s+(?:load|bootstrap|enable)", re.I),
    re.compile(rb"security\s+find-(?:generic|internet)-password", re.I),
    re.compile(rb"eval\s*\(\s*(?:atob|base64)", re.I),
    re.compile(rb"powershell.{0,80}-enc", re.I),
]
SCRIPT_EXTS = {".sh", ".command", ".py", ".js", ".jsx", ".scpt", ".applescript", ".ps1"}

def log(msg):
    LOGS.mkdir(parents=True, exist_ok=True)
    with (LOGS / "scanner.log").open("a", encoding="utf-8") as f:
        f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + msg + "\n")

def notify(msg):
    safe = msg.replace("\\", "\\\\").replace('"', '\\"')
    subprocess.run(["/usr/bin/osascript", "-e",
        f'display notification "{safe}" with title "c0oled Scanner"'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

def load_state():
    try:
        return json.loads(STATE_FILE.read_text())
    except Exception:
        return {"seen": {}, "stable": {}}

def save_state(state):
    tmp = STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state))
    os.replace(tmp, STATE_FILE)

def scan_file(path, state):
    try:
        st = path.stat()
        key = str(path)
        fingerprint = f"{st.st_size}:{st.st_mtime_ns}"
        old = state["stable"].get(key)
        now = time.time()
        if not old or old.get("fp") != fingerprint:
            state["stable"][key] = {"fp": fingerprint, "since": now}
            return
        if now - old["since"] < STABLE:
            return
        if state["seen"].get(key) == fingerprint:
            return

        findings = []
        suffix = path.suffix.lower()
        if suffix in SCRIPT_EXTS and st.st_size <= MAX_READ:
            data = path.read_bytes()
            matches = [p for p in PATTERNS if p.search(data)]
            if len(matches) >= 2:
                findings.append(f"{len(matches)} suspicious command patterns in script")
        # Ask Gatekeeper to assess application bundles and executable files.
        if path.suffix.lower() == ".app":
            assessment = subprocess.run(["/usr/sbin/spctl", "--assess", "--type", "execute", "--verbose=2", str(path)],
                capture_output=True, text=True, check=False)
            if assessment.returncode != 0:
                findings.append("Gatekeeper did not accept this app (review required)")
        state["seen"][key] = fingerprint
        if findings:
            QUARANTINE.mkdir(parents=True, exist_ok=True)
            dest = QUARANTINE / (str(int(now)) + "-" + path.name)
            n = 1
            while dest.exists():
                dest = QUARANTINE / (str(int(now)) + "-" + str(n) + "-" + path.name)
                n += 1
            # Keep suspicious items contained; user can review/restore them.
            shutil.move(str(path), str(dest))
            message = "; ".join(findings)
            log(f"REVIEW FLAG: {path.name} -> quarantine ({message})")
            notify(f"Flagged and quarantined: {path.name}")
        else:
            log(f"Checked: {path.name} (no heuristic match)")
    except (OSError, PermissionError) as e:
        log(f"Could not inspect {path}: {e}")

def walk_downloads():
    if not DOWNLOADS.exists():
        return
    for root, dirs, files in os.walk(DOWNLOADS, followlinks=False):
        dirs[:] = [d for d in dirs if not (Path(root) / d).is_symlink()]
        for name in files:
            p = Path(root) / name
            try:
                if not p.is_symlink() and p.is_file():
                    yield p
            except OSError:
                continue

def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    QUARANTINE.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    state = load_state()
    log("c0oled Scanner started; first run checks existing Downloads.")
    while True:
        try:
            for p in walk_downloads():
                scan_file(p, state)
            save_state(state)
        except Exception as e:
            log(f"Monitor error: {e}")
        time.sleep(POLL)

if __name__ == "__main__":
    main()
