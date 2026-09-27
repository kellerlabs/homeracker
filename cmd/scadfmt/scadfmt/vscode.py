"""Register scadfmt as the VS Code formatter for OpenSCAD files."""

import json
import logging
import platform
import shutil
import subprocess
import sys
from pathlib import Path

from scadfmt.fileio import write_atomically

logger = logging.getLogger(__name__)

EXTENSION = "jkillian.custom-local-formatters"
LANGUAGE = "scad"


def formatter_command() -> str:
    """Command VS Code runs to format a document: this interpreter, so it works in any install location.

    Returns:
        A shell command reading source on stdin and writing it formatted to stdout.
    """
    return f'"{sys.executable}" -m scadfmt format -'


def merge_settings(settings: dict) -> dict:
    """Add the scadfmt formatter to VS Code settings, replacing any other formatter for `scad`.

    Args:
        settings: Existing settings.json content.

    Returns:
        The updated settings (the same dict).
    """
    formatters = [
        entry
        for entry in settings.get("customLocalFormatters.formatters", [])
        if LANGUAGE not in entry.get("languages", [])
    ]
    formatters.append({"command": formatter_command(), "languages": [LANGUAGE]})
    settings["customLocalFormatters.formatters"] = formatters
    settings.setdefault(f"[{LANGUAGE}]", {})["editor.defaultFormatter"] = EXTENSION
    return settings


def _install_extension() -> bool:
    """Install the Custom Local Formatters extension with the `code` CLI."""
    if not shutil.which("code"):
        logger.error("VS Code CLI 'code' not found. Install VS Code and enable 'Add to PATH'.")
        return False
    try:
        subprocess.run(
            ["code", "--install-extension", EXTENSION, "--force"],
            check=True,
            capture_output=True,
            text=True,
            # code is a .cmd script on Windows, which only the shell resolves.
            shell=platform.system() == "Windows",
        )
    except subprocess.CalledProcessError as e:
        logger.error("Failed to install %s: %s", EXTENSION, e.stderr)
        return False
    logger.info("Installed %s", EXTENSION)
    return True


def setup_vscode(workspace: Path) -> bool:
    """Install the extension and point it at scadfmt in the workspace settings.

    Args:
        workspace: Workspace folder; its .vscode/settings.json is created or updated.

    Returns:
        True on success, False otherwise.
    """
    settings_file = workspace / ".vscode" / "settings.json"
    settings = {}
    if settings_file.exists():
        try:
            settings = json.loads(settings_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            # Comments or trailing commas: refuse rather than overwrite hand-written settings.
            logger.error(
                "%s is not plain JSON (%s). Add the settings from the scadfmt README by hand.", settings_file, e
            )
            return False
    if not _install_extension():
        return False
    try:
        settings_file.parent.mkdir(parents=True, exist_ok=True)
        write_atomically(settings_file, json.dumps(merge_settings(settings), indent=2, sort_keys=True) + "\n")
    except OSError as e:
        logger.error("Cannot write %s: %s", settings_file, e)
        return False
    logger.info("Updated %s, scadfmt now formats .scad files (Format Document)", settings_file)
    return True
