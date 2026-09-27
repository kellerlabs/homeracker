"""Tests for scadm.vscode module."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import subprocess

from scadm.vscode import (
    Extension,
    install_extension,
    setup_openscad_extension,
    setup_python_extension,
    update_vscode_settings,
)


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

    def test_removes_stale_search_paths_from_settings_file(self):
        """update_vscode_settings removes existing scad-lsp.searchPaths entries."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "bin" / "openscad" / "openscad.exe").touch()

            vscode_dir = root / ".vscode"
            vscode_dir.mkdir()
            (vscode_dir / "settings.json").write_text(
                '{"scad-lsp.searchPaths": "/old/path", "editor.fontSize": 14}', encoding="utf-8"
            )

            update_vscode_settings(root, Extension.OPENSCAD)

            settings = json.loads((vscode_dir / "settings.json").read_text(encoding="utf-8"))
            self.assertNotIn("scad-lsp.searchPaths", settings)
            self.assertEqual(settings["editor.fontSize"], 14)


class ExtensionTests(unittest.TestCase):
    """Tests for Extension metadata and settings."""

    def test_names_and_ids(self):
        self.assertEqual(Extension.OPENSCAD.get_name(), "Openscad")
        self.assertEqual(Extension.PYTHON.get_id(), "ms-python.python")

    def test_python_settings(self):
        settings = Extension.PYTHON.get_settings(Path("/ws"))
        self.assertEqual(settings, {"python.defaultInterpreterPath": "${workspaceFolder}/.venv"})
        self.assertEqual(Extension.PYTHON.get_deprecated_keys(), [])

    @patch("scadm.vscode.platform.system", return_value="Linux")
    def test_openscad_settings_linux_uses_wrapper(self, _):
        self.assertEqual(
            Extension.OPENSCAD.get_settings(Path("/ws")),
            {
                "files.associations": {"*.scad": "scad"},
                "files.eol": "\n",
                "scad-lsp.launchPath": str(Path("/ws/cmd/linux/openscad-wrapper.sh")),
            },
        )

    @patch("scadm.vscode.platform.system", return_value="Windows")
    def test_openscad_settings_windows_uses_exe(self, _):
        settings = Extension.OPENSCAD.get_settings(Path("/ws"))
        expected = str(Path("/ws") / "bin" / "openscad" / "openscad.exe").replace("/", "\\")
        self.assertEqual(settings["scad-lsp.launchPath"], expected)
        self.assertNotIn("/", settings["scad-lsp.launchPath"])


class InstallExtensionTests(unittest.TestCase):
    """Tests for install_extension."""

    @patch("scadm.vscode.subprocess.run")
    def test_success(self, mock_run):
        for system, shell in (("Linux", False), ("Windows", True)):
            with self.subTest(system=system), patch("scadm.vscode.platform.system", return_value=system):
                self.assertTrue(install_extension(Extension.PYTHON))
                mock_run.assert_called_with(
                    ["code", "--install-extension", "ms-python.python", "--force"],
                    check=True,
                    capture_output=True,
                    text=True,
                    shell=shell,
                )

    @patch("scadm.vscode.subprocess.run", side_effect=FileNotFoundError)
    def test_code_missing(self, _):
        self.assertFalse(install_extension(Extension.PYTHON))

    @patch("scadm.vscode.subprocess.run", side_effect=subprocess.CalledProcessError(1, "code", stderr="boom"))
    def test_install_error(self, _):
        self.assertFalse(install_extension(Extension.PYTHON))


