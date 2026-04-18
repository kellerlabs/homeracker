#!/usr/bin/env python3
"""Print pixel dimensions of image files (WebP, PNG, JPEG).

Reads image headers directly — no external dependencies required.

Usage:
    python cmd/export/image-dimensions.py path/to/images/
    python cmd/export/image-dimensions.py path/to/single-image.webp
"""

import struct
import sys
from pathlib import Path


def webp_dimensions(path: Path) -> tuple[int, int] | None:
    """Read width and height from a WebP file header.

    Args:
        path: Path to a WebP image file.

    Returns:
        Tuple of (width, height) or None if unreadable.
    """
    with path.open("rb") as f:
        header = f.read(30)
    if len(header) < 30 or header[:4] != b"RIFF" or header[8:12] != b"WEBP":
        return None
    chunk = header[12:16]
    if chunk == b"VP8 ":
        w = (header[26] | (header[27] << 8)) & 0x3FFF
        h = (header[28] | (header[29] << 8)) & 0x3FFF
        return w, h
    if chunk == b"VP8L":
        bits = int.from_bytes(header[21:25], "little")
        return (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1
    if chunk == b"VP8X":
        w = int.from_bytes(header[24:27], "little") + 1
        h = int.from_bytes(header[27:30], "little") + 1
        return w, h
    return None


def png_dimensions(path: Path) -> tuple[int, int] | None:
    """Read width and height from a PNG file header.

    Args:
        path: Path to a PNG image file.

    Returns:
        Tuple of (width, height) or None if unreadable.
    """
    with path.open("rb") as f:
        header = f.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    w, h = struct.unpack(">II", header[16:24])
    return w, h


def jpeg_dimensions(path: Path) -> tuple[int, int] | None:
    """Read width and height from a JPEG file header.

    Args:
        path: Path to a JPEG image file.

    Returns:
        Tuple of (width, height) or None if unreadable.
    """
    with path.open("rb") as f:
        if f.read(2) != b"\xff\xd8":
            return None
        while True:
            marker = f.read(2)
            if len(marker) < 2:
                return None
            if marker[0] != 0xFF:
                return None
            if marker[1] in (0xC0, 0xC1, 0xC2):
                f.read(3)  # length + precision
                h, w = struct.unpack(">HH", f.read(4))
                return w, h
            length = struct.unpack(">H", f.read(2))[0]
            f.read(length - 2)
    return None


READERS = {
    ".webp": webp_dimensions,
    ".png": png_dimensions,
    ".jpg": jpeg_dimensions,
    ".jpeg": jpeg_dimensions,
}


def get_dimensions(path: Path) -> tuple[int, int] | None:
    """Get pixel dimensions for a supported image file.

    Args:
        path: Path to an image file (.webp, .png, .jpg, .jpeg).

    Returns:
        Tuple of (width, height) or None if format unsupported/unreadable.
    """
    reader = READERS.get(path.suffix.lower())
    return reader(path) if reader else None


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <path> [path ...]", file=sys.stderr)
        sys.exit(1)

    for arg in sys.argv[1:]:
        target = Path(arg)
        files = sorted(target.iterdir()) if target.is_dir() else [target]
        for f in files:
            if f.suffix.lower() in READERS:
                dims = get_dimensions(f)
                if dims:
                    print(f"{f.name}: {dims[0]}x{dims[1]}")
                else:
                    print(f"{f.name}: <unreadable>", file=sys.stderr)


if __name__ == "__main__":
    main()
