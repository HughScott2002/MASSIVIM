#!/usr/bin/env python3
"""Apply two bounded grammar fixes to pinned upstream sources in user cache."""
import argparse, hashlib, subprocess
from pathlib import Path

PINS = {
    "rust": "77a3747266f4d621d0757825e6b11edcbf991ca5",
    "bash": "a06c2e4415e9bc0346c6b86d401879ffb44058f7",
}
a = argparse.ArgumentParser()
a.add_argument("cache")
args = a.parse_args()
root = Path(__file__).resolve().parent.parent
for lang, rev in PINS.items():
    patch = root / "patches" / f"{lang}.patch"
    identity = rev + "-v2-" + hashlib.sha256(patch.read_bytes()).hexdigest()[:12]
    target = Path(args.cache) / ("massivim-" + lang + "-" + identity)
    if not (target / ".massivim-ready").exists():
        target.mkdir(parents=True, exist_ok=True)

        def run(*cmd):
            subprocess.run(cmd, cwd=target, check=True, timeout=120)

        run("git", "init", "--quiet")
        run(
            "git",
            "fetch",
            "--quiet",
            "--depth=1",
            f"https://github.com/tree-sitter/tree-sitter-{lang}",
            rev,
        )
        run("git", "checkout", "--quiet", "--detach", "FETCH_HEAD")
        # A failed or interrupted prior attempt must not apply the same patch twice.
        run("git", "restore", "--source=HEAD", "--worktree", "grammar.js")
        run("git", "apply", str(patch))
        run("tree-sitter", "generate", "grammar.js")
        (target / ".massivim-ready").write_text(identity)
    print(f"{lang}\t{target}\t{identity}")