class UpdateSettingsEdgeCaseTests(unittest.TestCase):
    """Tests for update_vscode_settings merge and error handling."""

    def test_merges_nested_and_drops_deprecated(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".vscode").mkdir()
            existing = {"files.associations": {"*.md": "markdown"}, "scad-lsp.searchPaths": "x", "keep": 1}
            (root / ".vscode" / "settings.json").write_text(json.dumps(existing), encoding="utf-8")

            self.assertTrue(update_vscode_settings(root, Extension.OPENSCAD))

            settings = json.loads((root / ".vscode" / "settings.json").read_text(encoding="utf-8"))
            self.assertEqual(settings["files.associations"], {"*.md": "markdown", "*.scad": "scad"})
            self.assertNotIn("scad-lsp.searchPaths", settings)
            self.assertEqual(settings["keep"], 1)

    def test_invalid_json_is_overwritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".vscode").mkdir()
            (root / ".vscode" / "settings.json").write_text("{broken", encoding="utf-8")
            self.assertTrue(update_vscode_settings(root, Extension.PYTHON))
            settings = json.loads((root / ".vscode" / "settings.json").read_text(encoding="utf-8"))
            self.assertIn("python.defaultInterpreterPath", settings)

    def test_writes_sorted_two_space_json_into_new_workspace(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "new" / "ws"
            with patch("scadm.vscode.platform.system", return_value="Linux"):
                self.assertTrue(update_vscode_settings(root, Extension.OPENSCAD))
            text = (root / ".vscode" / "settings.json").read_text(encoding="utf-8")
            expected = {
                "files.associations": {"*.scad": "scad"},
                "files.eol": "\n",
                "scad-lsp.launchPath": str(root / "cmd" / "linux" / "openscad-wrapper.sh"),
            }
            self.assertEqual(text, json.dumps(expected, indent=2, sort_keys=True))

    def test_output_keys_are_sorted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".vscode").mkdir()
            (root / ".vscode" / "settings.json").write_text('{"zzz": 1, "aaa": 2}', encoding="utf-8")
            self.assertTrue(update_vscode_settings(root, Extension.PYTHON))
            text = (root / ".vscode" / "settings.json").read_text(encoding="utf-8")
            self.assertEqual(
                list(json.loads(text)), ["aaa", "python.defaultInterpreterPath", "zzz"], "keys must be written sorted"
            )

    def test_non_dict_value_replaces_existing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".vscode").mkdir()
            (root / ".vscode" / "settings.json").write_text('{"files.associations": "x"}', encoding="utf-8")
            self.assertTrue(update_vscode_settings(root, Extension.OPENSCAD))
            settings = json.loads((root / ".vscode" / "settings.json").read_text(encoding="utf-8"))
            self.assertEqual(settings["files.associations"], {"*.scad": "scad"})

    def test_write_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            with patch("builtins.open", side_effect=OSError("read-only")):
                self.assertFalse(update_vscode_settings(Path(tmp), Extension.PYTHON))


@patch("scadm.vscode.shutil.which", return_value="/usr/bin/code")
class SetupExtensionTests(unittest.TestCase):
    """Tests for setup_openscad_extension and setup_python_extension."""

    @patch("scadm.vscode.update_vscode_settings", return_value=True)
    @patch("scadm.vscode.install_extension", return_value=True)
    @patch("scadm.vscode.get_workspace_root", return_value=Path("/ws"))
    def test_success(self, _, mock_install, mock_update, mock_which):
        for setup, extension in (
            (setup_openscad_extension, Extension.OPENSCAD),
            (setup_python_extension, Extension.PYTHON),
        ):
            with self.subTest(extension=extension):
                self.assertTrue(setup())
                mock_install.assert_called_with(extension)
                mock_update.assert_called_with(Path("/ws"), extension)
        mock_which.assert_called_with("code")

    def test_code_not_on_path(self, mock_which):
        mock_which.return_value = None
        self.assertFalse(setup_python_extension())

    @patch("scadm.vscode.get_workspace_root", side_effect=FileNotFoundError("no scadm.json"))
    def test_no_workspace(self, *_):
        self.assertFalse(setup_python_extension())

    @patch("scadm.vscode.update_vscode_settings")
    @patch("scadm.vscode.install_extension", return_value=False)
    @patch("scadm.vscode.get_workspace_root", return_value=Path("/ws"))
    def test_install_failure_skips_settings(self, _, __, mock_update, ___):
        self.assertFalse(setup_python_extension())
        mock_update.assert_not_called()

    @patch("scadm.vscode.update_vscode_settings", return_value=False)
    @patch("scadm.vscode.install_extension", return_value=True)
    @patch("scadm.vscode.get_workspace_root", return_value=Path("/ws"))
    def test_settings_failure(self, *_):
        self.assertFalse(setup_python_extension())


if __name__ == "__main__":
    unittest.main()
