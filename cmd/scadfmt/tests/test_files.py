"""Canary and repo-wide tests: real files format without error and idempotently."""

import subprocess
from pathlib import Path

import pytest

from scadfmt.formatter import format_source

CANARY = Path(__file__).parent / "canary"
REPO_ROOT = Path(__file__).resolve().parents[3]


def test_canary_formats_to_expected():
    source = (CANARY / "canary.scad").read_text(encoding="utf-8")
    expected = (CANARY / "canary.expected.scad").read_text(encoding="utf-8")
    assert format_source(source) == expected


def test_canary_expected_is_stable():
    expected = (CANARY / "canary.expected.scad").read_text(encoding="utf-8")
    assert format_source(expected) == expected


def _repo_scad_files():
    try:
        out = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "ls-files", "*.scad"], capture_output=True, encoding="utf-8", check=True
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return []
    return [REPO_ROOT / name for name in out.split()]


@pytest.mark.parametrize("path", _repo_scad_files(), ids=lambda p: str(p.relative_to(REPO_ROOT)))
def test_repo_file_formats_idempotently(path):
    formatted = format_source(path.read_text(encoding="utf-8"))
    assert format_source(formatted) == formatted
