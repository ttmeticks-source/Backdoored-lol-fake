import socket, ctypes, ctypes.util, os, subprocess, time

OPIUMWARE_PORTS = list(range(8390, 8400))
MACSPLOIT_PORTS = list(range(5553, 5564)) + [8765]

def find_backend(timeout=0.4):
    for port in OPIUMWARE_PORTS + MACSPLOIT_PORTS:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(timeout)
            s.connect(("127.0.0.1", port))
            s.close()
            return port
        except OSError:
            continue
    return None

def send_script(port, source):
    """Send a Luau chunk over the executor socket.
    Opiumware and MacSploit both accept raw Luau on their listener."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(("127.0.0.1", port))
    s.sendall(source.encode("utf-8"))
    s.shutdown(socket.SHUT_WR)
    reply = b""
    try:
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            reply += chunk
    except socket.timeout:
        pass
    s.close()
    return reply.decode("utf-8", "replace")

def roblox_pids():
    try:
        out = subprocess.check_output(["pgrep", "-x", "RobloxPlayer"])
        return [int(x) for x in out.split()]
    except subprocess.CalledProcessError:
        return []

def try_inject(dylib_path):
    """Attempt to inject a dylib into RobloxPlayer via task_for_pid.
    Requires: SIP disabled OR signed binary with task_for_pid entitlement.
    On a stock Mac this returns False. That is not a bug — that is macOS."""
    if not os.path.exists(dylib_path):
        return False, "dylib not found"
    pids = roblox_pids()
    if not pids:
        return False, "RobloxPlayer not running"
    pid = pids[0]
    libc = ctypes.CDLL(ctypes.util.find_library("c"))
    lib_sys = ctypes.CDLL(ctypes.util.find_library("System"))
    task = ctypes.c_uint(0)
    kr = lib_sys.task_for_pid(libc.mach_task_self(), pid, ctypes.byref(task))
    if kr != 0:
        return False, f"task_for_pid failed ({kr}) — SIP likely on, Roblox not debuggable"
    return False, "task_for_pid OK but thread hijack scaffold not shipped — needs a real loader"
