"""Core installer functionality for OpenSCAD and libraries."""

import json
import logging
import os
import platform
import re
import shutil
import stat
import subprocess
import tarfile
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from typing import Optional

from scadm.resolver import resolve_version

logger = logging.getLogger(__name__)


def get_workspace_root(start_path: Optional[Path] = None) -> Path:
    """Find workspace root by looking for scadm.json.

    Args:
        start_path: Starting directory (defaults to current working directory).

    Returns:
        Path to workspace root.

    Raises:
        FileNotFoundError: If scadm.json not found in any parent directory.
    """
    if start_path is None:
        start_path = Path.cwd()

    current = start_path.resolve()
    while current != current.parent:
        if (current / "scadm.json").exists():
            return current
        current = current.parent

    raise FileNotFoundError("scadm.json not found in any parent directory")


def get_install_paths(workspace_root: Optional[Path] = None):
    """Get installation directory paths.

    Args:
        workspace_root: Workspace root directory (auto-detected if None).

    Returns:
        Tuple of (install_dir, libraries_dir).
    """
    if workspace_root is None:
        workspace_root = get_workspace_root()

    install_dir = workspace_root / "bin" / "openscad"
    libraries_dir = install_dir / "libraries"
    return install_dir, libraries_dir


def download_file(url: str, dest_path: Path) -> bool:
    """Download a file from URL to dest_path.

    Args:
        url: The URL to download from.
        dest_path: The destination path to save the file.

    Returns:
        True if download succeeded, False otherwise.
    """
    try:
        logger.info("Downloading %s...", url)
        urllib.request.urlretrieve(url, dest_path)
        return True
    except urllib.error.URLError as e:
        logger.error("Failed to download %s: %s", url, e)
        return False


def get_system_platform() -> str:
    """Get system platform (windows, linux, unknown).

    Returns:
        String representing the platform ('windows', 'linux', or 'unknown').
    """
    system = platform.system().lower()
    if system == "windows":
        return "windows"
    if system in ("linux", "darwin"):
        return "linux"  # Treat macOS as Linux (AppImage)
    return "unknown"


def get_openscad_config(workspace_root: Optional[Path] = None) -> dict:
    """Read OpenSCAD configuration from scadm.json.

    Args:
        workspace_root: Workspace root directory (auto-detected if None).

    Returns:
        Dict with 'type' and 'version' keys. Defaults to nightly/latest if not configured.
    """
    defaults = {"type": "nightly", "version": "latest"}

    try:
        if workspace_root is None:
            workspace_root = get_workspace_root()
    except FileNotFoundError:
        return defaults

    config_file = workspace_root / "scadm.json"
    if not config_file.exists():
        return defaults

    try:
        with open(config_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError):
        return defaults

    openscad_config = data.get("openscad", {})
    return {
        "type": openscad_config.get("type", defaults["type"]),
        "version": openscad_config.get("version", defaults["version"]),
    }


def get_openscad_version(os_name: str = "linux", workspace_root: Optional[Path] = None, force: bool = False) -> str:
    """Get target OpenSCAD version from config.

    Args:
        os_name: Operating system name.
        workspace_root: Workspace root directory (auto-detected if None).
        force: Force re-resolve (bypass cache).

    Returns:
        Version string.
    """
    config = get_openscad_config(workspace_root)

    if workspace_root is None:
        try:
            workspace_root = get_workspace_root()
        except FileNotFoundError:
            pass

    install_dir = None
    if workspace_root:
        install_dir, _ = get_install_paths(workspace_root)

    return resolve_version(config["type"], config["version"], os_name, install_dir=install_dir, force=force)


def get_installed_openscad_version(install_dir: Path, os_name: str) -> Optional[str]:
    """Get currently installed OpenSCAD version.

    Args:
        install_dir: OpenSCAD installation directory.
        os_name: Operating system name.

    Returns:
        Version string if installed, None otherwise.
    """
    if os_name == "windows":
        exe = install_dir / "openscad.exe"
    else:
        exe = install_dir / "openscad"  # symlink to AppImage
        if not exe.exists():
            exe = install_dir / "OpenSCAD.AppImage"

    if not exe.exists():
        return None

    try:
        cmd = [str(exe), "--version"]
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        output = result.stderr + result.stdout
        # e.g. "OpenSCAD version 2024.12.06.ai20515"
        match = re.search(r"OpenSCAD version ([^\s]+)", output)
        if match:
            return match.group(1)
    except (OSError, subprocess.SubprocessError) as e:
        # Executable exists but can't run (permissions, missing libs, etc.) - treat as not installed
        logger.debug("Failed to get OpenSCAD version: %s", e)
    return None


