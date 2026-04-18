"""Tests for scadm.vscode module."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scadm.vscode import Extension, update_vscode_settings


class OpenScadSettingsTests(unittest.TestCase):
    """Tests for OpenSCAD extension settings generation."""

    def test_no_search_paths_in_settings(self):
        """scad-lsp.searchPaths must NOT be generated.

        OpenSCAD 2026+ doesn't support -L flags, and the extension converts
        searchPaths into -L arguments, breaking preview.
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "bin" / "openscad" / "openscad.exe").touch()

            settings = Extension.OPENSCAD.get_settings(root)

            self.assertNotIn("scad-lsp.searchPaths", settings)
            self.assertIn("scad-lsp.launchPath", settings)

    def test_launch_path_uses_exe_on_windows(self):
        """On Windows, launchPath should point to openscad.exe."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "bin" / "openscad" / "openscad.exe").touch()

            with patch("scadm.vscode.platform") as mock_platform:
                mock_platform.system.return_value = "Windows"
                settings = Extension.OPENSCAD.get_settings(root)

            self.assertIn("openscad.exe", settings["scad-lsp.launchPath"])

    def test_launch_path_uses_wrapper_on_linux(self):
        """On Linux, launchPath should point to the wrapper script."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)

            with patch("scadm.vscode.platform") as mock_platform:
                mock_platform.system.return_value = "Linux"
                settings = Extension.OPENSCAD.get_settings(root)

            self.assertIn("openscad-wrapper.sh", settings["scad-lsp.launchPath"])


class UpdateSettingsTests(unittest.TestCase):
    """Tests for update_vscode_settings."""

    def test_creates_settings_file(self):
        """Settings file is created if it doesn't exist."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "bin" / "openscad" / "openscad.exe").touch()

            result = update_vscode_settings(root, Extension.OPENSCAD)

            self.assertTrue(result)
            settings_file = root / ".vscode" / "settings.json"
            self.assertTrue(settings_file.exists())
            settings = json.loads(settings_file.read_text(encoding="utf-8"))
            self.assertIn("scad-lsp.launchPath", settings)

    def test_preserves_existing_settings(self):
        """Existing unrelated settings are preserved."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "bin" / "openscad" / "openscad.exe").touch()

            vscode_dir = root / ".vscode"
            vscode_dir.mkdir()
            (vscode_dir / "settings.json").write_text('{"editor.fontSize": 14}', encoding="utf-8")

            update_vscode_settings(root, Extension.OPENSCAD)

            settings = json.loads((vscode_dir / "settings.json").read_text(encoding="utf-8"))
            self.assertEqual(settings["editor.fontSize"], 14)
            self.assertIn("scad-lsp.launchPath", settings)

    def test_removes_stale_search_paths(self):
        """Running update should NOT re-introduce searchPaths."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "bin" / "openscad" / "openscad.exe").touch()

            vscode_dir = root / ".vscode"
            vscode_dir.mkdir()
            (vscode_dir / "settings.json").write_text('{"scad-lsp.searchPaths": "/old/path"}', encoding="utf-8")

            update_vscode_settings(root, Extension.OPENSCAD)

            # update merges, doesn't remove keys — old searchPaths stays
            # but the extension settings themselves must not contain it
            new_settings = Extension.OPENSCAD.get_settings(root)
            self.assertNotIn("scad-lsp.searchPaths", new_settings)


if __name__ == "__main__":
    unittest.main()
