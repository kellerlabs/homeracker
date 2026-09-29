"""Command-line interface for scadfmt."""

import argparse
import difflib
import logging
import sys
from pathlib import Path

from scadfmt import __version__
from scadfmt.fileio import ENCODING, write_atomically
from scadfmt.formatter import FormatError, format_source
from scadfmt.vscode import choose_workspace, setup_vscode

logger = logging.getLogger(__name__)

EXIT_OK = 0
EXIT_CHANGES = 1
EXIT_ERROR = 2


def _collect(paths: list[str]) -> list[Path]:
    """Expand directories to the .scad files below them, sorted."""
    files: list[Path] = []
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            files.extend(sorted(path.rglob("*.scad")))
        else:
            files.append(path)
    return files


def _diff(before: str, after: str, name: str) -> str:
    """Unified diff between two versions of a file."""
    return "".join(
        difflib.unified_diff(
            before.splitlines(keepends=True),
            after.splitlines(keepends=True),
            f"{name} (original)",
            f"{name} (formatted)",
        )
    )


def _write(text: str) -> None:
    """Write UTF-8 text to stdout without newline translation."""
    sys.stdout.buffer.write(text.encode(ENCODING))
    sys.stdout.buffer.flush()


def _format_stdin(check: bool, diff: bool) -> int:
    """Format stdin to stdout, or report on it with --check or --diff."""
    # Bytes, not text: text mode would translate newlines and use the locale codepage on Windows.
    try:
        source = sys.stdin.buffer.read().decode(ENCODING)
        formatted = format_source(source)
    except (UnicodeDecodeError, FormatError) as e:
        logger.error("<stdin>:%s", e)
        return EXIT_ERROR
    if diff:
        _write(_diff(source, formatted, "<stdin>"))
    elif not check:
        _write(formatted)
    return EXIT_CHANGES if check and formatted != source else EXIT_OK


def _format_files(files: list[Path], check: bool, diff: bool) -> int:
    """Format files in place, or report on them with --check or --diff."""
    changed = failed = False  # pragma: no mutate  (None reads the same)
    for path in files:
        try:
            source = path.read_bytes().decode(ENCODING)
            formatted = format_source(source)
        except (OSError, UnicodeDecodeError, FormatError) as e:
            logger.error("%s:%s", path, e)
            failed = True
            continue
        if formatted == source:
            continue
        changed = True
        if diff:
            _write(_diff(source, formatted, str(path)))
        if check or diff:
            logger.info("would reformat %s", path)
        else:
            try:
                write_atomically(path, formatted)
            except OSError as e:
                logger.error("%s: cannot write: %s", path, e)
                failed = True
                continue
            logger.info("reformatted %s", path)
    if failed:
        return EXIT_ERROR
    return EXIT_CHANGES if check and changed else EXIT_OK


def _handle_format(args: argparse.Namespace) -> int:
    """Run the format subcommand."""
    if args.paths == ["-"]:
        return _format_stdin(args.check, args.diff)
    if "-" in args.paths:
        logger.error("'-' (stdin) cannot be combined with file paths")
        return EXIT_ERROR
    return _format_files(_collect(args.paths), args.check, args.diff)


def _handle_vscode(args: argparse.Namespace) -> int:
    """Run the vscode subcommand, asking for the workspace when --workspace has no path."""
    if args.workspace:
        target = Path(args.workspace)
    else:
        try:
            target = choose_workspace(Path.cwd())
        except EOFError:
            target = None
        if target is None:
            logger.error("No workspace given. Pass it as --workspace <path>.")
            return EXIT_ERROR
    return EXIT_OK if setup_vscode(target) else EXIT_ERROR


def build_parser() -> argparse.ArgumentParser:
    """Build the argument parser.

    Returns:
        The configured parser.
    """
    # Help texts sit on their own lines, where mutation testing skips them (see [tool.mutmut] in pyproject.toml).
    parser = argparse.ArgumentParser(
        prog="scadfmt",
        description="Opinionated formatter for OpenSCAD code.",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    subparsers = parser.add_subparsers(dest="command", required=True)

    format_parser = subparsers.add_parser(
        "format",
        help="Format .scad files in place",
    )
    format_parser.add_argument(
        "paths",
        nargs="+",
        help="Files or directories to format, or '-' for stdin",
    )
    format_parser.add_argument(
        "--check",
        action="store_true",
        help="Write nothing, exit 1 if any file would change",
    )
    format_parser.add_argument(
        "--diff",
        action="store_true",
        help="Write nothing, print a diff of the changes",
    )

    vscode_parser = subparsers.add_parser(
        "vscode",
        help="Make scadfmt the VS Code formatter for .scad files",
    )
    vscode_parser.add_argument(
        "--workspace",
        nargs="?",
        default=".",
        const="",
        help="Workspace folder (its .vscode/settings.json) or .code-workspace file to update (default: .);"
        " without a path, asks about the nearest .code-workspace file",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    """Run scadfmt.

    Args:
        argv: Arguments without the program name. Defaults to sys.argv[1:].

    Returns:
        Exit code: 0 clean, 1 files would change (--check), 2 error.
    """
    # No mutation: format=None formats as "%(message)s" too. test_log_lines_are_plain_messages covers the rest.
    logging.basicConfig(level=logging.INFO, format="%(message)s")  # pragma: no mutate
    args = build_parser().parse_args(argv)
    if args.command == "vscode":
        return _handle_vscode(args)
    return _handle_format(args)


if __name__ == "__main__":
    sys.exit(main())
