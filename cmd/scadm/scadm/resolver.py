"""Version resolution for OpenSCAD installations."""

import json
import logging
import re
import urllib.error
import urllib.request
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

SNAPSHOTS_URL = "https://files.openscad.org/snapshots/"
GITHUB_API_LATEST = "https://api.github.com/repos/openscad/openscad/releases/latest"

# Patterns for extracting nightly versions from snapshot filenames
WINDOWS_PATTERN = re.compile(r"OpenSCAD-(\d{4}\.\d{2}\.\d{2})-x86-64\.zip")
LINUX_PATTERN = re.compile(r"OpenSCAD-(\d{4}\.\d{2}\.\d{2})-x86_64\.AppImage")

RESOLVED_VERSION_FILE = ".resolved-version"


def resolve_latest_nightly(os_name: str) -> str:
    """Resolve the latest nightly version by scraping the snapshots page.

    Args:
        os_name: Operating system name ('windows' or 'linux').

    Returns:
        Latest nightly version string (e.g., '2026.03.28').

    Raises:
        RuntimeError: If scraping fails or no versions found.
    """
    pattern = WINDOWS_PATTERN if os_name == "windows" else LINUX_PATTERN

    try:
        logger.debug("Fetching snapshot listing from %s", SNAPSHOTS_URL)
        req = urllib.request.Request(SNAPSHOTS_URL, headers={"User-Agent": "scadm"})
        with urllib.request.urlopen(req, timeout=30) as response:
            html = response.read().decode("utf-8")
    except (urllib.error.URLError, OSError) as e:
        raise RuntimeError(f"Failed to fetch snapshots page: {e}") from e

    versions = sorted(set(pattern.findall(html)), reverse=True)
    if not versions:
        raise RuntimeError(f"No nightly versions found for {os_name} at {SNAPSHOTS_URL}")

    return versions[0]


def resolve_latest_stable() -> str:
    """Resolve the latest stable version from GitHub releases.

    Returns:
        Latest stable version string (e.g., '2021.01').

    Raises:
        RuntimeError: If the GitHub API request fails.
    """
    try:
        logger.debug("Fetching latest stable release from GitHub API")
        req = urllib.request.Request(GITHUB_API_LATEST, headers={"User-Agent": "scadm"})
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, OSError, json.JSONDecodeError) as e:
        raise RuntimeError(f"Failed to fetch latest stable release: {e}") from e

    tag = data.get("tag_name", "")
    if not tag:
        raise RuntimeError("No tag_name found in GitHub API response")

    # Strip leading 'openscad-' prefix if present (e.g., 'openscad-2021.01' -> '2021.01')
    tag = tag.removeprefix("openscad-")

    return tag


def resolve_version(
    openscad_type: str, version: str, os_name: str, install_dir: Optional[Path] = None, force: bool = False
) -> str:
    """Resolve the target OpenSCAD version.

    Args:
        openscad_type: Build type ('nightly' or 'stable').
        version: Version string or 'latest' for automatic resolution.
        os_name: Operating system name.
        install_dir: Install directory for caching resolved version.
        force: Bypass cache and re-resolve.

    Returns:
        Resolved version string.

    Raises:
        RuntimeError: If version resolution fails.
    """
    if version != "latest":
        return version

    # Check cache
    if install_dir and not force:
        cached = _read_cache(install_dir)
        if cached:
            logger.debug("Using cached resolved version: %s", cached)
            return cached

    if openscad_type == "stable":
        resolved = resolve_latest_stable()
    else:
        resolved = resolve_latest_nightly(os_name)

    logger.info("Resolved latest %s version: %s", openscad_type, resolved)

    # Write cache
    if install_dir:
        _write_cache(install_dir, resolved)

    return resolved


def _read_cache(install_dir: Path) -> Optional[str]:
    """Read cached resolved version.

    Args:
        install_dir: Install directory containing the cache file.

    Returns:
        Cached version string, or None if not cached.
    """
    cache_file = install_dir / RESOLVED_VERSION_FILE
    if cache_file.exists():
        try:
            return cache_file.read_text(encoding="utf-8").strip()
        except OSError:
            return None
    return None


def _write_cache(install_dir: Path, version: str) -> None:
    """Write resolved version to cache.

    Args:
        install_dir: Install directory for cache file.
        version: Resolved version string to cache.
    """
    try:
        install_dir.mkdir(parents=True, exist_ok=True)
        cache_file = install_dir / RESOLVED_VERSION_FILE
        cache_file.write_text(version, encoding="utf-8")
    except OSError as e:
        logger.debug("Failed to write version cache: %s", e)
