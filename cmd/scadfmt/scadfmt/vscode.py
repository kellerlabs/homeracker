"""Register scadfmt as the VS Code formatter for OpenSCAD files."""

import json
import logging
import platform
import re
import shutil
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path

from scadfmt.fileio import ENCODING, write_atomically

logger = logging.getLogger(__name__)

EXTENSION = "jkillian.custom-local-formatters"
LANGUAGE = "scad"
WORKSPACE_SUFFIX = ".code-workspace"


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


def find_workspace_file(start: Path) -> Path | None:
    """Find the nearest .code-workspace file in start or a folder above it.

    Args:
        start: Folder to search first.

    Returns:
        The first match by name in the nearest folder that has one, or None.
    """
    for folder in [start, *start.parents]:
        found = sorted(folder.glob(f"*{WORKSPACE_SUFFIX}"))
        if found:
            return found[0]
    return None


def choose_workspace(start: Path, ask: Callable[[str], str] = input) -> Path | None:
    """Ask which workspace to update, offering the nearest .code-workspace file first.

    Args:
        start: Folder to search from.
        ask: Prompts and returns the answer.

    Returns:
        The chosen .code-workspace file or workspace folder, or None when no path was given.

    Raises:
        EOFError: If stdin is closed.
    """
    found = find_workspace_file(start)
    if found and ask(f"Use workspace file {found}? [Y/n] ").strip().lower() in ("", "y", "yes"):
        return found
    # Windows "Copy as path" wraps the path in quotes.
    answer = ask("Workspace file or folder: ").strip().strip('"')
    return Path(answer) if answer else None


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


def _indent(text: str) -> str:
    """Indentation of the first indented line, so a rewrite keeps the file's style (VS Code writes tabs)."""
    match = re.search(r"^([ \t]+)\S", text, re.MULTILINE)
    return match.group(1) if match else "  "


def setup_vscode(target: Path) -> bool:
    """Install the extension and point it at scadfmt in the workspace settings.

    Args:
        target: A .code-workspace file, whose settings block is updated, or a workspace folder, whose
            .vscode/settings.json is created or updated.

    Returns:
        True on success, False otherwise.
    """
    workspace_file = target.suffix == WORKSPACE_SUFFIX
    settings_file = target if workspace_file else target / ".vscode" / "settings.json"
    if workspace_file and not settings_file.is_file():
        logger.error("Workspace file %s not found.", settings_file)
        return False
    text = ""
    data = {}
    if settings_file.exists():
        try:
            text = settings_file.read_text(encoding=ENCODING)
            data = json.loads(text)
        except json.JSONDecodeError as e:
            # Comments or trailing commas: refuse rather than overwrite hand-written settings.
            logger.error(
                "%s is not plain JSON (%s). Add the settings from the scadfmt README by hand.", settings_file, e
            )
            return False
        except (OSError, UnicodeDecodeError) as e:
            logger.error("Cannot read %s: %s", settings_file, e)
            return False
    if not _install_extension():
        return False
    merge_settings(data.setdefault("settings", {}) if workspace_file else data)
    try:
        settings_file.parent.mkdir(parents=True, exist_ok=True)
        write_atomically(settings_file, json.dumps(data, indent=_indent(text), ensure_ascii=False) + "\n")
    except OSError as e:
        logger.error("Cannot write %s: %s", settings_file, e)
        return False
    logger.info("Updated %s, scadfmt now formats .scad files (Format Document)", settings_file)
    return True
