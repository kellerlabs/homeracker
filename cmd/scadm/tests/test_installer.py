"""Tests for the installer module."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scadm.installer import (
    get_openscad_config,
    get_openscad_version,
    get_installed_openscad_version,
    _write_installed_version,
)


class GetOpenscadConfigTests(unittest.TestCase):
    """Tests for get_openscad_config."""

    def test_defaults_when_no_openscad_section(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "scadm.json"
            config_file.write_text(json.dumps({"dependencies": []}), encoding="utf-8")

            result = get_openscad_config(Path(tmpdir))
            self.assertEqual(result, {"type": "nightly", "version": "latest"})

    def test_reads_openscad_section(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "scadm.json"
            data = {"openscad": {"type": "stable", "version": "2021.01"}, "dependencies": []}
            config_file.write_text(json.dumps(data), encoding="utf-8")

            result = get_openscad_config(Path(tmpdir))
            self.assertEqual(result, {"type": "stable", "version": "2021.01"})

    def test_partial_openscad_section(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "scadm.json"
            data = {"openscad": {"type": "nightly"}, "dependencies": []}
            config_file.write_text(json.dumps(data), encoding="utf-8")

            result = get_openscad_config(Path(tmpdir))
            self.assertEqual(result, {"type": "nightly", "version": "latest"})

    def test_defaults_when_no_scadm_json(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            result = get_openscad_config(Path(tmpdir))
            self.assertEqual(result, {"type": "nightly", "version": "latest"})

    def test_defaults_when_invalid_json(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "scadm.json"
            config_file.write_text("not valid json", encoding="utf-8")

            result = get_openscad_config(Path(tmpdir))
            self.assertEqual(result, {"type": "nightly", "version": "latest"})

    def test_nightly_latest_config(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "scadm.json"
            data = {"openscad": {"type": "nightly", "version": "latest"}, "dependencies": []}
            config_file.write_text(json.dumps(data), encoding="utf-8")

            result = get_openscad_config(Path(tmpdir))
            self.assertEqual(result, {"type": "nightly", "version": "latest"})

    def test_invalid_type_raises(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "scadm.json"
            data = {"openscad": {"type": "nigthly", "version": "latest"}, "dependencies": []}
            config_file.write_text(json.dumps(data), encoding="utf-8")

            with self.assertRaises(ValueError):
                get_openscad_config(Path(tmpdir))


class GetOpenscadVersionTests(unittest.TestCase):
    """Tests for get_openscad_version (config-driven)."""

    @patch("scadm.installer.resolve_version")
    def test_pinned_version(self, mock_resolve):
        mock_resolve.return_value = "2026.03.28"
        with tempfile.TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "scadm.json"
            data = {"openscad": {"type": "nightly", "version": "2026.03.28"}, "dependencies": []}
            config_file.write_text(json.dumps(data), encoding="utf-8")

            result = get_openscad_version(os_name="linux", workspace_root=Path(tmpdir))
            self.assertEqual(result, "2026.03.28")

    @patch("scadm.installer.resolve_version")
    def test_latest_version(self, mock_resolve):
        mock_resolve.return_value = "2026.03.28"
        with tempfile.TemporaryDirectory() as tmpdir:
            config_file = Path(tmpdir) / "scadm.json"
            data = {"openscad": {"type": "nightly", "version": "latest"}, "dependencies": []}
            config_file.write_text(json.dumps(data), encoding="utf-8")

            result = get_openscad_version(os_name="linux", workspace_root=Path(tmpdir))
            self.assertEqual(result, "2026.03.28")
            mock_resolve.assert_called_once()


class GetInstalledOpenscadVersionTests(unittest.TestCase):
    """Tests for get_installed_openscad_version."""

    def test_reads_marker_file(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            (install_dir / ".installed-version").write_text("2026.04.16", encoding="utf-8")

            result = get_installed_openscad_version(install_dir, "linux")
            self.assertEqual(result, "2026.04.16")

    def test_empty_marker_returns_none(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            (install_dir / ".installed-version").write_text("", encoding="utf-8")

            result = get_installed_openscad_version(install_dir, "linux")
            self.assertIsNone(result)

    def test_no_marker_no_binary_returns_none(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            result = get_installed_openscad_version(Path(tmpdir), "linux")
            self.assertIsNone(result)

    def test_marker_takes_precedence_over_binary(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            (install_dir / ".installed-version").write_text("2026.04.16", encoding="utf-8")
            (install_dir / "openscad").write_text("fake", encoding="utf-8")

            result = get_installed_openscad_version(install_dir, "linux")
            self.assertEqual(result, "2026.04.16")


class WriteInstalledVersionTests(unittest.TestCase):
    """Tests for _write_installed_version."""

    def test_writes_marker(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            _write_installed_version(install_dir, "2026.04.16")

            marker = install_dir / ".installed-version"
            self.assertTrue(marker.exists())
            self.assertEqual(marker.read_text(encoding="utf-8"), "2026.04.16")


if __name__ == "__main__":
    unittest.main()
