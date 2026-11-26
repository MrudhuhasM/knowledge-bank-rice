#!/usr/bin/env python3
"""RL build time log: the saver.

Serves the time log page at http://localhost:8765 and keeps its data on disk.

  GET  /              the page
  GET  /api/state     everything the page stores, plus the last heartbeat
  PUT  /api/state     save (refused with 409 if a newer save is already on disk)
  PUT  /api/beat      "the page is still open" (lets it notice power cuts)
  GET  /api/summary   a small digest for the bar, the desktop and the lock screen
  PUT  /api/import    {"url": ...}: clone or pull a git repo of phase steps and
                      return the text of every .txt/.md file in its steps/ folder

Every write goes to a temp file, is fsync'd and renamed into place, so a power
cut leaves the old or the new file, never half of one. One copy per day is kept
in data/backups/ for 30 days.

It also sends the desktop notifications: "time for a break" after the work
interval set in the page, and "break's over" when a timed break runs out. They
come from here rather than the page, so they arrive even if the page is closed.

Python standard library only. Listens on 127.0.0.1 only.
"""
import datetime
import json
import os
import shutil
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
PAGE = os.path.join(HERE, "rl-time-log.html")
DATA = os.path.expanduser(os.environ.get("RL_TIMELOG_DATA", os.path.join(HERE, "data")))
STATE = os.path.join(DATA, "state.json")
BEAT = os.path.join(DATA, "heartbeat")
BACKUPS = os.path.join(DATA, "backups")
PORT = int(os.environ.get("RL_TIMELOG_PORT", "8765"))
KEEP_DAYS = 30
MIN, HOUR, DAY = 60_000, 3_600_000, 86_400_000
LOCK = threading.Lock()

os.makedirs(BACKUPS, exist_ok=True)


# ── disk ────────────────────────────────────────────────────────────
def atomic_write(path, data: bytes):
    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)
    fd = os.open(os.path.dirname(path), os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def read_json(path):
    with open(path, "rb") as f:
        return json.loads(f.read())


def read_state():
    try:
        return read_json(STATE)
    except FileNotFoundError:
        return None
    except (OSError, ValueError):
        # Unreadable state file: fall back to the newest good daily copy.
        for name in sorted(os.listdir(BACKUPS), reverse=True):
            try:
                return read_json(os.path.join(BACKUPS, name))
            except (OSError, ValueError):
                continue
        return None


def read_beat():
    try:
        with open(BEAT) as f:
            return int(f.read().strip())
    except (OSError, ValueError):
        return None


def daily_copy(data: bytes):
    name = "state-" + datetime.date.today().isoformat() + ".json"
    atomic_write(os.path.join(BACKUPS, name), data)
    copies = sorted(n for n in os.listdir(BACKUPS) if n.startswith("state-"))
    for old in copies[:-KEEP_DAYS]:
        os.remove(os.path.join(BACKUPS, old))


# ── the same time maths as the page ─────────────────────────────────
def local_midnight(ms):
    d = datetime.datetime.fromtimestamp(ms / 1000)
    return int(d.replace(hour=0, minute=0, second=0, microsecond=0).timestamp() * 1000)


def summarize(S, t):
    if not S or not isinstance(S.get("phases"), list):
        return {"ok": True, "empty": True, "busy": False}
    active = S.get("active")
    brk = S.get("brk")
    if isinstance(brk, (int, float)):
        brk = {"s": brk, "plan": 0, "step": active}
    settings = S.get("settings") or {}
    work_min = settings.get("work", 50)
    rest_min = settings.get("rest", 10)
    steps = [(p, s) for p in S["phases"] for s in p.get("steps", [])]

    def breaks(s):
        out = [(b[0], b[1]) for b in (s.get("breaks") or []) if b and b[0] and b[1]]
        if brk and brk.get("step") == s.get("id"):
            out.append((brk["s"], t))
        return sorted(out)

    def segs(s):
        if not s.get("start"):
            return []
        end = s.get("end") or (t if active == s.get("id") else s["start"])
        out, cur = [], s["start"]
        for a, b in breaks(s):
            if a > cur:
                out.append((cur, min(a, end)))
            cur = max(cur, b)
        if end > cur:
            out.append((cur, end))
        return [x for x in out if x[1] > x[0]]

    every = sorted(x for _, s in steps for x in segs(s))
    merged = []
    for a, b in every:
        if merged and a - merged[-1][1] < 2 * MIN:
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])

    today0 = local_midnight(t)
    week0 = local_midnight(t - 6 * DAY)
    month0 = local_midnight(int(datetime.datetime.fromtimestamp(t / 1000).replace(day=1).timestamp() * 1000))
    today = sum(max(0, min(b, t) - max(a, today0)) for a, b in every)
    week = sum(max(0, min(b, t) - max(a, week0)) for a, b in every)
    days = set()
    for a, b in every:
        x = max(a, month0)
        while x < b:
            days.add(datetime.datetime.fromtimestamp(x / 1000).day)
            x = local_midnight(x) + DAY + 1

    cur = next((s for _, s in steps if s.get("id") == active), None)
    since_break = 0
    if cur and not brk and merged and t - merged[-1][1] < 5000:
        since_break = t - merged[-1][0]
    nxt = next((s for _, s in steps if not s.get("start") and not s.get("pre") and not s.get("end")), None)
    ref = cur or nxt
    phase = next((p for p, s in steps if ref and s is ref), None)

    out = {
        "ok": True,
        "running": bool(cur) and not brk,
        "onBreak": bool(brk),
        "busy": bool(cur or brk),
        "step": None,
        "brk": None,
        "next": {"id": nxt["id"], "name": nxt["name"]} if nxt else None,
        "todayMs": today,
        "weekMs": week,
        "sinceBreakMs": since_break,
        "due": bool(work_min) and since_break >= work_min * MIN,
        "workMin": work_min,
        "restMin": rest_min,
        "monthDays": sorted(days),
        "phase": None,
    }
    if cur:
        out["step"] = {"id": cur["id"], "name": cur["name"], "start": cur["start"],
                       "workMs": sum(b - a for a, b in segs(cur))}
    if brk:
        plan = brk.get("plan") or 0
        left = brk["s"] + plan - t if plan else None
        out["brk"] = {"start": brk["s"], "planMs": plan, "sinceMs": t - brk["s"],
                      "leftMs": max(0, left) if left is not None else None,
                      "overMs": max(0, -left) if left is not None else 0}
    if phase:
        ps = phase.get("steps", [])
        out["phase"] = {"id": phase["id"], "name": phase.get("name", ""), "total": len(ps),
                        "done": sum(1 for s in ps if s.get("end") or s.get("pre"))}
    return out


