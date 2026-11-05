#!/usr/bin/python3
"""Protecter: a small, local heuristic file-review monitor for macOS."""
import json, os, re, shutil, subprocess, time
from pathlib import Path

ROOT = Path.home() / "Library" / "Application Support" / "Protecter"
DOWNLOADS = Path.home() / "Downloads"
QUARANTINE = ROOT / "Quarantine"
LOGS = ROOT / "Logs"
STATE = ROOT / "state.json"
POLL, STABLE, MAX_READ = 4, 5, 2 * 1024 * 1024
PATTERNS = [
    re.compile(rb"curl.{0,160}\\|\\s*(?:bash|sh)", re.I),
    re.compile(rb"base64\\s+--decode|base64\\s+-d", re.I),
    re.compile(rb"osascript\\s+-e", re.I),
    re.compile(rb"launchctl\\s+(?:load|bootstrap|enable)", re.I),
    re.compile(rb"security\\s+find-(?:generic|internet)-password", re.I),
    re.compile(rb"eval\\s*\\(\\s*(?:atob|base64)", re.I),
]
SCRIPT_EXTS = {".sh", ".command", ".py", ".js", ".jsx", ".scpt", ".applescript"}

def log(message):
    LOGS.mkdir(parents=True, exist_ok=True)
    with (LOGS / "protecter.log").open("a", encoding="utf-8") as f:
        f.write(time.strftime("%Y-%m-%d %H:%M:%S ") + message + "\\n")

def notify(message):
    safe = message.replace("\\", "\\\\").replace('"', '\\"')
    subprocess.run(["/usr/bin/osascript", "-e",
        f'display notification "{safe}" with title "Protecter"'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)

def load_state():
    try: return json.loads(STATE.read_text())
    except Exception: return {"seen": {}, "stable": {}}

def save_state(state):
    tmp = STATE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state))
    os.replace(tmp, STATE)

def scan(path, state):
    try:
        st = path.stat()
        key = str(path)
        fingerprint = f"{st.st_size}:{st.st_mtime_ns}"
        old = state["stable"].get(key)
        now = time.time()
        if not old or old.get("fp") != fingerprint:
            state["stable"][key] = {"fp": fingerprint, "since": now}
            return
        if now - old["since"] < STABLE or state["seen"].get(key) == fingerprint:
            return
        findings = []
        if path.suffix.lower() in SCRIPT_EXTS and st.st_size <= MAX_READ:
            data = path.read_bytes()
            hits = sum(bool(pattern.search(data)) for pattern in PATTERNS)
            if hits >= 2:
                findings.append(f"{hits} suspicious command patterns")
        if path.suffix.lower() == ".app":
            result = subprocess.run(["/usr/sbin/spctl", "--assess", "--type", "execute", str(path)],
                                    capture_output=True, check=False)
            if result.returncode:
                findings.append("Gatekeeper assessment did not pass; manual review recommended")
        state["seen"][key] = fingerprint
        if findings:
            QUARANTINE.mkdir(parents=True, exist_ok=True)
            dest = QUARANTINE / f"{int(now)}-{path.name}"
            index = 1
            while dest.exists():
                dest = QUARANTINE / f"{int(now)}-{index}-{path.name}"
                index += 1
            shutil.move(str(path), str(dest))
            log(f"FLAGGED and quarantined {path.name}: {'; '.join(findings)}")
            notify(f"Flagged and quarantined: {path.name}")
        else:
            log(f"Checked {path.name}; no heuristic match")
    except OSError as exc:
        log(f"Could not inspect {path}: {exc}")

def files():
    if not DOWNLOADS.exists(): return
    for root, dirs, names in os.walk(DOWNLOADS, followlinks=False):
        dirs[:] = [d for d in dirs if not (Path(root) / d).is_symlink()]
        for name in names:
            p = Path(root) / name
            try:
                if not p.is_symlink() and p.is_file(): yield p
            except OSError:
                pass

def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    QUARANTINE.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(parents=True, exist_ok=True)
    state = load_state()
    log("Protecter started; checking Downloads locally.")
    while True:
        try:
            for path in files(): scan(path, state)
            save_state(state)
        except Exception as exc:
            log(f"Monitor error: {exc}")
        time.sleep(POLL)

if __name__ == "__main__":
    main()
