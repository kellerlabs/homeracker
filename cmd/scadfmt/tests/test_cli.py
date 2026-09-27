"""Tests for scadfmt.cli."""

import io
import subprocess
import sys

import pytest

from scadfmt import cli

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
    path.write_text(UGLY, encoding="utf-8")
    assert cli.main(["format", str(path)]) == cli.EXIT_OK
    assert path.read_text(encoding="utf-8") == PRETTY


def test_format_writes_lf_and_keeps_formatted_file(tmp_path):
    path = tmp_path / "a.scad"
    path.write_bytes(b"x=1;\r\n")
    assert cli.main(["format", str(path)]) == cli.EXIT_OK
    assert path.read_bytes() == PRETTY.encode()
    assert cli.main(["format", str(path)]) == cli.EXIT_OK


def test_check_reports_without_writing(tmp_path):
    ugly, pretty = tmp_path / "ugly.scad", tmp_path / "pretty.scad"
    ugly.write_text(UGLY, encoding="utf-8")
    pretty.write_text(PRETTY, encoding="utf-8")
    assert cli.main(["format", "--check", str(pretty)]) == cli.EXIT_OK
    assert cli.main(["format", "--check", str(ugly), str(pretty)]) == cli.EXIT_CHANGES
    assert ugly.read_text(encoding="utf-8") == UGLY


def test_diff_prints_without_writing(tmp_path, capsysbinary):
    path = tmp_path / "a.scad"
    path.write_text(UGLY, encoding="utf-8")
    assert cli.main(["format", "--diff", str(path)]) == cli.EXIT_OK
    assert b"-x=1;\n+x = 1;\n" in capsysbinary.readouterr().out
    assert path.read_text(encoding="utf-8") == UGLY


def test_directory_is_searched_recursively(tmp_path):
    nested = tmp_path / "sub" / "b.scad"
    nested.parent.mkdir()
    nested.write_text(UGLY, encoding="utf-8")
    (tmp_path / "notes.txt").write_text(UGLY, encoding="utf-8")
    assert cli.main(["format", str(tmp_path)]) == cli.EXIT_OK
    assert nested.read_text(encoding="utf-8") == PRETTY
    assert (tmp_path / "notes.txt").read_text(encoding="utf-8") == UGLY


def test_error_leaves_file_and_continues(tmp_path):
    bad, ugly = tmp_path / "bad.scad", tmp_path / "ugly.scad"
    bad.write_text("x = @;\n", encoding="utf-8")
    ugly.write_text(UGLY, encoding="utf-8")
    assert cli.main(["format", str(bad), str(ugly)]) == cli.EXIT_ERROR
    assert bad.read_text(encoding="utf-8") == "x = @;\n"
    assert ugly.read_text(encoding="utf-8") == PRETTY


def test_missing_file_is_an_error(tmp_path):
    assert cli.main(["format", str(tmp_path / "missing.scad")]) == cli.EXIT_ERROR


def test_stdin_to_stdout(monkeypatch, capsysbinary):
    assert run_stdin(monkeypatch, 'x="☺";\r\n'.encode()) == cli.EXIT_OK
    assert capsysbinary.readouterr().out == 'x = "☺";\n'.encode()


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
    path.write_text(PRETTY, encoding="utf-8")
    result = subprocess.run(
        [sys.executable, "-m", "scadfmt", "format", "--check", str(path)], capture_output=True, check=False
    )
    assert result.returncode == cli.EXIT_OK