# ── phase steps from a git repo ─────────────────────────────────────
STEPS_REPO = os.path.join(DATA, "steps-repo")


def git(*args, timeout=90):
    return subprocess.run(["git", *args], capture_output=True, text=True, timeout=timeout,
                          env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})


def import_steps(url):
    if not (url.startswith("https://") or url.startswith("git@")) or any(c.isspace() for c in url):
        return {"ok": False, "error": "Give the repo's clone URL (https://… or git@…)"}
    if not shutil.which("git"):
        return {"ok": False, "error": "git isn't installed"}
    if os.path.isdir(os.path.join(STEPS_REPO, ".git")):
        cur = git("-C", STEPS_REPO, "remote", "get-url", "origin").stdout.strip()
        if cur != url:
            shutil.rmtree(STEPS_REPO)
    if os.path.isdir(os.path.join(STEPS_REPO, ".git")):
        r = git("-C", STEPS_REPO, "fetch", "--depth", "1", "origin")
        if r.returncode == 0:
            r = git("-C", STEPS_REPO, "reset", "--hard", "FETCH_HEAD")
    else:
        r = git("clone", "--depth", "1", url, STEPS_REPO)
    if r.returncode != 0:
        msg = (r.stderr.strip().splitlines() or ["git failed"])[-1]
        return {"ok": False, "error": "git: " + msg}
    commit = git("-C", STEPS_REPO, "rev-parse", "--short", "HEAD").stdout.strip()
    folder = os.path.join(STEPS_REPO, "steps")
    if not os.path.isdir(folder):
        return {"ok": False, "error": "The repo has no steps/ folder"}
    files, parts = [], []
    for root, _, names in os.walk(folder):
        for n in names:
            if n.lower().endswith((".txt", ".md")):
                files.append(os.path.relpath(os.path.join(root, n), folder))
    for rel in sorted(files):
        with open(os.path.join(folder, rel), encoding="utf-8", errors="replace") as f:
            parts.append(f.read())
    return {"ok": True, "commit": commit, "files": sorted(files), "text": "\n".join(parts)}


