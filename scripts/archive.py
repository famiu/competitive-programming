#!/usr/bin/env python3
"""Move a problem from scratch/ to problems/.

Usage: archive.py <problem-dir> [site name]

The destination is problems/<site>/<id>_<slug>, named the same way as `just listen` names
problems. Without <site> and <name>, both come from meta.json, which then needs a URL. With
them, they replace meta.json's site and name, and the ID still comes from the URL when there is
one. meta.json is created or updated to match, and the destination is printed on stdout.
"""

import json
import sys
from pathlib import Path

from listen import PLATFORMS, PROBLEMS_DIR, problem_dir, slugify


def main() -> None:
    args = sys.argv[1:]
    if len(args) not in (1, 3):
        sys.exit("usage: just archive [dir] [site name] [--commit]")
    source = Path(args[0])
    meta_path = source / "meta.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else {}

    if len(args) == 3:
        site, name = slugify(args[1]), args[2].strip()
        if not site or not name:
            sys.exit("error: the site and name must not be empty")
        if site != meta.get("site"):
            meta["platform"] = PLATFORMS.get(site, args[1].strip())
        meta.update(site=site, name=name)
    elif not meta.get("url") or not meta.get("site"):
        sys.exit("error: meta.json has no URL to name the problem from; pass the site and name: just archive <site> <name>")

    destination = problem_dir({**meta, "url": meta.get("url", "")})
    if destination.exists():
        sys.exit(f"error: {destination} already exists")
    if destination.parent.resolve() == PROBLEMS_DIR.resolve():
        sys.exit("error: the site must not be empty")
    destination.parent.mkdir(parents=True, exist_ok=True)
    source.rename(destination)
    (destination / "meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")
    print(destination)


if __name__ == "__main__":
    main()
