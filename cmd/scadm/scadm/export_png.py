"""Export isometric preview PNGs from OpenSCAD model files."""

import logging
import os
import shutil
import subprocess
from pathlib import Path
from typing import Optional

from scadm.installer import find_openscad_exe, get_install_paths, get_system_platform, get_workspace_root

logger = logging.getLogger(__name__)

DEFAULT_CAMERA = "0,0,0,55,0,35,80"
DEFAULT_IMGSIZE = "800,600"
DEFAULT_COLORSCHEME = "BeforeDawn"


# pylint: disable-next=too-many-arguments,too-many-branches  # OpenSCAD CLI has many options; grouping would add needless abstraction
def export_png(
    input_file: Path,
    *,
    camera: str = DEFAULT_CAMERA,
    imgsize: str = DEFAULT_IMGSIZE,
    colorscheme: str = DEFAULT_COLORSCHEME,
    output: Optional[Path] = None,
    projection: Optional[str] = None,
    defines: Optional[list[str]] = None,
    param_file: Optional[Path] = None,
    param_set: Optional[str] = None,
    workspace_root: Optional[Path] = None,
) -> bool:
    """Export an isometric preview PNG from an OpenSCAD model file.

    Args:
        input_file: Path to .scad file.
        camera: Camera params (translate_x,y,z,rot_x,y,z,dist).
        imgsize: Image size (width,height).
        colorscheme: OpenSCAD color scheme name.
        output: Output file path (default: renders/<input_basename>.png).
        projection: Projection type ('o' for ortho, 'p' for perspective).
        defines: List of OpenSCAD variable overrides (key=value strings).
        param_file: Customizer parameter file (JSON).
        param_set: Parameter set name within the param file.
        workspace_root: Project root (auto-detected if None).

    Returns:
        True if export succeeded, False otherwise.
    """
    input_file = input_file.resolve()

    if workspace_root is None:
        workspace_root = get_workspace_root(input_file.parent)

    install_dir, libraries_dir = get_install_paths(workspace_root)

    openscad_exe = find_openscad_exe(install_dir)
    if openscad_exe is None:
        logger.error("OpenSCAD not found in %s. Run `scadm install` first.", install_dir)
        return False

    if not libraries_dir.is_dir():
        logger.error("Libraries directory not found: %s", libraries_dir)
        return False

    if not input_file.is_file():
        logger.error("File not found: %s", input_file)
        return False

    if output is None:
        output = input_file.parent / "renders" / input_file.with_suffix(".png").name
    else:
        output = output.resolve()

    output.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        str(openscad_exe),
        "-o",
        str(output),
        "--render",
        f"--camera={camera}",
        "--autocenter",
        "--viewall",
        f"--imgsize={imgsize}",
        f"--colorscheme={colorscheme}",
    ]

    if projection:
        cmd.append(f"--projection={projection}")
    if param_file:
        cmd.extend(["-p", str(param_file.resolve())])
    if param_set:
        cmd.extend(["-P", param_set])
    for d in defines or []:
        cmd.extend(["-D", d])

    cmd.append(str(input_file))

    if get_system_platform() == "linux" and shutil.which("xvfb-run"):
        cmd = ["xvfb-run", "-a"] + cmd

    env = os.environ.copy()
    env["OPENSCADPATH"] = str(libraries_dir)

    logger.info("Exporting PNG: %s -> %s", input_file, output)

    result = subprocess.run(cmd, env=env, capture_output=True, text=True, check=False)

    if result.returncode == 0 and output.exists():
        size = output.stat().st_size
        if size == 0:
            logger.error("Export produced empty file: %s", output)
            return False
        logger.info("Exported: %s (%d bytes)", output, size)
        return True

    logger.error("Export failed: %s", input_file.name)
    if result.stdout:
        logger.error("stdout: %s", result.stdout)
    if result.stderr:
        logger.error("stderr: %s", result.stderr)
    return False
