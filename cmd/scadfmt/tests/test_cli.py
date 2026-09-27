"""Tests for scadfmt.cli."""

import importlib
import importlib.metadata
import io
import subprocess
import sys
from pathlib import Path

import pytest

import scadfmt
from scadfmt import cli, fileio

UGLY = "x=1;\n"
PRETTY = "x = 1;\n"


class FakeStream:
    """Stand-in for sys.stdin with a byte buffer."""

    def __init__(self, data=b""):
        self.buffer = io.BytesIO(data)


def run_stdin(monkeypatch, data, *args):
    monkeypatch.setattr(sys, "stdin", FakeStream(data))
    return cli.main(["format", *args, "-"])


def test_format_rewrites_file(tmp_path):
    path = tmp_path / "a.scad"
    path.write_bytes(UGLY.encode())
    assert cli.main(["format", str(path)]) == cli.EXIT_OK
    assert path.read_text(encoding="utf-8") == PRETTY


def test_format_keeps_crlf(tmp_path):
    path = tmp_path / "a.scad"
    path.write_bytes(b"x=1;\r\n")
    assert cli.main(["format", str(path)]) == cli.EXIT_OK
    assert path.read_bytes() == b"x = 1;\r\n"
    assert cli.main(["format", "--check", str(path)]) == cli.EXIT_OK


def test_check_reports_without_writing(tmp_path):
    ugly, pretty = tmp_path / "ugly.scad", tmp_path / "pretty.scad"
    ugly.write_bytes(UGLY.encode())
    pretty.write_bytes(PRETTY.encode())
    assert cli.main(["format", "--check", str(pretty)]) == cli.EXIT_OK
    assert cli.main(["format", "--check", str(ugly), str(pretty)]) == cli.EXIT_CHANGES
    assert ugly.read_text(encoding="utf-8") == UGLY


def test_diff_prints_without_writing(tmp_path, capsysbinary):
    path = tmp_path / "a.scad"
    path.write_bytes(UGLY.encode())
    assert cli.main(["format", "--diff", str(path)]) == cli.EXIT_OK
    assert b"-x=1;\n+x = 1;\n" in capsysbinary.readouterr().out
    assert path.read_text(encoding="utf-8") == UGLY


def test_directory_is_searched_recursively(tmp_path):
    nested = tmp_path / "sub" / "b.scad"
    nested.parent.mkdir()
    nested.write_bytes(UGLY.encode())
    (tmp_path / "notes.txt").write_bytes(UGLY.encode())
    assert cli.main(["format", str(tmp_path)]) == cli.EXIT_OK
    assert nested.read_text(encoding="utf-8") == PRETTY
    assert (tmp_path / "notes.txt").read_text(encoding="utf-8") == UGLY


def test_error_leaves_file_and_continues(tmp_path):
    bad, ugly = tmp_path / "bad.scad", tmp_path / "ugly.scad"
    bad.write_bytes("x = @;\n".encode())
    ugly.write_bytes(UGLY.encode())
    assert cli.main(["format", str(bad), str(ugly)]) == cli.EXIT_ERROR
    assert bad.read_text(encoding="utf-8") == "x = @;\n"
    assert ugly.read_text(encoding="utf-8") == PRETTY


def test_write_failure_keeps_original_and_continues(tmp_path, monkeypatch):
    first, second = tmp_path / "a.scad", tmp_path / "b.scad"
    first.write_bytes(UGLY.encode())
    second.write_bytes(UGLY.encode())
    real_replace = fileio.os.replace

    def fail_for_first(src, dst):
        if Path(dst) == first:
            raise OSError("disk full")
        real_replace(src, dst)

    monkeypatch.setattr(fileio.os, "replace", fail_for_first)
    assert cli.main(["format", str(first), str(second)]) == cli.EXIT_ERROR
    assert first.read_bytes() == UGLY.encode()
    assert second.read_bytes() == PRETTY.encode()
    assert sorted(p.name for p in tmp_path.iterdir()) == ["a.scad", "b.scad"]


