"""Integration tests for the scadm CLI.

These tests exercise real CLI commands against temporary workspaces.
Network-dependent tests require internet access.

Run with: python -m pytest tests/ -m integration -v
"""

import json
import os
import platform
import shutil
import subprocess

import pytest

from scadm.vscode import Extension, update_vscode_settings

SCADM = shutil.which("scadm") or "scadm"


def _run_scadm(*args, cwd, env=None):
    """Run scadm CLI and return CompletedProcess."""
    merged_env = {**os.environ, **(env or {})}
    return subprocess.run(
        [SCADM, *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        env=merged_env,
        timeout=120,
        check=False,
    )


def _write_config(workspace, openscad=None, dependencies=None):
    """Write a scadm.json to the workspace."""
    config = {}
    if openscad:
        config["openscad"] = openscad
    config["dependencies"] = dependencies or []
    (workspace / "scadm.json").write_text(json.dumps(config), encoding="utf-8")


# --- scadm --version ---


@pytest.mark.integration
def test_version_prints_and_exits_zero():
    result = subprocess.run([SCADM, "--version"], capture_output=True, text=True, timeout=10, check=False)
    assert result.returncode == 0
    assert result.stdout.strip()


# --- scadm install --info ---


@pytest.mark.integration
def test_info_latest_nightly(tmp_path):
    _write_config(tmp_path, openscad={"type": "nightly", "version": "latest"})

    result = _run_scadm("install", "--info", cwd=tmp_path)
    assert result.returncode == 0
    assert "Configured type:    nightly" in result.stderr
    assert "Configured version: latest" in result.stderr
    assert "Resolved version:" in result.stderr


@pytest.mark.integration
def test_info_pinned_nightly(tmp_path):
    _write_config(tmp_path, openscad={"type": "nightly", "version": "2026.03.28"})

    result = _run_scadm("install", "--info", cwd=tmp_path)
    assert result.returncode == 0
    assert "Configured version: 2026.03.28" in result.stderr
    assert "Resolved version:" not in result.stderr


@pytest.mark.integration
def test_info_stable_latest(tmp_path):
    _write_config(tmp_path, openscad={"type": "stable", "version": "latest"})

    result = _run_scadm("install", "--info", cwd=tmp_path)
    assert result.returncode == 0
    assert "Configured type:    stable" in result.stderr
    assert "Resolved version:" in result.stderr


@pytest.mark.integration
def test_info_default_config(tmp_path):
    _write_config(tmp_path)

    result = _run_scadm("install", "--info", cwd=tmp_path)
    assert result.returncode == 0
    assert "Configured type:    nightly" in result.stderr
    assert "Configured version: latest" in result.stderr


# --- scadm install --check ---


@pytest.mark.integration
def test_check_no_binary_returns_nonzero(tmp_path):
    _write_config(tmp_path, openscad={"type": "nightly", "version": "2026.03.28"})

    result = _run_scadm("install", "--check", cwd=tmp_path)
    assert result.returncode != 0
    assert "Update available" in result.stderr


# --- Invalid config ---


@pytest.mark.integration
def test_invalid_type_exits_nonzero(tmp_path):
    _write_config(tmp_path, openscad={"type": "invalid", "version": "latest"})

    result = _run_scadm("install", "--info", cwd=tmp_path)
    assert result.returncode != 0


@pytest.mark.integration
def test_no_scadm_json_exits_nonzero(tmp_path):
    result = _run_scadm("install", "--check", cwd=tmp_path)
    assert result.returncode != 0


# --- Cache lifecycle ---


@pytest.mark.integration
def test_cache_created_on_resolve(tmp_path):
    _write_config(tmp_path, openscad={"type": "nightly", "version": "latest"})

    _run_scadm("install", "--info", cwd=tmp_path)

    cache_file = tmp_path / "bin" / "openscad" / ".resolved-version"
    assert cache_file.exists(), "Cache file should be created after resolve"
    data = json.loads(cache_file.read_text(encoding="utf-8"))
    assert data["type"] == "nightly"
    assert "version" in data


@pytest.mark.integration
def test_force_bypasses_cache(tmp_path):
    _write_config(tmp_path, openscad={"type": "nightly", "version": "latest"})
    bin_dir = tmp_path / "bin" / "openscad"
    bin_dir.mkdir(parents=True)

    stale = json.dumps({"type": "nightly", "os": "linux", "version": "2020.01.01"})
    (bin_dir / ".resolved-version").write_text(stale, encoding="utf-8")

    result = _run_scadm("install", "--info", "--force", cwd=tmp_path)
    assert result.returncode == 0

    data = json.loads((bin_dir / ".resolved-version").read_text(encoding="utf-8"))
    assert data["version"] != "2020.01.01"


# --- Actual install (slow, downloads binary) ---


@pytest.mark.integration
@pytest.mark.slow
def test_install_openscad_only(tmp_path):
    _write_config(tmp_path, openscad={"type": "nightly", "version": "latest"})

    result = _run_scadm("install", "--openscad-only", cwd=tmp_path)
    assert result.returncode == 0, f"Install failed:\n{result.stderr}"

    bin_dir = tmp_path / "bin" / "openscad"
    if platform.system() == "Windows":
        assert (bin_dir / "openscad.exe").exists(), "openscad.exe not found"
    else:
        assert (bin_dir / "openscad").exists() or (bin_dir / "OpenSCAD.AppImage").exists(), "binary not found"


@pytest.mark.integration
@pytest.mark.slow
def test_install_check_after_install(tmp_path):
    _write_config(tmp_path, openscad={"type": "nightly", "version": "latest"})

    install_result = _run_scadm("install", "--openscad-only", cwd=tmp_path)
    assert install_result.returncode == 0, f"Install failed:\n{install_result.stderr}"

    check_result = _run_scadm("install", "--check", "--openscad-only", cwd=tmp_path)
    assert check_result.returncode == 0
    assert "Up to date" in check_result.stderr


@pytest.mark.integration
@pytest.mark.slow
def test_install_libs_only(tmp_path):
    _write_config(
        tmp_path,
        dependencies=[{"name": "BOSL2", "repository": "BelfrySCAD/BOSL2", "version": "master"}],
    )

    result = _run_scadm("install", "--libs-only", cwd=tmp_path)
    assert result.returncode == 0, f"Libs install failed:\n{result.stderr}"

    lib_dir = tmp_path / "bin" / "openscad" / "libraries" / "BOSL2"
    assert lib_dir.exists(), "BOSL2 library directory not found"


# --- scadm vscode ---


@pytest.mark.integration
def test_vscode_creates_settings(tmp_path):
    """Test settings.json generation without triggering VS Code extension install."""
    _write_config(tmp_path)

    result = update_vscode_settings(tmp_path, Extension.OPENSCAD)
    assert result, "update_vscode_settings returned False"

    settings_file = tmp_path / ".vscode" / "settings.json"
    assert settings_file.exists(), "settings.json not created"

    settings = json.loads(settings_file.read_text(encoding="utf-8"))
    assert "scad-lsp.launchPath" in settings
