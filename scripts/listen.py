#!/usr/bin/env python3
"""Receive problems from the Competitive Companion browser extension.

Usage: listen.py [--once]

Listens on CP_LISTEN_PORT (default 1327, one of Competitive Companion's default ports) and
writes each received problem to problems/<site>/<id>_<slug>/: meta.json, the samples as
tests/NN.in and tests/NN.out, and solution.cpp from the template when it does not exist.
Other files in the problem directory are left alone. Problem directories are printed on
stdout as they are written. With --once, exits after the first problem or contest.
"""

import json
import os
import re
import shutil
import sys
import unicodedata
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlparse

REPO_ROOT = Path(__file__).resolve().parent.parent
PROBLEMS_DIR = REPO_ROOT / "problems"
TEMPLATE = REPO_ROOT / "templates" / "solution.cpp"

PLATFORMS = {
    "atcoder": "AtCoder",
    "codechef": "CodeChef",
    "codeforces": "Codeforces",
    "cses": "CSES",
    "spoj": "SPOJ",
}

# Problem IDs per site, matched against the URL path. Codeforces IDs join contest and index.
ID_PATTERNS = {
    "atcoder": [r"/contests/[^/]+/tasks/([^/]+)"],
    "codechef": [r"/problems/([^/]+)"],
    "codeforces": [
        r"/(?:contest|gym)/(\d+)/problem/([^/]+)",
        r"/problemset/(?:gym)?problem/(\d+)/([^/]+)",
    ],
    "cses": [r"/task/(\d+)"],
    "spoj": [r"/problems/([^/]+)"],
}


def site_of(url: str) -> str:
    """Site key from the URL's domain, e.g. codeforces.com -> codeforces, open.kattis.com -> kattis."""
    labels = (urlparse(url).hostname or "").split(".")
    return labels[-2] if len(labels) >= 2 else labels[0] or "unknown"


def problem_id(site: str, url: str) -> str:
    path = urlparse(url).path
    for pattern in ID_PATTERNS.get(site, []):
        if m := re.search(pattern, path):
            return "".join(m.groups()).lower()
    return ""


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    text = re.sub(r"[^\w\s-]", "", text).strip().lower()
    return re.sub(r"[-\s]+", "_", text).strip("_")


def problem_dir(meta: dict) -> Path:
    """problems/<site>/<id>_<slug>, where the slug is the name without its index ("D. ", "A - ")."""
    title = re.sub(r"^[A-Za-z0-9]+\s*(?:\.|-|–)\s+", "", meta["name"])
    parts = [p for p in (problem_id(meta["site"], meta["url"]), slugify(title)) if p]
    return PROBLEMS_DIR / meta["site"] / ("_".join(parts) or "problem")


def make_meta(url: str, name: str, time_limit_ms: float, memory_limit_mb: float, interactive: bool, judge: str = "") -> dict:
    """The meta.json contents. Every field is derived the same way for every problem."""
    site = site_of(url)
    return {
        "url": url,
        "name": name,
        "site": site,
        "platform": PLATFORMS.get(site, judge or site),
        "time_limit": round(time_limit_ms),
        "memory_limit": round(memory_limit_mb),
        "interactive": bool(interactive),
    }


def write_meta(directory: Path, meta: dict) -> None:
    (directory / "meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")


def write_problem(data: dict) -> Path:
    judge = data.get("group", "").split(" - ")[0]
    meta = make_meta(data["url"], data["name"], data["timeLimit"], data["memoryLimit"], data.get("interactive", False), judge)
    directory = problem_dir(meta)
    tests = directory / "tests"
    tests.mkdir(parents=True, exist_ok=True)

    # Samples are numbered NN; custom_* and stress_* tests are kept.
    for path in tests.iterdir():
        if path.suffix in (".in", ".out") and path.stem.isdigit() and path.is_file():
            path.unlink()
    for i, test in enumerate(data.get("tests", []), 1):
        (tests / f"{i:02d}.in").write_text(test["input"], encoding="utf-8")
        (tests / f"{i:02d}.out").write_text(test["output"], encoding="utf-8")

    write_meta(directory, meta)
    solution = directory / "solution.cpp"
    if not solution.exists():
        shutil.copyfile(TEMPLATE, solution)
    if meta["interactive"]:
        log(f"warning: {meta['name']} is interactive; `just test` cannot judge it")
    return directory


def log(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


class Handler(BaseHTTPRequestHandler):
    once = False
    batches: dict[str, int] = {}

    def do_POST(self) -> None:
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        self.send_response(200)
        self.end_headers()
        try:
            data = json.loads(body)
            directory = write_problem(data)
        except (ValueError, KeyError, OSError) as exc:
            log(f"error: could not save problem: {exc}")
            return
        log(f"saved: {data['name']}")
        print(directory, flush=True)

        batch = data.get("batch", {})
        batch_id, size = batch.get("id", ""), batch.get("size", 1)
        self.batches[batch_id] = self.batches.get(batch_id, 0) + 1
        if self.once and self.batches[batch_id] >= size:
            raise KeyboardInterrupt

    def log_message(self, format: str, *args: object) -> None:
        pass


def main() -> None:
    Handler.once = "--once" in sys.argv[1:]
    port = int(os.environ.get("CP_LISTEN_PORT", "1327"))
    try:
        server = HTTPServer(("127.0.0.1", port), Handler)
    except OSError as exc:
        sys.exit(f"error: cannot listen on port {port}: {exc}")
    log(f"waiting for Competitive Companion on port {port} (Ctrl-C to stop)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
