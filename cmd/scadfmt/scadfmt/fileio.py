"""Atomic file writes shared by formatting and VS Code setup."""

import os
import shutil
import tempfile
from pathlib import Path

# Explicit everywhere: the locale default is not UTF-8 on Windows.
ENCODING = "utf-8"


def write_atomically(path: Path, text: str) -> None:
    """Replace the file at path with text in one step, so a failed write never leaves a truncated file.

    A symlink is followed and its target updated. An existing file keeps its permissions.

    Args:
        path: File to write, created if missing.
        text: New content, written as UTF-8 without newline translation.

    Raises:
        OSError: If the temporary file cannot be written or moved into place.
    """
    target = path.resolve()
    handle, temp_name = tempfile.mkstemp(dir=target.parent, prefix=f".{target.name}.", suffix=".tmp")
    try:
        with os.fdopen(handle, "wb") as temp:
            temp.write(text.encode(ENCODING))
        if target.exists():
            shutil.copymode(target, temp_name)
        os.replace(temp_name, target)
    except OSError:
        Path(temp_name).unlink()
        raise
