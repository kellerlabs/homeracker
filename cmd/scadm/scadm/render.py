"""Render .scad files via OpenSCAD for validation.

Finds the bundled OpenSCAD binary, sets OPENSCADPATH to the installed libraries,
and runs a render-to-STL to validate syntax and geometry.
"""

import concurrent.futures
import logging
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Optional

from scadm.flatten import discover_scad_files, load_flatten_config
from scadm.installer import find_openscad_exe, get_install_paths, get_system_platform, get_workspace_root

logger = logging.getLogger(__name__)


def render_file(scad_file: Path, workspace_root: Optional[Path] = None) -> bool:
    """Render a single .scad file to validate it.

    Args:
        scad_file: Absolute path to .scad file.
        workspace_root: Project root (auto-detected if None).

    Returns:
        True if render succeeded, False otherwise.
    """
    if workspace_root is None:
        workspace_root = get_workspace_root(scad_file.parent)

    install_dir, libraries_dir = get_install_paths(workspace_root)

    openscad_exe = find_openscad_exe(install_dir)
    if openscad_exe is None:
        logger.error("OpenSCAD executable not found in %s. Run `scadm install` first.", install_dir)
        return False

    if not libraries_dir.is_dir():
        logger.error("Libraries directory not found: %s", libraries_dir)
        return False

    if not scad_file.is_file():
        logger.error("File not found: %s", scad_file)
        return False

    logger.info("Rendering: %s", scad_file)

    with tempfile.NamedTemporaryFile(suffix=".stl", delete=False) as tmp:
        output_file = Path(tmp.name)

    env = os.environ.copy()
    env["OPENSCADPATH"] = str(libraries_dir)

    cmd = [str(openscad_exe), "-o", str(output_file), str(scad_file), "--export-format=binstl"]

    # Use xvfb-run on Linux if available (headless rendering in CI)
    if get_system_platform() == "linux" and shutil.which("xvfb-run"):
        cmd = ["xvfb-run", "-a"] + cmd

    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True, check=False)

        if result.returncode == 0 and output_file.exists() and output_file.stat().st_size > 0:
            size = output_file.stat().st_size
            logger.info("Passed: %s (%d bytes)", scad_file.name, size)
            return True

        logger.error("Failed: %s", scad_file.name)
        if result.stdout:
            logger.error("stdout: %s", result.stdout)
        if result.stderr:
            logger.error("stderr: %s", result.stderr)
        return False
    finally:
        output_file.unlink(missing_ok=True)


def render_files(
    files: list[Path],
    workspace_root: Optional[Path] = None,
    max_workers: Optional[int] = None,
) -> bool:
    """Render multiple .scad files in parallel.

    Args:
        files: List of .scad file paths.
        workspace_root: Project root (auto-detected if None).
        max_workers: Max parallel renders. Defaults to os.cpu_count().

    Returns:
        True if all renders succeeded.
    """
    if workspace_root is None:
        workspace_root = get_workspace_root()

    if max_workers is None:
        max_workers = os.cpu_count() or 1
    elif max_workers < 1:
        raise ValueError(f"--jobs must be at least 1, got {max_workers}")

    workers = min(max_workers, len(files))
    logger.info("Rendering %d file(s) with %d worker(s)", len(files), workers)

    failed = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(render_file, f, workspace_root): f for f in files}
        for future in concurrent.futures.as_completed(futures):
            if not future.result():
                failed += 1

    if failed:
        logger.error("%d render(s) failed", failed)
    else:
        logger.info("All %d render(s) passed", len(files))
    return failed == 0


def discover_flatten_files(
    workspace_root: Optional[Path] = None,
    *,
    source: bool = False,
    flattened: bool = False,
) -> list[Path]:
    """Discover .scad files from scadm.json flatten config.

    Args:
        workspace_root: Project root (auto-detected if None).
        source: Include source files (flatten src dirs).
        flattened: Include flattened output files (flatten dest dirs).

    Returns:
        Sorted list of absolute .scad file paths.

    Raises:
        FileNotFoundError: If scadm.json not found.
        ValueError: If neither flag is set, no flatten config, or no files found.
    """
    if not source and not flattened:
        raise ValueError("At least one of source or flattened must be True.")

    if workspace_root is None:
        workspace_root = get_workspace_root()

    entries = load_flatten_config(workspace_root)
    files: list[Path] = []
    missing: list[str] = []

    for entry in entries:
        src_dir = (workspace_root / entry["src"]).resolve()
        dest_dir = (workspace_root / entry["dest"]).resolve()

        if source:
            if src_dir.is_dir():
                files.extend(discover_scad_files(src_dir, dest_dir))
            else:
                missing.append(f"src: {entry['src']}")

        if flattened:
            if dest_dir.is_dir():
                files.extend(sorted(dest_dir.rglob("*.scad")))
            else:
                missing.append(f"dest: {entry['dest']}")

    if missing:
        raise ValueError(f"Configured flatten directories not found: {', '.join(missing)}")

    if not files:
        raise ValueError("No .scad files found in flatten config directories.")
    return sorted(set(files))
