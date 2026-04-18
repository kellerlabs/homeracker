"""VSCode extension management for scadm."""

import json
import logging
import platform
import shutil
import subprocess
from enum import Enum
from pathlib import Path

from scadm.installer import get_install_paths, get_workspace_root

logger = logging.getLogger(__name__)


class Extension(Enum):
    """VS Code extension identifiers with their settings configurations."""

    OPENSCAD = "Leathong.openscad-language-support"
    PYTHON = "ms-python.python"

    def get_name(self) -> str:
        """Get human-readable extension name.

        Returns:
            Title-cased name of the extension.
        """
        return self.name.title()

    def get_id(self) -> str:
        """Get extension ID.

        Returns:
            The VS Code extension identifier.
        """
        return self.value

    def get_settings(self, workspace_root: Path) -> dict:
        """Get VS Code settings for this extension.

        Args:
            workspace_root: Workspace root directory.

        Returns:
            Dictionary of settings to merge into settings.json.
        """
        if self == Extension.OPENSCAD:
            return _get_openscad_settings(workspace_root)
        if self == Extension.PYTHON:
            return _get_python_settings()
        return {}

    def get_deprecated_keys(self) -> list[str]:
        """Get settings keys that should be removed on update.

        Returns:
            List of settings keys to remove from settings.json.
        """
        if self == Extension.OPENSCAD:
            return ["scad-lsp.searchPaths"]
        return []


def _get_openscad_settings(workspace_root: Path) -> dict:
    """Get OpenSCAD extension settings.

    Args:
        workspace_root: Workspace root directory.

    Returns:
        Dictionary of OpenSCAD settings.
    """
    install_dir, _ = get_install_paths(workspace_root)

    system = platform.system()
    if system == "Windows":
        openscad_path = str(install_dir / "openscad.exe").replace("/", "\\")
    else:
        openscad_path = str(workspace_root / "cmd" / "linux" / "openscad-wrapper.sh")

    return {
        "files.associations": {"*.scad": "scad"},
        "files.eol": "\n",
        "scad-lsp.launchPath": openscad_path,
    }


def _get_python_settings() -> dict:
    """Get Python extension settings.

    Returns:
        Dictionary of Python settings.
    """
    return {
        "python.defaultInterpreterPath": "${workspaceFolder}/.venv",
    }


def install_extension(extension: Extension) -> bool:
    """Install a VS Code extension.

    Args:
        extension: The extension to install.

    Returns:
        True if installation succeeded, False otherwise.
    """
    try:
        logger.info("Installing extension %s...", extension.get_id())
        # Use shell=True on Windows to properly find code.cmd
        use_shell = platform.system() == "Windows"
        subprocess.run(
            ["code", "--install-extension", extension.get_id(), "--force"],
            check=True,
            capture_output=True,
            text=True,
            shell=use_shell,
        )
        logger.info("Extension %s installed", extension.get_id())
        return True
    except FileNotFoundError:
        logger.warning("VS Code CLI 'code' command not found")
        logger.warning("Install VS Code from: https://code.visualstudio.com/download")
        logger.warning("Make sure to enable 'Add to PATH' during installation")
        return False
    except subprocess.CalledProcessError as e:
        logger.error("Failed to install extension %s: %s", extension.get_id(), e.stderr)
        return False


def update_vscode_settings(workspace_root: Path, extension: Extension) -> bool:
    """Update VS Code settings.json with extension configuration.

    Args:
        workspace_root: Workspace root directory.
        extension: Extension to configure settings for.

    Returns:
        True if settings were updated successfully, False otherwise.
    """
    vscode_dir = workspace_root / ".vscode"
    settings_file = vscode_dir / "settings.json"

    # Load existing settings or start with empty dict
    settings = {}
    if settings_file.exists():
        try:
            with open(settings_file, "r", encoding="utf-8") as f:
                settings = json.load(f)
        except json.JSONDecodeError:
            logger.warning("Invalid JSON in settings.json, will overwrite")

    # Get extension-specific settings
    new_settings = extension.get_settings(workspace_root)

    # Deep merge settings
    for key, value in new_settings.items():
        if isinstance(value, dict) and key in settings and isinstance(settings[key], dict):
            settings[key].update(value)
        else:
            settings[key] = value

    # Remove deprecated keys
    for key in extension.get_deprecated_keys():
        if key in settings:
            logger.info("Removing deprecated setting: %s", key)
            del settings[key]

    # Write settings
    vscode_dir.mkdir(parents=True, exist_ok=True)
    try:
        with open(settings_file, "w", encoding="utf-8") as f:
            json.dump(settings, f, indent=2, sort_keys=True)
        logger.info("Updated VS Code settings")
        return True
    except OSError as e:
        logger.error("Failed to write settings.json: %s", e)
        return False


def _setup_extension(extension: Extension) -> bool:
    """Install and configure a VS Code extension.

    Args:
        extension: Extension to install and configure.

    Returns:
        True if setup succeeded, False otherwise.
    """
    if not shutil.which("code"):
        logger.warning("VS Code CLI 'code' command not found")
        logger.warning("Install VS Code from: https://code.visualstudio.com/download")
        logger.warning("Make sure to enable 'Add to PATH' during installation")
        return False

    try:
        workspace_root = get_workspace_root()
    except FileNotFoundError as e:
        logger.error("%s", e)
        return False

    if not install_extension(extension):
        return False

    if not update_vscode_settings(workspace_root, extension):
        return False

    logger.info("VS Code configured for %s", extension.get_name())
    return True


def setup_openscad_extension() -> bool:
    """Install and configure OpenSCAD extension for VS Code.

    Returns:
        True if setup succeeded, False otherwise.
    """
    return _setup_extension(Extension.OPENSCAD)


def setup_python_extension() -> bool:
    """Install and configure Python extension for VS Code.

    Returns:
        True if setup succeeded, False otherwise.
    """
    return _setup_extension(Extension.PYTHON)
