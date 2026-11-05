#!/usr/bin/env python3
"""Local Downloads watcher using ClamAV. Detections are quarantined, not destroyed."""
import json
import os
import shutil
import subprocess
import time
from pathlib import Path

HOME = Path.home()
DOWNLOADS = HOME / "Downloads"
ROOT = HOME / "Library" / "Application Support" / "DownloadGuard"
QUARANTINE = ROOT / "Quarantine"
LOG_DIR = ROOT / "Logs"
DB_DIR = ROOT / "db"
STATE = ROOT / "state.json"
FRESHCONF = ROOT / "freshclam.conf"
POLL_SECONDS = 3
STABLE_SECONDS = 4
UPDATE_SECONDS = 24 * 60 * 60

def log(message):
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    line = f"{time.strftime('%Y-%m-%d %H:%M:%S')} {message}"
    with (LOG_DIR / "scanner.log").open("a", encoding="utf-8") as stream:
        stream.write(line + "\n")
    print(line, flush=True)

def notify(message):
    safe = message.replace("\\", "\\\\").replace('"', '\\"')
    subprocess.run(
        ["/usr/bin/osascript", "-e",
         f'display notification "{safe}" with title "Download Guard"'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False
    )

def load_state():
    try:
        return json.loads(STATE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"scanned": {}, "stable": {}, "last_update": 0}

def save_state(state):
    temporary = STATE.with_suffix(".tmp")
    temporary.write_text(json.dumps(state), encoding="utf-8")
    os.replace(temporary, STATE)

def clam_path(name):
    found = shutil.which(name)
    if not found:
        raise RuntimeError(f"{name} is not installed")
    return found

def update_signatures(state):
    if time.time() - state.get("last_update", 0) < UPDATE_SECONDS:
        return
    result = subprocess.run(
        [clam_path("freshclam"), f"--config-file={FRESHCONF}"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=False
    )
    if result.returncode == 0:
        state["last_update"] = time.time()
        log("ClamAV signatures updated")
    else:
        log("WARNING: signature update failed; continuing with installed signatures")

def files_to_check():
    if not DOWNLOADS.exists():
        return
    for root, dirs, names in os.walk(DOWNLOADS, followlinks=False):
        dirs[:] = [d for d in dirs if not (Path(root) / d).is_symlink()]
        for name in names:
            path = Path(root) / name
            try:
                if path.is_symlink() or not path.is_file():
                    continue
                if path.resolve().is_relative_to(QUARANTINE):
                    continue
                yield path
            except OSError:
                continue

def scan(path, state):
    try:
        stat = path.stat()
        key = str(path)
        fingerprint = f"{stat.st_size}:{stat.st_mtime_ns}"
        now = time.time()
        old = state["stable"].get(key)
        if not old or old.get("fingerprint") != fingerprint:
            state["stable"][key] = {"fingerprint": fingerprint, "since": now}
            return
        if now - old["since"] < STABLE_SECONDS:
            return
        if state["scanned"].get(key) == fingerprint:
            return

        result = subprocess.run(
            [clam_path("clamscan"), "--no-summary", "--infected", str(path)],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=False
        )
        if result.returncode == 0:
            state["scanned"][key] = fingerprint
            log(f"CLEAN {path.name}")
        elif result.returncode == 1:
            QUARANTINE.mkdir(parents=True, exist_ok=True)
            destination = QUARANTINE / f"{int(now)}-{path.name}"
            suffix = 1
            while destination.exists():
                destination = QUARANTINE / f"{int(now)}-{suffix}-{path.name}"
                suffix += 1
            shutil.move(str(path), str(destination))
            state["scanned"].pop(key, None)
            log(f"DETECTED and quarantined {path.name}: {result.stdout.strip()}")
            notify("Deleted 1 malware!")
        else:
            log(f"SCAN ERROR for {path.name}; file left untouched: {result.stdout.strip()}")
            notify("Scan error — file left untouched")
    except FileNotFoundError:
        log(f"File disappeared before scan: {path}")
    except Exception as error:
        log(f"ERROR scanning {path}: {error}")

def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    QUARANTINE.mkdir(parents=True, exist_ok=True)
    state = load_state()
    log("Download Guard started")
    while True:
        try:
            update_signatures(state)
            for path in files_to_check():
                scan(path, state)
            save_state(state)
        except Exception as error:
            log(f"Monitor loop error: {error}")
        time.sleep(POLL_SECONDS)

if __name__ == "__main__":
    main()
