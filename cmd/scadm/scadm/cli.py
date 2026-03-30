"""CLI interface for scadm."""

import argparse
import logging
import sys
from importlib.metadata import version, PackageNotFoundError
from pathlib import Path

from scadm.flatten import compute_checksum, flatten_all, flatten_file
from scadm.installer import install_libraries, install_openscad
from scadm.render import discover_flatten_files, render_files
from scadm.vscode import setup_openscad_extension, setup_python_extension

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s", handlers=[logging.StreamHandler()])
logger = logging.getLogger(__name__)

# Get version from package metadata
try:
    __version__ = version("scadm")
except PackageNotFoundError:
    __version__ = "unknown"


def _handle_vscode(args, vscode_parser):
    """Handle the vscode subcommand."""
    if args.openscad:
        success = setup_openscad_extension()
        sys.exit(0 if success else 1)
    elif args.python:
        success = setup_python_extension()
        sys.exit(0 if success else 1)
    else:
        vscode_parser.print_help()
        sys.exit(0)


def _handle_install(args):
    """Handle the install subcommand."""
    success = True

    try:
        if not args.libs_only:
            if not install_openscad(force=args.force, check_only=args.check, info=args.info):
                success = False
                if not args.check and not args.info:
                    logger.error("OpenSCAD installation failed. Aborting.")
                    sys.exit(1)

        if not args.openscad_only and not args.info:
            if not install_libraries(force=args.force, check_only=args.check):
                success = False
    except FileNotFoundError as e:
        logger.error("%s", e)
        logger.error("Create a scadm.json file in your project root to get started.")
        sys.exit(1)

    sys.exit(0 if success else 1)


def _handle_flatten(args, flatten_parser):
    """Handle the flatten subcommand."""
    try:
        if args.checksum:
            if not args.file:
                logger.error("--checksum requires a file argument")
                sys.exit(1)
            checksum = compute_checksum(Path(args.file).resolve())
            print(checksum)
            sys.exit(0)

        if args.flatten_all:
            success = flatten_all()
            sys.exit(0 if success else 1)

        if args.file:
            if not args.output:
                logger.error("Single-file mode requires -o/--output")
                sys.exit(1)
            flatten_file(Path(args.file).resolve(), Path(args.output).resolve())
            sys.exit(0)

        flatten_parser.print_help()
        sys.exit(1)
    except (FileNotFoundError, ValueError) as e:
        logger.error("%s", e)
        sys.exit(1)


def _handle_render(args, render_parser):
    """Handle the render subcommand."""
    has_flags = args.source or args.flattened

    if args.files and has_flags:
        logger.error("Cannot combine explicit files with --source/--flattened")
        sys.exit(1)

    if not args.files and not has_flags:
        render_parser.print_help()
        sys.exit(1)

    try:
        if has_flags:
            files = discover_flatten_files(source=args.source, flattened=args.flattened)
        else:
            files = [f.resolve() for f in args.files]

        sys.exit(0 if render_files(files) else 1)
    except (FileNotFoundError, ValueError) as e:
        logger.error("%s", e)
        sys.exit(1)


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        prog="scadm",
        description="OpenSCAD Dependency Manager - Install OpenSCAD and manage library dependencies",
    )

    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
        help="Show the currently installed version of scadm",
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Install command
    install_parser = subparsers.add_parser("install", help="Install OpenSCAD and libraries")
    install_parser.add_argument("--check", action="store_true", help="Check installation status only")
    install_parser.add_argument("--force", action="store_true", help="Force reinstall")
    install_parser.add_argument("--info", action="store_true", help="Show OpenSCAD version info")
    install_parser.add_argument("--openscad-only", action="store_true", help="Install only OpenSCAD binary")
    install_parser.add_argument("--libs-only", action="store_true", help="Install only libraries")

    # VSCode command
    vscode_parser = subparsers.add_parser("vscode", help="Configure VS Code extensions")
    vscode_parser.add_argument("--openscad", action="store_true", help="Install and configure OpenSCAD extension")
    vscode_parser.add_argument("--python", action="store_true", help="Install and configure Python extension")

    # Flatten command
    flatten_parser = subparsers.add_parser("flatten", help="Flatten .scad include trees into single files")
    flatten_parser.add_argument("file", nargs="?", help="Single .scad file to flatten")
    flatten_parser.add_argument("-o", "--output", help="Output file path (required for single-file mode)")
    flatten_parser.add_argument(
        "--all", action="store_true", dest="flatten_all", help="Batch-flatten from scadm.json config"
    )
    flatten_parser.add_argument("--checksum", action="store_true", help="Print transitive dependency checksum")

    # Render command
    render_parser = subparsers.add_parser(
        "render", help="Render .scad files via OpenSCAD to validate syntax and geometry"
    )
    render_parser.add_argument("files", nargs="*", type=Path, help=".scad files to render")
    render_parser.add_argument(
        "--source", action="store_true", help="Render source files from scadm.json flatten src dirs"
    )
    render_parser.add_argument(
        "--flattened", action="store_true", help="Render flattened output files from scadm.json flatten dest dirs"
    )

    args = parser.parse_args()

    # Show help if no command provided
    if not args.command:
        parser.print_help()
        sys.exit(0)

    handlers = {
        "vscode": lambda: _handle_vscode(args, vscode_parser),
        "install": lambda: _handle_install(args),
        "flatten": lambda: _handle_flatten(args, flatten_parser),
        "render": lambda: _handle_render(args, render_parser),
    }

    handlers[args.command]()


if __name__ == "__main__":
    main()
