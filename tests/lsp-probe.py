#!/usr/bin/env python3
"""Bounded stdio LSP lifecycle probe; no project files are written."""
import argparse, json, os, selectors, subprocess, tempfile, time
from pathlib import Path


def probe(command, language, text, diagnostics=True, expect_errors=None):
    with tempfile.TemporaryDirectory(
        prefix="massivim-lsp-"
    ) as root, tempfile.TemporaryFile() as err:
        p = subprocess.Popen(
            command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=err
        )
        sel = selectors.DefaultSelector()
        sel.register(p.stdout, selectors.EVENT_READ)
        buf = b""
        messages = []

        def send(msg):
            raw = json.dumps(dict(jsonrpc="2.0", **msg)).encode()
            p.stdin.write(f"Content-Length: {len(raw)}\r\n\r\n".encode() + raw)
            p.stdin.flush()

        def receive(predicate, timeout=20):
            nonlocal buf
            end = time.monotonic() + timeout
            while time.monotonic() < end:
                while b"\r\n\r\n" in buf:
                    header, body = buf.split(b"\r\n\r\n", 1)
                    length = int(
                        next(
                            l.split(b":", 1)[1]
                            for l in header.split(b"\r\n")
                            if l.lower().startswith(b"content-length:")
                        )
                    )
                    if len(body) < length:
                        break
                    msg = json.loads(body[:length])
                    buf = body[length:]
                    messages.append(msg)
                    if "method" in msg and "id" in msg:
                        result = (
                            [{} for _ in msg.get("params", {}).get("items", [])]
                            if msg["method"] == "workspace/configuration"
                            else None
                        )
                        send(dict(id=msg["id"], result=result))
                    if predicate(msg):
                        return msg
                if not sel.select(max(0, min(0.2, end - time.monotonic()))):
                    continue
                chunk = os.read(p.stdout.fileno(), 65536)
                if not chunk:
                    raise RuntimeError(f"server exited unexpectedly: {p.poll()}")
                buf += chunk
            raise TimeoutError("LSP response/diagnostics timeout")

        try:
            send(
                dict(
                    id=1,
                    method="initialize",
                    params=dict(
                        processId=os.getpid(),
                        rootUri=Path(root).as_uri(),
                        capabilities={
                            "workspace": {"configuration": True},
                            "textDocument": {"publishDiagnostics": {}},
                        },
                    ),
                )
            )
            result = receive(lambda m: m.get("id") == 1)
            assert "capabilities" in result.get("result", {}), result
            send(dict(method="initialized", params={}))
            uri = Path(
                root,
                "fixture."
                + {
                    "html": "html",
                    "css": "css",
                    "json": "json",
                    "jsonc": "jsonc",
                    "javascript": "js",
                }[language],
            ).as_uri()
            send(
                dict(
                    method="textDocument/didOpen",
                    params={
                        "textDocument": dict(
                            uri=uri, languageId=language, version=1, text=text
                        )
                    },
                )
            )
            published = None
            if diagnostics:
                published = receive(
                    lambda m: m.get("method") == "textDocument/publishDiagnostics"
                    and m.get("params", {}).get("uri") == uri
                )
                items = published["params"].get("diagnostics")
                assert isinstance(items, list), "Invalid diagnostics payload"
                if expect_errors is not None:
                    assert (
                        bool(items) == expect_errors
                    ), f"Unexpected diagnostic count: {len(items)}"
            send(dict(id=2, method="shutdown", params=None))
            reply = receive(lambda m: m.get("id") == 2)
            assert "result" in reply, reply
            send(dict(method="exit", params=None))
            assert p.wait(timeout=5) == 0
            return dict(
                status="pass",
                command=command,
                diagnostics_required=diagnostics,
                diagnostic_count=(
                    len(published["params"]["diagnostics"]) if published else None
                ),
            )
        except Exception as exc:
            return dict(status="fail", command=command, error=str(exc))
        finally:
            if p.poll() is None:
                p.kill()
                p.wait()
            err.seek(0)
            log = err.read().decode(errors="replace")
            if log:
                print(log[-2500:], file=__import__("sys").stderr)
            try:
                p.stdin.close()
            except BrokenPipeError:
                pass
            p.stdout.close()
            sel.close()


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--bin-dir", default="")
    ap.add_argument("--output")
    a = ap.parse_args()
    cases = [
        ("html", "<html><body><div></body></html>"),
        ("json", '{"bad": }'),
        ("css", "a { color: ; }"),
        ("eslint", "let x = 1;"),
    ]
    results = []
    for name, source in cases:
        exe = "vscode-" + name + "-language-server"
        results.append(
            probe(
                [str(Path(a.bin_dir) / exe) if a.bin_dir else exe, "--stdio"],
                "javascript" if name == "eslint" else name,
                source,
                name != "eslint",
            )
        )
    exe = (
        str(Path(a.bin_dir) / "vscode-json-language-server")
        if a.bin_dir
        else "vscode-json-language-server"
    )
    for source, expected in [
        ('// comment\n{"name":"hello",}', False),
        ("{unquoted:'JSON5 only'}", True),
    ]:
        result = probe([exe, "--stdio"], "jsonc", source, True, expected)
        result["case"] = (
            "JSONC valid trailing comma"
            if not expected
            else "JSONC rejects JSON5-only syntax"
        )
        results.append(result)
    report = json.dumps(results, indent=2)
    print(report)
    if a.output:
        Path(a.output).write_text(report + "\n")
    raise SystemExit(any(r["status"] != "pass" for r in results))
