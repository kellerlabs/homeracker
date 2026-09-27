"""Opinionated formatter for OpenSCAD code (scadfmt)."""

from importlib.metadata import PackageNotFoundError, version

# release-please bumps pyproject.toml only, so the installed metadata is the single source of truth.
try:
    __version__ = version("scadfmt")
except PackageNotFoundError:
    __version__ = "unknown"
