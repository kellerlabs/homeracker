"""Tests for scadfmt.vscode."""

import json
import subprocess
import sys

import pytest

from scadfmt import fileio, vscode


@pytest.fixture(name="fake_code")
def fixture_fake_code(monkeypatch):
    calls = []
    monkeypatch.setattr(vscode.shutil, "which", lambda name: "/usr/bin/code")
    monkeypatch.setattr(vscode.subprocess, "run", lambda args, **kwargs: calls.append(args))
    return calls


def test_formatter_command_uses_this_interpreter():
    assert vscode.formatter_command() == f'"{sys.executable}" -m scadfmt format -'


def test_merge_settings_replaces_other_scad_formatters():
    settings = {
        "customLocalFormatters.formatters": [
            {"command": "old", "languages": ["scad"]},
            {"command": "keep", "languages": ["yaml"]},
        ],
        "[scad]": {"editor.tabSize": 2},
        "other": True,
    }
    merged = vscode.merge_settings(settings)
    assert merged["customLocalFormatters.formatters"] == [
        {"command": "keep", "languages": ["yaml"]},
        {"command": vscode.formatter_command(), "languages": ["scad"]},
    ]
    assert merged["[scad]"] == {"editor.tabSize": 2, "editor.defaultFormatter": vscode.EXTENSION}
    assert merged["other"] is True


def test_setup_creates_settings(tmp_path, fake_code):
    assert vscode.setup_vscode(tmp_path)
    assert fake_code == [["code", "--install-extension", vscode.EXTENSION, "--force"]]
    settings = json.loads((tmp_path / ".vscode" / "settings.json").read_text(encoding="utf-8"))
    assert settings["[scad]"]["editor.defaultFormatter"] == vscode.EXTENSION


def test_setup_keeps_existing_settings(tmp_path, fake_code):
    settings_file = tmp_path / ".vscode" / "settings.json"
    settings_file.parent.mkdir()
    settings_file.write_text('{"files.eol": "\\n"}', encoding="utf-8")
    assert vscode.setup_vscode(tmp_path)
    assert json.loads(settings_file.read_text(encoding="utf-8"))["files.eol"] == "\n"
    assert fake_code


def test_setup_refuses_settings_with_comments(tmp_path, fake_code):
    settings_file = tmp_path / ".vscode" / "settings.json"
    settings_file.parent.mkdir()
    settings_file.write_text("{\n  // mine\n}", encoding="utf-8")
    assert not vscode.setup_vscode(tmp_path)
    assert settings_file.read_text(encoding="utf-8") == "{\n  // mine\n}"
    assert not fake_code


def test_setup_when_settings_cannot_be_written(tmp_path, fake_code):
    (tmp_path / ".vscode").write_text("not a directory", encoding="utf-8")
    assert not vscode.setup_vscode(tmp_path)


def test_failed_settings_write_keeps_existing_file(tmp_path, fake_code, monkeypatch):
    settings_file = tmp_path / ".vscode" / "settings.json"
    settings_file.parent.mkdir()
    settings_file.write_text('{"keep": 1}', encoding="utf-8")

    def fail(src, dst):
        raise OSError("disk full")

    monkeypatch.setattr(fileio.os, "replace", fail)
    assert not vscode.setup_vscode(tmp_path)
    assert settings_file.read_text(encoding="utf-8") == '{"keep": 1}'
    assert [p.name for p in settings_file.parent.iterdir()] == ["settings.json"]


def test_setup_without_code_cli(tmp_path, monkeypatch):
    monkeypatch.setattr(vscode.shutil, "which", lambda name: None)
    assert not vscode.setup_vscode(tmp_path)
    assert not (tmp_path / ".vscode").exists()


def test_setup_when_install_fails(tmp_path, monkeypatch):
    def fail(args, **kwargs):
        raise subprocess.CalledProcessError(1, args, stderr="boom")

    monkeypatch.setattr(vscode.shutil, "which", lambda name: "/usr/bin/code")
    monkeypatch.setattr(vscode.subprocess, "run", fail)
    assert not vscode.setup_vscode(tmp_path)
    assert not (tmp_path / ".vscode").exists()
