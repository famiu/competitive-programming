#!/usr/bin/env python3
"""Receive problems from the Competitive Companion browser extension.

Usage: listen.py [--once] [--contest [name]]

Listens on CP_LISTEN_PORT (default 1327, one of Competitive Companion's default ports) and
writes each received problem to problems/<site>/<id>_<slug>/: meta.json, the samples as
tests/NN.in and tests/NN.out, and solution.cpp from the template when it does not exist.
Other files in the problem directory are left alone. Problem directories are printed on
stdout as they are written. With --once, exits after the first problem or contest.

Interactive problems get interactor.cpp from its template when it does not exist, and no
samples: the samples of interactive problems show an interaction, not an input for the
interactor.

With --contest, problems go to scratch/<contest>/<letter>/ instead, and meta.json records the
contest. <contest> is <name> when given, else the contest name Competitive Companion sends,
without the judge's name. <letter> is the problem's index from its name ("A. ", "B - "), or
the slugified name when it has none.
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
SCRATCH_DIR = REPO_ROOT / "scratch"
TEMPLATE = REPO_ROOT / "templates" / "solution.cpp"
INTERACTOR_TEMPLATE = REPO_ROOT / "templates" / "interactor.cpp"

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


INDEX_PATTERN = r"^([A-Za-z0-9]+)\s*(?:\.|-|–)\s+"


def problem_dir(meta: dict) -> Path:
    """problems/<site>/<id>_<slug>, where the slug is the name without its index ("D. ", "A - ")."""
    title = re.sub(INDEX_PATTERN, "", meta["name"])
    parts = [p for p in (problem_id(meta["site"], meta["url"]), slugify(title)) if p]
    return PROBLEMS_DIR / meta["site"] / ("_".join(parts) or "problem")


def contest_name(data: dict) -> str:
    """The contest from Competitive Companion's group, e.g. "Codeforces - Round 1000" -> round_1000."""
    group = data.get("group", "")
    return slugify(group.split(" - ", 1)[1] if " - " in group else group)


def contest_problem_dir(contest: str, meta: dict) -> Path:
    """scratch/<contest>/<index>, or scratch/<contest>/<slug> when the name has no index."""
    m = re.match(INDEX_PATTERN, meta["name"])
    return SCRATCH_DIR / contest / ((m.group(1).lower() if m else slugify(meta["name"])) or "problem")


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


def write_problem(data: dict, contest: str | None) -> Path:
    """Writes the problem to problems/, or to scratch/<contest>/ when contest is not None ("" uses
    the contest name from the data)."""
    judge = data.get("group", "").split(" - ")[0]
    meta = make_meta(data["url"], data["name"], data["timeLimit"], data["memoryLimit"], data.get("interactive", False), judge)
    if contest is None:
        directory = problem_dir(meta)
    else:
        contest = contest or contest_name(data)
        if not contest:
            raise ValueError("no contest name received; pass one with --contest <name>")
        meta["contest"] = contest
        directory = contest_problem_dir(contest, meta)
    tests = directory / "tests"
    tests.mkdir(parents=True, exist_ok=True)

    # Samples are numbered NN; custom_* and stress_* tests are kept.
    if not meta["interactive"]:
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
        interactor = directory / "interactor.cpp"
        if not interactor.exists():
            shutil.copyfile(INTERACTOR_TEMPLATE, interactor)
        log(f"note: {meta['name']} is interactive; write interactor.cpp and add tests with `just add-test`")
    return directory


def log(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


class Handler(BaseHTTPRequestHandler):
    once = False
    contest: str | None = None
    batches: dict[str, int] = {}

    def do_POST(self) -> None:
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        self.send_response(200)
        self.end_headers()
        try:
            data = json.loads(body)
            directory = write_problem(data, self.contest)
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
    usage = "usage: just listen [--once] [--contest [name]]"
    args = sys.argv[1:]
    while args:
        arg = args.pop(0)
        if arg == "--once":
            Handler.once = True
        elif arg == "--contest":
            Handler.contest = args.pop(0) if args and not args[0].startswith("-") else ""
            if "/" in Handler.contest or Handler.contest in (".", ".."):
                sys.exit(f"error: invalid contest name: {Handler.contest}")
        else:
            sys.exit(usage)
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
