"""Tests for scadm.export_png module."""

import json
import platform
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from scadm.export_png import DEFAULT_CAMERA, DEFAULT_COLORSCHEME, DEFAULT_IMGSIZE, export_png
from scadm.installer import find_openscad_exe


class ExportPngTests(unittest.TestCase):
    def _make_workspace(self, tmp):
        """Create a minimal workspace with OpenSCAD binary stub and libraries."""
        root = Path(tmp)
        (root / "scadm.json").write_text(json.dumps({"dependencies": []}), encoding="utf-8")

        install_dir = root / "bin" / "openscad"
        install_dir.mkdir(parents=True)
        (install_dir / "libraries").mkdir()

        if platform.system() == "Windows":
            exe = install_dir / "openscad.com"
        else:
            exe = install_dir / "openscad"
        exe.write_text("stub", encoding="utf-8")

        return root, exe

    def _make_scad(self, root, rel_path="test.scad"):
        """Create a stub .scad file."""
        scad = root / rel_path
        scad.parent.mkdir(parents=True, exist_ok=True)
        scad.write_text("cube(1);", encoding="utf-8")
        return scad

    @patch("scadm.export_png.subprocess.run")
    def test_default_output_in_renders_subfolder(self, mock_run):
        """Default output is renders/<input_basename>.png."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root, "models/test.scad")
            expected_output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            expected_output.parent.mkdir(parents=True, exist_ok=True)
            expected_output.write_text("fake png", encoding="utf-8")

            result = export_png(scad, workspace_root=root)

            self.assertTrue(result)
            cmd = mock_run.call_args[0][0]
            self.assertIn(str(expected_output), cmd)

    @patch("scadm.export_png.subprocess.run")
    def test_custom_output_path(self, mock_run):
        """--output overrides default output path."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            custom_output = root / "custom" / "out.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            custom_output.parent.mkdir(parents=True, exist_ok=True)
            custom_output.write_text("fake png", encoding="utf-8")

            result = export_png(scad, output=custom_output, workspace_root=root)

            self.assertTrue(result)
            cmd = mock_run.call_args[0][0]
            self.assertIn(str(custom_output.resolve()), cmd)

    @patch("scadm.export_png.subprocess.run")
    def test_default_camera_imgsize_colorscheme(self, mock_run):
        """Default camera, imgsize, and colorscheme are passed to OpenSCAD."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, workspace_root=root)

            cmd = mock_run.call_args[0][0]
            self.assertIn(f"--camera={DEFAULT_CAMERA}", cmd)
            self.assertIn(f"--imgsize={DEFAULT_IMGSIZE}", cmd)
            self.assertIn(f"--colorscheme={DEFAULT_COLORSCHEME}", cmd)

    @patch("scadm.export_png.subprocess.run")
    def test_custom_camera_imgsize_colorscheme(self, mock_run):
        """Custom camera, imgsize, and colorscheme are forwarded."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, camera="1,2,3,4,5,6,7", imgsize="1200,900", colorscheme="Cornfield", workspace_root=root)

            cmd = mock_run.call_args[0][0]
            self.assertIn("--camera=1,2,3,4,5,6,7", cmd)
            self.assertIn("--imgsize=1200,900", cmd)
            self.assertIn("--colorscheme=Cornfield", cmd)

    @patch("scadm.export_png.subprocess.run")
    def test_projection_flag(self, mock_run):
        """--projection is passed when provided."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, projection="o", workspace_root=root)

            cmd = mock_run.call_args[0][0]
            self.assertIn("--projection=o", cmd)

    @patch("scadm.export_png.subprocess.run")
    def test_projection_omitted_by_default(self, mock_run):
        """--projection is not in command when not provided."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, workspace_root=root)

            cmd_str = " ".join(mock_run.call_args[0][0])
            self.assertNotIn("--projection", cmd_str)

    @patch("scadm.export_png.subprocess.run")
    def test_defines_passed(self, mock_run):
        """Multiple -D overrides are forwarded."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, defines=["variant=2", "split=true"], workspace_root=root)

            cmd = mock_run.call_args[0][0]
            d_indices = [i for i, v in enumerate(cmd) if v == "-D"]
            self.assertEqual(len(d_indices), 2)
            self.assertEqual(cmd[d_indices[0] + 1], "variant=2")
            self.assertEqual(cmd[d_indices[1] + 1], "split=true")

    @patch("scadm.export_png.subprocess.run")
    def test_param_file_and_set(self, mock_run):
        """-p and -P flags are forwarded."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"
            preset = root / "presets.json"
            preset.write_text("{}", encoding="utf-8")

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, param_file=preset, param_set="both_sides", workspace_root=root)

            cmd = mock_run.call_args[0][0]
            p_idx = cmd.index("-p")
            self.assertEqual(cmd[p_idx + 1], str(preset.resolve()))
            big_p_idx = cmd.index("-P")
            self.assertEqual(cmd[big_p_idx + 1], "both_sides")

    @patch("scadm.export_png.subprocess.run")
    def test_render_and_viewall_flags(self, mock_run):
        """--render, --autocenter, --viewall are always passed."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, workspace_root=root)

            cmd = mock_run.call_args[0][0]
            self.assertIn("--render", cmd)
            self.assertIn("--autocenter", cmd)
            self.assertIn("--viewall", cmd)

    @patch("scadm.export_png.subprocess.run")
    def test_openscadpath_env_set(self, mock_run):
        """OPENSCADPATH environment variable is set to libraries dir."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, workspace_root=root)

            env = mock_run.call_args[1]["env"]
            expected_lib = str(root / "bin" / "openscad" / "libraries")
            self.assertEqual(env["OPENSCADPATH"], expected_lib)

    def test_missing_input_file_returns_false(self):
        """Returns False when input file doesn't exist."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            missing = root / "nonexistent.scad"

            result = export_png(missing, workspace_root=root)
            self.assertFalse(result)

    def test_no_openscad_returns_false(self):
        """Returns False when OpenSCAD is not installed."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "scadm.json").write_text(json.dumps({"dependencies": []}), encoding="utf-8")
            (root / "bin" / "openscad").mkdir(parents=True)
            (root / "bin" / "openscad" / "libraries").mkdir()
            scad = self._make_scad(root)

            result = export_png(scad, workspace_root=root)
            self.assertFalse(result)

    @patch("scadm.export_png.subprocess.run")
    def test_failed_render_returns_false(self, mock_run):
        """Returns False when OpenSCAD exits non-zero."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)

            mock_run.return_value = MagicMock(returncode=1, stdout="", stderr="error")

            result = export_png(scad, workspace_root=root)
            self.assertFalse(result)

    @patch("scadm.export_png.subprocess.run")
    def test_zero_byte_output_returns_false(self, mock_run):
        """Returns False when OpenSCAD produces a zero-byte file."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(b"")

            result = export_png(scad, workspace_root=root)
            self.assertFalse(result)

    @patch("scadm.export_png.subprocess.run")
    def test_input_file_is_last_arg(self, mock_run):
        """Input .scad file is the last argument to OpenSCAD."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            output = scad.parent / "renders" / "test.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text("fake png", encoding="utf-8")

            export_png(scad, workspace_root=root)

            cmd = mock_run.call_args[0][0]
            self.assertEqual(cmd[-1], str(scad.resolve()))

    @patch("scadm.export_png.subprocess.run")
    def test_output_dir_created(self, mock_run):
        """Parent directory of output file is created if it doesn't exist."""
        with tempfile.TemporaryDirectory() as tmp:
            root, _ = self._make_workspace(tmp)
            scad = self._make_scad(root)
            custom_output = root / "deep" / "nested" / "out.png"

            mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")

            # The function should create the directory
            export_png(scad, output=custom_output, workspace_root=root)

            self.assertTrue(custom_output.parent.exists())