def install_openscad_windows(install_dir: Path, version: str, nightly: bool) -> bool:
    """Install OpenSCAD on Windows.

    Args:
        install_dir: Installation directory.
        version: Version string to install.
        nightly: Whether it is a nightly build.

    Returns:
        True if successful, False otherwise.
    """
    if nightly:
        url = f"https://files.openscad.org/snapshots/OpenSCAD-{version}-x86-64.zip"
    else:
        url = f"https://files.openscad.org/OpenSCAD-{version}-x86-64.zip"

    zip_path = install_dir / f"openscad-{version}.zip"
    if not download_file(url, zip_path):
        return False

    logger.info("Extracting...")
    try:
        with zipfile.ZipFile(zip_path, "r") as zip_ref:
            temp_extract = install_dir / "temp_extract"
            zip_ref.extractall(temp_extract)

            content = list(temp_extract.iterdir())
            if len(content) == 1 and content[0].is_dir():
                source_dir = content[0]
            else:
                source_dir = temp_extract

            for item in source_dir.iterdir():
                shutil.move(str(item), str(install_dir))

            shutil.rmtree(temp_extract)

        zip_path.unlink()
        logger.info("OpenSCAD %s installed successfully!", version)
        return True
    except (zipfile.BadZipFile, OSError, shutil.Error) as e:
        logger.error("Extraction failed: %s", e)
        return False


def install_openscad_linux(install_dir: Path, version: str, nightly: bool) -> bool:
    """Install OpenSCAD on Linux.

    Args:
        install_dir: Installation directory.
        version: Version string to install.
        nightly: Whether it is a nightly build.

    Returns:
        True if successful, False otherwise.
    """
    if nightly:
        url = f"https://files.openscad.org/snapshots/OpenSCAD-{version}-x86_64.AppImage"
    else:
        url = f"https://files.openscad.org/OpenSCAD-{version}-x86_64.AppImage"

    appimage_path = install_dir / "OpenSCAD.AppImage"
    if not download_file(url, appimage_path):
        return False

    st_mode = os.stat(appimage_path).st_mode
    os.chmod(appimage_path, st_mode | stat.S_IEXEC)

    symlink_path = install_dir / "openscad"
    if symlink_path.exists():
        symlink_path.unlink()

    try:
        os.symlink("OpenSCAD.AppImage", symlink_path)
    except OSError as e:
        # Symlink creation can fail on some filesystems (FAT32, Windows without dev mode) - not critical
        logger.debug("Could not create symlink (using .AppImage directly): %s", e)

    logger.info("OpenSCAD %s installed successfully!", version)
    return True


def install_openscad(
    force: bool = False, check_only: bool = False, workspace_root: Optional[Path] = None, info: bool = False
) -> bool:
    """Install OpenSCAD binary.

    Args:
        force: Force reinstall even if version matches.
        check_only: Only check installation status.
        workspace_root: Workspace root directory (auto-detected if None).
        info: Display version info and exit.

    Returns:
        True if successful or up to date, False otherwise.
    """
    os_name = get_system_platform()
    if os_name == "unknown":
        logger.error("Unsupported platform")
        return False

    if workspace_root is None:
        workspace_root = get_workspace_root()

    config = get_openscad_config(workspace_root)
    install_dir, _ = get_install_paths(workspace_root)

    if info:
        _show_version_info(config, install_dir, os_name, force)
        return True

    target_version = resolve_version(config["type"], config["version"], os_name, install_dir=install_dir, force=force)
    nightly = config["type"] == "nightly"
    current_version = get_installed_openscad_version(install_dir, os_name)

    if check_only:
        up_to_date = current_version == target_version
        if up_to_date:
            logger.info("OpenSCAD: Up to date (%s)", target_version)
        else:
            logger.warning("OpenSCAD: Update available (%s -> %s)", current_version or "none", target_version)
        return up_to_date

    if current_version == target_version and not force:
        logger.info("OpenSCAD is up to date (%s)", target_version)
        return True

    logger.info("Installing OpenSCAD %s (%s)...", target_version, "Nightly" if nightly else "Stable")

    if install_dir.exists():
        logger.info("Cleaning old installation...")
        shutil.rmtree(install_dir)

    install_dir.mkdir(parents=True, exist_ok=True)

    if os_name == "windows":
        return install_openscad_windows(install_dir, target_version, nightly)
    return install_openscad_linux(install_dir, target_version, nightly)


