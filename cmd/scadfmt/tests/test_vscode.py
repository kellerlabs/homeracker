"""Tests for scadfmt.vscode."""

import json
import subprocess
import sys
from pathlib import Path

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
            {"command": "no languages"},
        ],
        "[scad]": {"editor.tabSize": 2},
        "other": True,
    }
    merged = vscode.merge_settings(settings)
    assert merged["customLocalFormatters.formatters"] == [
        {"command": "keep", "languages": ["yaml"]},
        {"command": "no languages"},
        {"command": vscode.formatter_command(), "languages": ["scad"]},
    ]
    assert merged["[scad]"] == {"editor.tabSize": 2, "editor.defaultFormatter": vscode.EXTENSION}
    assert merged["other"] is True


def test_setup_creates_settings(tmp_path, fake_code):
    workspace = tmp_path / "new" / "workspace"
    assert vscode.setup_vscode(workspace)
    assert fake_code == [["code", "--install-extension", vscode.EXTENSION, "--force"]]
    expected = {
        "customLocalFormatters.formatters": [{"command": vscode.formatter_command(), "languages": ["scad"]}],
        "[scad]": {"editor.defaultFormatter": vscode.EXTENSION},
    }
    text = (workspace / ".vscode" / "settings.json").read_text(encoding="utf-8")
    assert text == json.dumps(expected, indent=2) + "\n"


@pytest.mark.parametrize(("system", "shell"), [("Linux", False), ("Windows", True)])
def test_install_runs_code_cli(monkeypatch, system, shell):
    looked_up, calls = [], []
    monkeypatch.setattr(vscode.shutil, "which", lambda name: looked_up.append(name) or "/usr/bin/code")
    monkeypatch.setattr(vscode.platform, "system", lambda: system)
    monkeypatch.setattr(vscode.subprocess, "run", lambda args, **kwargs: calls.append(kwargs))
    assert vscode._install_extension()  # pylint: disable=protected-access
    assert looked_up == ["code"]
    assert calls == [{"check": True, "capture_output": True, "text": True, "shell": shell}]


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


def test_setup_refuses_unreadable_settings(tmp_path, fake_code):
    settings_file = tmp_path / ".vscode" / "settings.json"
    settings_file.parent.mkdir()
    settings_file.write_bytes(b"\xff\xfe")
    assert not vscode.setup_vscode(tmp_path)
    assert settings_file.read_bytes() == b"\xff\xfe"
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


def test_find_workspace_file_prefers_nearest_folder(tmp_path):
    (tmp_path / "outer.code-workspace").write_text("{}", encoding="utf-8")
    inner = tmp_path / "repo" / "sub"
    inner.mkdir(parents=True)
    assert vscode.find_workspace_file(inner) == tmp_path / "outer.code-workspace"
    (inner / "b.code-workspace").write_text("{}", encoding="utf-8")
    (inner / "a.code-workspace").write_text("{}", encoding="utf-8")
    assert vscode.find_workspace_file(inner) == inner / "a.code-workspace"


def test_find_workspace_file_without_one(tmp_path, monkeypatch):
    monkeypatch.setattr(vscode.Path, "glob", lambda self, pattern: iter([]))
    assert vscode.find_workspace_file(tmp_path) is None


def _asker(answers):
    prompts = []

    def ask(prompt):
        prompts.append(prompt)
        return answers.pop(0)

    return ask, prompts


def test_choose_workspace_asks_for_path_when_none_found(tmp_path, monkeypatch):
    monkeypatch.setattr(vscode, "find_workspace_file", lambda start: None)
    ask, prompts = _asker(['"C:/x/other.code-workspace" '])
    assert vscode.choose_workspace(tmp_path, ask) == Path("C:/x/other.code-workspace")
    assert prompts == ["Workspace file or folder: "]


@pytest.mark.parametrize("answer", ["", "y", " YES "])
def test_choose_workspace_accepts_found_file(tmp_path, answer):
    found = tmp_path / "w.code-workspace"
    found.write_text("{}", encoding="utf-8")
    ask, prompts = _asker([answer])
    assert vscode.choose_workspace(tmp_path, ask) == found
    assert prompts == [f"Use workspace file {found}? [Y/n] "]


@pytest.mark.parametrize(("typed", "expected"), [("other.code-workspace", Path("other.code-workspace")), ("", None)])
def test_choose_workspace_asks_for_another_file(tmp_path, typed, expected):
    (tmp_path / "w.code-workspace").write_text("{}", encoding="utf-8")
    ask, prompts = _asker(["n", typed])
    assert vscode.choose_workspace(tmp_path, ask) == expected
    assert prompts[1] == "Workspace file or folder: "


def test_setup_updates_workspace_file(tmp_path, fake_code):
    workspace_file = tmp_path / "w.code-workspace"
    workspace_file.write_text(
        '{\n\t"folders": [{"path": "repo"}],\n\t"settings": {"z": "Pötz", "a": 1}\n}', encoding="utf-8"
    )
    assert vscode.setup_vscode(workspace_file)
    assert fake_code
    expected = {
        "folders": [{"path": "repo"}],
        "settings": {
            "z": "Pötz",
            "a": 1,
            "customLocalFormatters.formatters": [{"command": vscode.formatter_command(), "languages": ["scad"]}],
            "[scad]": {"editor.defaultFormatter": vscode.EXTENSION},
        },
    }
    text = workspace_file.read_text(encoding="utf-8")
    assert text == json.dumps(expected, indent="\t", ensure_ascii=False) + "\n"
    assert not (tmp_path / ".vscode").exists()


def test_setup_adds_settings_block_to_workspace_file(tmp_path, fake_code):
    workspace_file = tmp_path / "w.code-workspace"
    workspace_file.write_text('{"folders": []}', encoding="utf-8")
    assert vscode.setup_vscode(workspace_file)
    data = json.loads(workspace_file.read_text(encoding="utf-8"))
    assert data["settings"] == vscode.merge_settings({})


def test_setup_refuses_missing_workspace_file(tmp_path, fake_code):
    assert not vscode.setup_vscode(tmp_path / "missing.code-workspace")
    assert not fake_code
    assert not list(tmp_path.iterdir())