class FindOpenscadExeTests(unittest.TestCase):
    """Tests for the shared find_openscad_exe function."""

    def test_finds_openscad_com_on_windows(self):
        with tempfile.TemporaryDirectory() as tmp:
            install_dir = Path(tmp)
            (install_dir / "openscad.com").write_text("stub", encoding="utf-8")

            with patch("scadm.installer.get_system_platform", return_value="windows"):
                result = find_openscad_exe(install_dir)
                self.assertEqual(result, install_dir / "openscad.com")

    def test_finds_openscad_exe_on_windows(self):
        with tempfile.TemporaryDirectory() as tmp:
            install_dir = Path(tmp)
            (install_dir / "openscad.exe").write_text("stub", encoding="utf-8")

            with patch("scadm.installer.get_system_platform", return_value="windows"):
                result = find_openscad_exe(install_dir)
                self.assertEqual(result, install_dir / "openscad.exe")

    def test_finds_openscad_on_linux(self):
        with tempfile.TemporaryDirectory() as tmp:
            install_dir = Path(tmp)
            (install_dir / "openscad").write_text("stub", encoding="utf-8")

            with patch("scadm.installer.get_system_platform", return_value="linux"):
                result = find_openscad_exe(install_dir)
                self.assertEqual(result, install_dir / "openscad")

    def test_finds_appimage_on_linux(self):
        with tempfile.TemporaryDirectory() as tmp:
            install_dir = Path(tmp)
            (install_dir / "OpenSCAD.AppImage").write_text("stub", encoding="utf-8")

            with patch("scadm.installer.get_system_platform", return_value="linux"):
                result = find_openscad_exe(install_dir)
                self.assertEqual(result, install_dir / "OpenSCAD.AppImage")

    def test_finds_versioned_appimage_on_linux(self):
        with tempfile.TemporaryDirectory() as tmp:
            install_dir = Path(tmp)
            (install_dir / "OpenSCAD-2025.03.17.ai22092-x86_64.AppImage").write_text("stub", encoding="utf-8")

            with patch("scadm.installer.get_system_platform", return_value="linux"):
                result = find_openscad_exe(install_dir)
                self.assertIsNotNone(result)
                self.assertIn("AppImage", str(result))

    def test_returns_none_when_not_found(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = find_openscad_exe(Path(tmp))
            self.assertIsNone(result)
