"""Tests for the version resolver module."""

import json
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from scadm.resolver import (
    _read_cache,
    _write_cache,
    resolve_latest_nightly,
    resolve_latest_stable,
    resolve_version,
)


SNAPSHOT_HTML = """
<html><body>
<a href="OpenSCAD-2026.03.20-x86-64.zip">OpenSCAD-2026.03.20-x86-64.zip</a>
<a href="OpenSCAD-2026.03.28-x86-64.zip">OpenSCAD-2026.03.28-x86-64.zip</a>
<a href="OpenSCAD-2026.03.15-x86-64.zip">OpenSCAD-2026.03.15-x86-64.zip</a>
<a href="OpenSCAD-2026.03.20-x86_64.AppImage">OpenSCAD-2026.03.20-x86_64.AppImage</a>
<a href="OpenSCAD-2026.03.28-x86_64.AppImage">OpenSCAD-2026.03.28-x86_64.AppImage</a>
<a href="OpenSCAD-2026.03.15-x86_64.AppImage">OpenSCAD-2026.03.15-x86_64.AppImage</a>
</body></html>
"""


class ResolveLatestNightlyTests(unittest.TestCase):
    """Tests for resolve_latest_nightly."""

    @patch("scadm.resolver.urllib.request.urlopen")
    def test_returns_latest_windows_version(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.read.return_value = SNAPSHOT_HTML.encode()
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response

        result = resolve_latest_nightly("windows")
        self.assertEqual(result, "2026.03.28")

    @patch("scadm.resolver.urllib.request.urlopen")
    def test_returns_latest_linux_version(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.read.return_value = SNAPSHOT_HTML.encode()
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response

        result = resolve_latest_nightly("linux")
        self.assertEqual(result, "2026.03.28")

    @patch("scadm.resolver.urllib.request.urlopen")
    def test_no_versions_raises(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.read.return_value = b"<html><body>nothing here</body></html>"
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response

        with self.assertRaises(RuntimeError):
            resolve_latest_nightly("linux")

    @patch("scadm.resolver.urllib.request.urlopen")
    def test_network_error_raises(self, mock_urlopen):
        import urllib.error

        mock_urlopen.side_effect = urllib.error.URLError("connection failed")

        with self.assertRaises(RuntimeError):
            resolve_latest_nightly("linux")


class ResolveLatestStableTests(unittest.TestCase):
    """Tests for resolve_latest_stable."""

    @patch("scadm.resolver.urllib.request.urlopen")
    def test_returns_stable_version(self, mock_urlopen):
        api_response = json.dumps({"tag_name": "openscad-2021.01"}).encode()
        mock_response = MagicMock()
        mock_response.read.return_value = api_response
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response

        result = resolve_latest_stable()
        self.assertEqual(result, "2021.01")

    @patch("scadm.resolver.urllib.request.urlopen")
    def test_strips_openscad_prefix(self, mock_urlopen):
        api_response = json.dumps({"tag_name": "openscad-2025.01"}).encode()
        mock_response = MagicMock()
        mock_response.read.return_value = api_response
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response

        result = resolve_latest_stable()
        self.assertEqual(result, "2025.01")

    @patch("scadm.resolver.urllib.request.urlopen")
    def test_no_prefix_tag(self, mock_urlopen):
        api_response = json.dumps({"tag_name": "2025.01"}).encode()
        mock_response = MagicMock()
        mock_response.read.return_value = api_response
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response

        result = resolve_latest_stable()
        self.assertEqual(result, "2025.01")

    @patch("scadm.resolver.urllib.request.urlopen")
    def test_missing_tag_raises(self, mock_urlopen):
        api_response = json.dumps({}).encode()
        mock_response = MagicMock()
        mock_response.read.return_value = api_response
        mock_response.__enter__ = MagicMock(return_value=mock_response)
        mock_response.__exit__ = MagicMock(return_value=False)
        mock_urlopen.return_value = mock_response

        with self.assertRaises(RuntimeError):
            resolve_latest_stable()


class ResolveVersionTests(unittest.TestCase):
    """Tests for resolve_version."""

    def test_pinned_version_returns_as_is(self):
        result = resolve_version("nightly", "2026.03.28", "linux")
        self.assertEqual(result, "2026.03.28")

    def test_pinned_stable_returns_as_is(self):
        result = resolve_version("stable", "2021.01", "linux")
        self.assertEqual(result, "2021.01")

    @patch("scadm.resolver.resolve_latest_nightly")
    def test_latest_nightly_resolves(self, mock_resolve):
        mock_resolve.return_value = "2026.03.28"
        result = resolve_version("nightly", "latest", "linux")
        self.assertEqual(result, "2026.03.28")
        mock_resolve.assert_called_once_with("linux")

    @patch("scadm.resolver.resolve_latest_stable")
    def test_latest_stable_resolves(self, mock_resolve):
        mock_resolve.return_value = "2021.01"
        result = resolve_version("stable", "latest", "linux")
        self.assertEqual(result, "2021.01")
        mock_resolve.assert_called_once()

    @patch("scadm.resolver.resolve_latest_nightly")
    def test_cache_read(self, mock_resolve, tmp_path=None):
        import tempfile

        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            (install_dir / ".resolved-version").write_text("2026.03.20", encoding="utf-8")

            result = resolve_version("nightly", "latest", "linux", install_dir=install_dir)
            self.assertEqual(result, "2026.03.20")
            mock_resolve.assert_not_called()

    @patch("scadm.resolver.resolve_latest_nightly")
    def test_cache_bypass_with_force(self, mock_resolve):
        import tempfile

        mock_resolve.return_value = "2026.03.28"
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            (install_dir / ".resolved-version").write_text("2026.03.20", encoding="utf-8")

            result = resolve_version("nightly", "latest", "linux", install_dir=install_dir, force=True)
            self.assertEqual(result, "2026.03.28")
            mock_resolve.assert_called_once()

    @patch("scadm.resolver.resolve_latest_nightly")
    def test_cache_write(self, mock_resolve):
        import tempfile

        mock_resolve.return_value = "2026.03.28"
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)

            resolve_version("nightly", "latest", "linux", install_dir=install_dir)

            cache_file = install_dir / ".resolved-version"
            self.assertTrue(cache_file.exists())
            self.assertEqual(cache_file.read_text(encoding="utf-8"), "2026.03.28")


class CacheTests(unittest.TestCase):
    """Tests for cache read/write helpers."""

    def test_read_cache_missing(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmpdir:
            result = _read_cache(Path(tmpdir))
            self.assertIsNone(result)

    def test_read_cache_exists(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmpdir:
            cache_file = Path(tmpdir) / ".resolved-version"
            cache_file.write_text("2026.03.28", encoding="utf-8")
            result = _read_cache(Path(tmpdir))
            self.assertEqual(result, "2026.03.28")

    def test_write_cache_creates_file(self):
        import tempfile

        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir) / "openscad"
            _write_cache(install_dir, "2026.03.28")
            cache_file = install_dir / ".resolved-version"
            self.assertTrue(cache_file.exists())
            self.assertEqual(cache_file.read_text(encoding="utf-8"), "2026.03.28")


if __name__ == "__main__":
    unittest.main()