def _show_version_info(config: dict, install_dir: Path, os_name: str, force: bool = False) -> None:
    """Display OpenSCAD version information.

    Args:
        config: OpenSCAD configuration dict.
        install_dir: Installation directory.
        os_name: Operating system name.
        force: Bypass cache and re-resolve.
    """
    current_version = get_installed_openscad_version(install_dir, os_name)

    logger.info("OpenSCAD Version Info:")
    logger.info("  Configured type:    %s", config["type"])
    logger.info("  Configured version: %s", config["version"])
    if config["version"] == "latest":
        try:
            resolved = resolve_version(config["type"], config["version"], os_name, install_dir=install_dir, force=force)
            logger.info("  Resolved version:   %s", resolved)
        except RuntimeError as e:
            logger.info("  Resolved version:   (unavailable: %s)", e)
    logger.info("  Installed version:  %s", current_version or "not installed")
    logger.info("  Install path:       %s", install_dir)


def get_installed_lib_version(lib_path: Path) -> Optional[str]:
    """Get installed library version.

    Args:
        lib_path: Path to the library directory.

    Returns:
        Version string if found, None otherwise.
    """
    version_file = lib_path / ".version"
    if version_file.exists():
        return version_file.read_text(encoding="utf-8").strip()
    return None


def install_library(dep: dict, libraries_dir: Path, force: bool = False) -> bool:
    """Install a single library.

    Args:
        dep: Dependency dictionary.
        libraries_dir: Directory where libraries are installed.
        force: Force reinstall.

    Returns:
        True if successful, False otherwise.
    """
    name = dep["name"]
    repo = dep["repository"]
    version = dep["version"]
    source = dep.get("source", "github")

    lib_path = libraries_dir / name
    current_version = get_installed_lib_version(lib_path)

    if current_version == version and not force:
        logger.info("%s: Up to date (%s)", name, version)
        return True

    if current_version:
        logger.info("Updating %s from %s to %s...", name, current_version, version)
    else:
        logger.info("Installing %s %s...", name, version)

    if source == "github":
        url = f"https://github.com/{repo}/archive/{version}.tar.gz"
    else:
        logger.error("Unknown source type: %s", source)
        return False

    temp_file = Path.cwd() / f"{name}-{version}.tar.gz"
    try:
        logger.info("Downloading %s...", url)
        urllib.request.urlretrieve(url, temp_file)

        if lib_path.exists():
            shutil.rmtree(lib_path)
        lib_path.mkdir(parents=True, exist_ok=True)

        logger.info("Extracting...")
        with tarfile.open(temp_file, "r:gz") as tar:
            members = []
            for member in tar.getmembers():
                p = Path(member.name)
                if len(p.parts) > 1:
                    member.name = str(Path(*p.parts[1:]))
                    members.append(member)
                elif len(p.parts) == 1:
                    members.append(member)
            tar.extractall(path=lib_path, members=members, filter="data")

        temp_file.unlink()
        (lib_path / ".version").write_text(version, encoding="utf-8")
        logger.info("%s installed successfully!", name)
        return True

    except (urllib.error.URLError, tarfile.TarError, OSError, shutil.Error) as e:
        logger.error("Failed to install %s: %s", name, e)
        if temp_file.exists():
            temp_file.unlink()
        return False


def install_libraries(force: bool = False, check_only: bool = False, workspace_root: Optional[Path] = None) -> bool:
    """Install all libraries.

    Args:
        force: Force reinstall.
        check_only: Only check status.
        workspace_root: Workspace root directory (auto-detected if None).

    Returns:
        True if all libraries processed successfully, False otherwise.
    """
    if workspace_root is None:
        workspace_root = get_workspace_root()

    dependencies_file = workspace_root / "scadm.json"
    if not dependencies_file.exists():
        logger.error("Dependencies file not found: %s", dependencies_file)
        return False

    try:
        with open(dependencies_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        logger.error("Invalid JSON in dependencies file: %s", e)
        return False

    dependencies = data.get("dependencies", [])
    success = True

    required_fields = ["name", "repository", "version"]
    for dep in dependencies:
        missing = [f for f in required_fields if f not in dep]
        if missing:
            logger.error("Dependency missing required fields: %s", missing)
            return False

    _, libraries_dir = get_install_paths(workspace_root)
    libraries_dir.mkdir(parents=True, exist_ok=True)

    for dep in dependencies:
        if check_only:
            current = get_installed_lib_version(libraries_dir / dep["name"])
            if current != dep["version"]:
                logger.warning(
                    "%s: Update available (%s -> %s)", dep["name"], current or "not installed", dep["version"]
                )
                success = False
            else:
                logger.info("%s: Up to date", dep["name"])
        else:
            if not install_library(dep, libraries_dir, force=force):
                success = False

    return success
