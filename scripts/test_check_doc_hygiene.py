"""Tests for the documentation hygiene check."""

from __future__ import annotations

from pathlib import Path

import check_doc_hygiene as hygiene


def _write(root: Path, rel: str, text: str) -> None:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def test_parse_csv_drops_empty() -> None:
    """Empty fields are dropped."""
    assert hygiene.parse_csv("a, b,,c") == ["a", "b", "c"]
    assert hygiene.parse_csv("") == []


def test_path_excluded_prefix_basename_and_glob() -> None:
    """Exclude patterns cover a tree, a basename, and a glob."""
    patterns = ["docs/guardrails/**", "CHANGELOG.md", "notes/*.md"]
    assert hygiene.path_excluded("docs/guardrails", patterns)
    assert hygiene.path_excluded("docs/guardrails/ci/guardrails.md", patterns)
    assert not hygiene.path_excluded("docs/guardrails-extra/note.md", patterns)
    assert hygiene.path_excluded("docs/CHANGELOG.md", patterns)
    assert hygiene.path_excluded("notes/a.md", patterns)
    assert not hygiene.path_excluded("README.md", patterns)


def test_repo_allowed() -> None:
    """An allow glob matches the owner and the repository."""
    allowed = ["pirlruc/*devops", "pirlruc/guardrails"]
    assert hygiene.repo_allowed("pirlruc", "commondevops", allowed)
    assert hygiene.repo_allowed("pirlruc", "guardrails", allowed)
    assert not hygiene.repo_allowed("pirlruc", "heimdall", allowed)
    assert not hygiene.repo_allowed("pirlruc", "heimdall", [])


def test_machine_and_link_hits() -> None:
    """Machine paths and policed links are reported. Other owners are not."""
    text = "see /home/ada/src and /Users/ada/src and ~/Developer\n"
    text += "https://github.com/other/app https://github.com/pirlruc/heimdall\n"
    text += "https://github.com/pirlruc/commondevops\n"
    assert hygiene.machine_hits(text) == ["/home/ada/", "/Users/ada/", "~/Developer"]
    assert hygiene.machine_hits("no path") == []
    owners = {"pirlruc"}
    allowed = ["pirlruc/*devops"]
    text += "https://github.com/pirlruc/guardrails.git\n"
    assert hygiene.link_hits(
        text, owners, ["pirlruc/*devops", "pirlruc/guardrails"]
    ) == ["pirlruc/heimdall"]
    assert hygiene.link_hits(text, set(), allowed) == []


def test_scan_skips_excluded_and_vendored(tmp_path: Path) -> None:
    """Historical files, vendored trees, and non-text files are not scanned."""
    _write(tmp_path, "README.md", "ok\n")
    _write(tmp_path, "CHANGELOG.md", "see /home/ada/src\n")
    _write(tmp_path, "docs/guardrails/ci/guardrails.md", "/home/ada/src\n")
    _write(tmp_path, "node_modules/pkg/README.md", "/home/ada/src\n")
    _write(tmp_path, "blob.bin", "/home/ada/src\n")
    assert (
        hygiene.scan(
            tmp_path, {"pirlruc"}, [], hygiene.parse_csv(hygiene.DEFAULT_EXCLUDES)
        )
        == []
    )


def test_scan_reports_a_living_link(tmp_path: Path) -> None:
    """A living markdown link to a policed repository fails."""
    _write(tmp_path, "docs/guide.md", "https://github.com/pirlruc/heimdall\n")
    findings = hygiene.scan(tmp_path, {"pirlruc"}, ["pirlruc/guardrails"], [])
    assert findings == ["docs/guide.md: link outside allowlist pirlruc/heimdall"]


def test_main_ok_and_fail(tmp_path: Path, capsys: object) -> None:
    """The CLI exits 0 on a clean tree and 1 when a path is machine-local."""
    _write(tmp_path, "README.md", "generic\n")
    assert hygiene.main(["--root", str(tmp_path), "--owners", "pirlruc"]) == 0
    _write(tmp_path, "docs/note.md", "checkout ~/Developer\n")
    assert hygiene.main(["--root", str(tmp_path), "--exclude", ""]) == 1
    captured = capsys.readouterr()
    assert "doc hygiene check ok" in captured.out
    assert "machine-local path" in captured.err