# ── desktop notifications ───────────────────────────────────────────
def notify(summary, body, urgency="normal", replace=None):
    if not shutil.which("notify-send"):
        return None
    cmd = ["notify-send", "-a", "RL build", "-u", urgency, "-p"]
    if replace:
        cmd += ["-r", str(replace)]
    try:
        r = subprocess.run(cmd + [summary, body], capture_output=True, text=True, timeout=5)
        return int(r.stdout.strip()) if r.stdout.strip().isdigit() else None
    except (OSError, subprocess.SubprocessError):
        return None


def dismiss(nid):
    if nid and shutil.which("makoctl"):
        subprocess.run(["makoctl", "dismiss", "-n", str(nid)], capture_output=True)


def dur(ms):
    m = round(max(0, ms) / MIN)
    return f"{m}m" if m < 60 else f"{m // 60}h {m % 60:02d}m"


def notifier():
    remind_id = over_id = None
    last_remind = 0
    over_for = None
    while True:
        time.sleep(15)
        try:
            with LOCK:
                S = read_state()
            now = int(time.time() * 1000)
            s = summarize(S, now)
            if s.get("due"):
                if now - last_remind >= 10 * MIN:
                    step = s["step"]
                    remind_id = notify(
                        "Time for a break",
                        f"{dur(s['sinceBreakMs'])} without a break on {step['id']}. "
                        f"Take {s['restMin']} minutes: stand up, look away from the screen.",
                        replace=remind_id)
                    last_remind = now
            else:
                if remind_id:
                    dismiss(remind_id)
                remind_id, last_remind = None, 0
            b = s.get("brk")
            if b and b["planMs"] and b["leftMs"] == 0:
                if over_for != b["start"]:
                    target = s.get("step") or s.get("next")
                    over_id = notify("Break’s over",
                                     f"Back to {target['id']} — {target['name']}" if target else "Back to work",
                                     urgency="critical")
                    over_for = b["start"]
            elif over_for is not None:
                dismiss(over_id)
                over_id, over_for = None, None
        except Exception as e:  # never let a bad file stop the saver
            print("notifier:", e, flush=True)


# ── HTTP ────────────────────────────────────────────────────────────
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def reply(self, code, body=b"{}", ctype="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def local_only(self):
        host = (self.headers.get("Host") or "").split(":")[0]
        if host not in ("localhost", "127.0.0.1"):
            self.reply(403, b'{"error":"local use only"}')
            return False
        return True

    def do_GET(self):
        if not self.local_only():
            return
        path = self.path.split("?")[0]
        if path in ("/", "/index.html"):
            with open(PAGE, "rb") as f:
                return self.reply(200, f.read(), "text/html; charset=utf-8")
        if path == "/api/state":
            with LOCK:
                body = json.dumps({"state": read_state(), "beat": read_beat()})
            return self.reply(200, body.encode())
        if path == "/api/summary":
            with LOCK:
                S = read_state()
            return self.reply(200, json.dumps(summarize(S, int(time.time() * 1000))).encode())
        self.reply(404)

    def do_PUT(self):
        if not self.local_only():
            return
        path = self.path.split("?")[0]
        body = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        if path == "/api/import":
            try:
                url = (json.loads(body) or {}).get("url", "").strip()
            except (ValueError, AttributeError):
                return self.reply(400, b'{"ok":false,"error":"not JSON"}')
            try:
                res = import_steps(url)
            except subprocess.TimeoutExpired:
                res = {"ok": False, "error": "git took too long (no network?)"}
            return self.reply(200 if res["ok"] else 400, json.dumps(res).encode())
        if path == "/api/beat":
            with LOCK:
                atomic_write(BEAT, str(int(time.time() * 1000)).encode())
            return self.reply(200)
        if path == "/api/state":
            try:
                new = json.loads(body)
            except ValueError:
                return self.reply(400, b'{"error":"not JSON"}')
            if not isinstance(new, dict) or not isinstance(new.get("phases"), list):
                return self.reply(400, b'{"error":"not a time-log state"}')
            with LOCK:
                old = read_state()
                if old and new.get("rev", 0) <= old.get("rev", 0):
                    # An older or duplicate write (e.g. a second tab): send back what's stored.
                    return self.reply(409, json.dumps({"state": old}).encode())
                data = json.dumps(new, ensure_ascii=False, indent=1).encode()
                atomic_write(STATE, data)
                daily_copy(data)
            return self.reply(200)
        self.reply(404)


if __name__ == "__main__":
    threading.Thread(target=notifier, daemon=True).start()
    print(f"RL time log on http://localhost:{PORT}  (data in {DATA})", flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