@pytest.mark.skipif(sys.platform == "win32", reason="Windows has no POSIX file modes")
def test_rewrite_keeps_file_mode(tmp_path):
    path = tmp_path / "a.scad"
    path.write_bytes(UGLY.encode())
    path.chmod(0o640)
    assert cli.main(["format", str(path)]) == cli.EXIT_OK
    assert path.stat().st_mode & 0o777 == 0o640
    assert path.read_bytes() == PRETTY.encode()


@pytest.mark.parametrize(("installed", "expected"), [("1.2.3", "1.2.3"), (None, "unknown")])
def test_version_comes_from_package_metadata(monkeypatch, installed, expected):
    def fake_version(name):
        if installed is None:
            raise importlib.metadata.PackageNotFoundError(name)
        return installed

    monkeypatch.setattr(importlib.metadata, "version", fake_version)
    assert importlib.reload(scadfmt).__version__ == expected
    importlib.reload(scadfmt)


@pytest.mark.skipif(sys.platform == "win32", reason="symlinks need extra privileges on Windows")
def test_symlink_target_is_formatted_and_link_kept(tmp_path):
    target, link = tmp_path / "real.scad", tmp_path / "link.scad"
    target.write_bytes(UGLY.encode())
    link.symlink_to(target)
    assert cli.main(["format", str(link)]) == cli.EXIT_OK
    assert link.is_symlink()
    assert target.read_bytes() == PRETTY.encode()


def test_version(capsys):
    with pytest.raises(SystemExit):
        cli.main(["--version"])
    assert capsys.readouterr().out.startswith("scadfmt ")


def test_missing_file_is_an_error(tmp_path):
    assert cli.main(["format", str(tmp_path / "missing.scad")]) == cli.EXIT_ERROR


def test_stdin_to_stdout(monkeypatch, capsysbinary):
    assert run_stdin(monkeypatch, 'x="☺";\r\n'.encode()) == cli.EXIT_OK
    assert capsysbinary.readouterr().out == 'x = "☺";\r\n'.encode()


def test_stdin_check_and_diff(monkeypatch, capsysbinary):
    assert run_stdin(monkeypatch, UGLY.encode(), "--check") == cli.EXIT_CHANGES
    assert run_stdin(monkeypatch, PRETTY.encode(), "--check") == cli.EXIT_OK
    assert capsysbinary.readouterr().out == b""
    assert run_stdin(monkeypatch, UGLY.encode(), "--diff") == cli.EXIT_OK
    assert b"+x = 1;" in capsysbinary.readouterr().out


def test_stdin_error(monkeypatch, capsysbinary):
    assert run_stdin(monkeypatch, b"x = @;") == cli.EXIT_ERROR
    assert run_stdin(monkeypatch, b"\xff") == cli.EXIT_ERROR
    assert capsysbinary.readouterr().out == b""


def test_stdin_mixed_with_paths_is_rejected(tmp_path):
    assert cli.main(["format", "-", str(tmp_path)]) == cli.EXIT_ERROR


def test_vscode_subcommand(monkeypatch, tmp_path):
    calls = []
    monkeypatch.setattr(cli, "setup_vscode", lambda workspace: calls.append(workspace) or True)
    assert cli.main(["vscode", "--workspace", str(tmp_path)]) == cli.EXIT_OK
    assert calls == [tmp_path]
    monkeypatch.setattr(cli, "setup_vscode", lambda workspace: False)
    assert cli.main(["vscode"]) == cli.EXIT_ERROR


def test_module_entry_point(tmp_path):
    path = tmp_path / "a.scad"
    path.write_bytes(PRETTY.encode())
    result = subprocess.run(
        [sys.executable, "-m", "scadfmt", "format", "--check", str(path)], capture_output=True, check=False
    )
    assert result.returncode == cli.EXIT_OK
