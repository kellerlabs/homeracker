"""Tests for the installer module."""

import io
import json
import os
import subprocess
import tarfile
import tempfile
import unittest
import urllib.error
import zipfile
from pathlib import Path
from unittest.mock import MagicMock, patch

from scadm.installer import (
    _show_version_info,
    download_file,
    find_openscad_exe,
    get_install_paths,
    get_installed_lib_version,
    get_openscad_config,
    get_openscad_version,
    get_installed_openscad_version,
    get_system_platform,
    get_workspace_root,
    install_libraries,
    install_library,
    install_openscad,
    install_openscad_linux,
    install_openscad_windows,
    _write_installed_version,
)


def _fake_download(content: bytes):
    """Return a urlretrieve stand-in that writes content to the destination."""

    def _retrieve(_url, dest):
        Path(dest).write_bytes(content)

    return _retrieve


def _zip_bytes(files: dict) -> bytes:
    """Build an in-memory zip archive from {name: text}."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as zf:
        for name, text in files.items():
            zf.writestr(name, text)
    return buf.getvalue()


def _tar_gz_bytes(files: dict) -> bytes:
    """Build an in-memory .tar.gz archive from {name: text}."""
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode="w:gz") as tar:
        for name, text in files.items():
            data = text.encode("utf-8")
            info = tarfile.TarInfo(name)
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
    return buf.getvalue()


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


class WorkspaceRootTests(unittest.TestCase):
    """Tests for get_workspace_root and get_install_paths."""

    def test_finds_scadm_json_in_parent(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir).resolve()
            (root / "scadm.json").write_text("{}", encoding="utf-8")
            nested = root / "a" / "b"
            nested.mkdir(parents=True)
            self.assertEqual(get_workspace_root(nested), root)

    def test_defaults_to_cwd(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir).resolve()
            (root / "scadm.json").write_text("{}", encoding="utf-8")
            with patch("scadm.installer.Path.cwd", return_value=root):
                self.assertEqual(get_workspace_root(), root)

    def test_raises_when_missing(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            with self.assertRaises(FileNotFoundError):
                get_workspace_root(Path(tmpdir))

    def test_install_paths(self):
        root = Path("/ws")
        install_dir, libraries_dir = get_install_paths(root)
        self.assertEqual(install_dir, root / "bin" / "openscad")
        self.assertEqual(libraries_dir, root / "bin" / "openscad" / "libraries")

    @patch("scadm.installer.get_workspace_root", return_value=Path("/auto"))
    def test_install_paths_auto_detects_root(self, _):
        install_dir, _ = get_install_paths()
        self.assertEqual(install_dir, Path("/auto/bin/openscad"))


class DownloadFileTests(unittest.TestCase):
    """Tests for download_file."""

    @patch("scadm.installer.urllib.request.urlretrieve")
    def test_success(self, mock_retrieve):
        self.assertTrue(download_file("https://x/y", Path("dest")))
        mock_retrieve.assert_called_once_with("https://x/y", Path("dest"))

    @patch("scadm.installer.urllib.request.urlretrieve", side_effect=urllib.error.URLError("offline"))
    def test_failure(self, _):
        self.assertFalse(download_file("https://x/y", Path("dest")))


class GetSystemPlatformTests(unittest.TestCase):
    """Tests for get_system_platform."""

    def test_platform_mapping(self):
        cases = {"Windows": "windows", "Linux": "linux", "Darwin": "linux", "SunOS": "unknown"}
        for system, expected in cases.items():
            with self.subTest(system=system), patch("scadm.installer.platform.system", return_value=system):
                self.assertEqual(get_system_platform(), expected)


class FindOpenscadExeTests(unittest.TestCase):
    """Tests for find_openscad_exe."""

    def _find(self, os_name, files):
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            for name in files:
                (install_dir / name).write_text("", encoding="utf-8")
            with patch("scadm.installer.get_system_platform", return_value=os_name):
                exe = find_openscad_exe(install_dir)
            return exe.name if exe else None

    def test_windows_prefers_com(self):
        self.assertEqual(self._find("windows", ["openscad.com", "openscad.exe"]), "openscad.com")

    def test_windows_falls_back_to_exe(self):
        self.assertEqual(self._find("windows", ["openscad.exe"]), "openscad.exe")

    def test_linux_prefers_symlink(self):
        self.assertEqual(self._find("linux", ["openscad", "OpenSCAD.AppImage"]), "openscad")

    def test_linux_appimage(self):
        self.assertEqual(self._find("linux", ["OpenSCAD.AppImage"]), "OpenSCAD.AppImage")

    def test_linux_versioned_appimage(self):
        files = ["OpenSCAD-2026.02.AppImage", "OpenSCAD-2026.01.AppImage"]
        self.assertEqual(self._find("linux", files), "OpenSCAD-2026.01.AppImage")

    def test_not_found(self):
        self.assertIsNone(self._find("linux", []))
        self.assertIsNone(self._find("windows", []))


class GetOpenscadConfigAutoRootTests(unittest.TestCase):
    """Tests for get_openscad_config without an explicit root."""

    @patch("scadm.installer.get_workspace_root", side_effect=FileNotFoundError)
    def test_defaults_without_workspace(self, _):
        self.assertEqual(get_openscad_config(), {"type": "nightly", "version": "latest"})

    @patch("scadm.installer.resolve_version", return_value="2026.01.01")
    @patch("scadm.installer.get_workspace_root", side_effect=FileNotFoundError)
    def test_version_without_workspace_has_no_cache_dir(self, _, mock_resolve):
        self.assertEqual(get_openscad_version(os_name="windows"), "2026.01.01")
        mock_resolve.assert_called_once_with("nightly", "latest", "windows", install_dir=None, force=False)


class GetInstalledVersionFromBinaryTests(unittest.TestCase):
    """Tests for the legacy binary fallback of get_installed_openscad_version."""

    def _run(self, os_name, exe_name, output=None, side_effect=None):
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            (install_dir / exe_name).write_text("", encoding="utf-8")
            result = MagicMock(stdout="", stderr=output or "")
            with patch("scadm.installer.subprocess.run", return_value=result, side_effect=side_effect) as mock_run:
                version = get_installed_openscad_version(install_dir, os_name)
            return version, mock_run

    def test_parses_linux_binary(self):
        version, mock_run = self._run("linux", "openscad", "OpenSCAD version 2026.04.16.ai123\n")
        self.assertEqual(version, "2026.04.16.ai123")
        self.assertEqual(mock_run.call_args.args[0][1], "--version")

    def test_parses_linux_appimage(self):
        version, _ = self._run("linux", "OpenSCAD.AppImage", "OpenSCAD version 2021.01.01")
        self.assertEqual(version, "2021.01.01")

    def test_parses_windows_exe(self):
        version, _ = self._run("windows", "openscad.exe", "OpenSCAD version 2026.04.16")
        self.assertEqual(version, "2026.04.16")

    def test_unparseable_output(self):
        version, _ = self._run("linux", "openscad", "garbage")
        self.assertIsNone(version)

    def test_exec_error(self):
        version, _ = self._run("linux", "openscad", side_effect=OSError("exec format error"))
        self.assertIsNone(version)


class InstallOpenscadWindowsTests(unittest.TestCase):
    """Tests for install_openscad_windows."""

    def test_extracts_nested_zip(self):
        archive = _zip_bytes({"openscad-2026/openscad.exe": "exe", "openscad-2026/libraries/x.scad": "x"})
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            with patch("scadm.installer.urllib.request.urlretrieve", side_effect=_fake_download(archive)) as dl:
                self.assertTrue(install_openscad_windows(install_dir, "2026.01.01", nightly=True))
            self.assertIn("/snapshots/OpenSCAD-2026.01.01-x86-64.zip", dl.call_args.args[0])
            self.assertTrue((install_dir / "openscad.exe").exists())
            self.assertTrue((install_dir / "libraries" / "x.scad").exists())
            self.assertFalse((install_dir / "temp_extract").exists())
            self.assertFalse((install_dir / "openscad-2026.01.01.zip").exists())

    def test_extracts_flat_zip_stable_url(self):
        archive = _zip_bytes({"openscad.exe": "exe", "README.txt": "r"})
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            with patch("scadm.installer.urllib.request.urlretrieve", side_effect=_fake_download(archive)) as dl:
                self.assertTrue(install_openscad_windows(install_dir, "2021.01", nightly=False))
            self.assertEqual(dl.call_args.args[0], "https://files.openscad.org/OpenSCAD-2021.01-x86-64.zip")
            self.assertTrue((install_dir / "openscad.exe").exists())

    @patch("scadm.installer.download_file", return_value=False)
    def test_download_failure(self, _):
        with tempfile.TemporaryDirectory() as tmpdir:
            self.assertFalse(install_openscad_windows(Path(tmpdir), "2021.01", nightly=False))

    def test_bad_zip(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            with patch("scadm.installer.urllib.request.urlretrieve", side_effect=_fake_download(b"not a zip")):
                self.assertFalse(install_openscad_windows(Path(tmpdir), "2021.01", nightly=False))


class InstallOpenscadLinuxTests(unittest.TestCase):
    """Tests for install_openscad_linux."""

    @unittest.skipIf(os.name == "nt", "POSIX exec bit and symlinks")
    def test_installs_executable_appimage_and_symlink(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            (install_dir / "openscad").write_text("stale", encoding="utf-8")
            with patch("scadm.installer.urllib.request.urlretrieve", side_effect=_fake_download(b"elf")) as dl:
                self.assertTrue(install_openscad_linux(install_dir, "2026.01.01", nightly=True))
            self.assertEqual(
                dl.call_args.args[0], "https://files.openscad.org/snapshots/OpenSCAD-2026.01.01-x86_64.AppImage"
            )
            appimage = install_dir / "OpenSCAD.AppImage"
            self.assertTrue(os.access(appimage, os.X_OK))
            self.assertTrue((install_dir / "openscad").is_symlink())
            self.assertEqual(os.readlink(install_dir / "openscad"), "OpenSCAD.AppImage")

    def test_stable_url_and_symlink_failure_is_not_fatal(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            install_dir = Path(tmpdir)
            with (
                patch("scadm.installer.urllib.request.urlretrieve", side_effect=_fake_download(b"elf")) as dl,
                patch("scadm.installer.os.symlink", side_effect=OSError("no symlinks")),
            ):
                self.assertTrue(install_openscad_linux(install_dir, "2021.01", nightly=False))
            self.assertEqual(dl.call_args.args[0], "https://files.openscad.org/OpenSCAD-2021.01-x86_64.AppImage")

    @patch("scadm.installer.download_file", return_value=False)
    def test_download_failure(self, _):
        with tempfile.TemporaryDirectory() as tmpdir:
            self.assertFalse(install_openscad_linux(Path(tmpdir), "2021.01", nightly=False))


class InstallOpenscadTests(unittest.TestCase):
    """Tests for the install_openscad orchestration."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()  # pylint: disable=consider-using-with
        self.root = Path(self._tmp.name)
        config = {"openscad": {"type": "nightly", "version": "latest"}, "dependencies": []}
        (self.root / "scadm.json").write_text(json.dumps(config), encoding="utf-8")
        self.install_dir = self.root / "bin" / "openscad"
        patches = {
            "platform": patch("scadm.installer.get_system_platform", return_value="linux"),
            "resolve": patch("scadm.installer.resolve_version", return_value="2026.02.02"),
            "linux": patch("scadm.installer.install_openscad_linux", return_value=True),
            "windows": patch("scadm.installer.install_openscad_windows", return_value=True),
        }
        self.mocks = {name: p.start() for name, p in patches.items()}
        self.addCleanup(patch.stopall)
        self.addCleanup(self._tmp.cleanup)

    def _set_installed(self, version):
        self.install_dir.mkdir(parents=True, exist_ok=True)
        _write_installed_version(self.install_dir, version)

    def test_unsupported_platform(self):
        self.mocks["platform"].return_value = "unknown"
        self.assertFalse(install_openscad(workspace_root=self.root))

    def test_fresh_install_writes_marker(self):
        self.assertTrue(install_openscad(workspace_root=self.root))
        self.mocks["linux"].assert_called_once_with(self.install_dir, "2026.02.02", True)
        self.assertEqual(get_installed_openscad_version(self.install_dir, "linux"), "2026.02.02")

    def test_windows_install(self):
        self.mocks["platform"].return_value = "windows"
        self.assertTrue(install_openscad(workspace_root=self.root))
        self.mocks["windows"].assert_called_once()
        self.mocks["linux"].assert_not_called()

    def test_failed_install_writes_no_marker(self):
        self.mocks["linux"].return_value = False
        self.assertFalse(install_openscad(workspace_root=self.root))
        self.assertFalse((self.install_dir / ".installed-version").exists())

    def test_up_to_date_skips_install(self):
        self._set_installed("2026.02.02")
        self.assertTrue(install_openscad(workspace_root=self.root))
        self.mocks["linux"].assert_not_called()

    def test_force_reinstalls_and_cleans(self):
        self._set_installed("2026.02.02")
        (self.install_dir / "stale.txt").write_text("x", encoding="utf-8")
        self.assertTrue(install_openscad(force=True, workspace_root=self.root))
        self.mocks["linux"].assert_called_once()
        self.assertFalse((self.install_dir / "stale.txt").exists())

    def test_check_only_up_to_date(self):
        self._set_installed("2026.02.02")
        self.assertTrue(install_openscad(check_only=True, workspace_root=self.root))
        self.mocks["linux"].assert_not_called()

    def test_check_only_outdated(self):
        self._set_installed("2026.01.01")
        self.assertFalse(install_openscad(check_only=True, workspace_root=self.root))
        self.mocks["linux"].assert_not_called()

    def test_check_only_not_installed(self):
        self.assertFalse(install_openscad(check_only=True, workspace_root=self.root))

    def test_info_does_not_install(self):
        self.assertTrue(install_openscad(info=True, workspace_root=self.root))
        self.mocks["linux"].assert_not_called()

    def test_auto_detects_workspace(self):
        with patch("scadm.installer.get_workspace_root", return_value=self.root):
            self.assertTrue(install_openscad())
        self.mocks["linux"].assert_called_once()


class ShowVersionInfoTests(unittest.TestCase):
    """Tests for _show_version_info."""

    def _logged(self, config, resolve_side_effect=None):
        with (
            tempfile.TemporaryDirectory() as tmpdir,
            patch("scadm.installer.resolve_version", return_value="2026.03.03", side_effect=resolve_side_effect),
            self.assertLogs("scadm.installer", level="INFO") as logs,
        ):
            _show_version_info(config, Path(tmpdir), "linux")
        return "\n".join(logs.output)

    def test_latest_shows_resolved(self):
        output = self._logged({"type": "nightly", "version": "latest"})
        self.assertIn("Resolved version:   2026.03.03", output)
        self.assertIn("Installed version:  not installed", output)

    def test_resolve_error_is_reported(self):
        output = self._logged({"type": "nightly", "version": "latest"}, RuntimeError("offline"))
        self.assertIn("unavailable: offline", output)

    def test_pinned_skips_resolution(self):
        output = self._logged({"type": "stable", "version": "2021.01"})
        self.assertNotIn("Resolved version", output)


class InstallLibraryTests(unittest.TestCase):
    """Tests for get_installed_lib_version and install_library."""

    DEP = {"name": "BOSL2", "repository": "BelfrySCAD/BOSL2", "version": "v2.0.1"}

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()  # pylint: disable=consider-using-with
        self.addCleanup(self._tmp.cleanup)
        self.libs = Path(self._tmp.name) / "libraries"
        self.libs.mkdir()
        cwd = patch("scadm.installer.Path.cwd", return_value=Path(self._tmp.name))
        cwd.start()
        self.addCleanup(cwd.stop)

    def test_version_none_when_missing(self):
        self.assertIsNone(get_installed_lib_version(self.libs / "BOSL2"))

    def test_installs_and_strips_top_dir(self):
        archive = _tar_gz_bytes({"BOSL2-2.0.1/std.scad": "std", "BOSL2-2.0.1/sub/a.scad": "a", "top.txt": "t"})
        with patch("scadm.installer.urllib.request.urlretrieve", side_effect=_fake_download(archive)) as dl:
            self.assertTrue(install_library(self.DEP, self.libs))
        self.assertEqual(dl.call_args.args[0], "https://github.com/BelfrySCAD/BOSL2/archive/v2.0.1.tar.gz")
        lib = self.libs / "BOSL2"
        self.assertEqual((lib / "std.scad").read_text(encoding="utf-8"), "std")
        self.assertTrue((lib / "sub" / "a.scad").exists())
        self.assertEqual(get_installed_lib_version(lib), "v2.0.1")
        self.assertFalse((Path(self._tmp.name) / "BOSL2-v2.0.1.tar.gz").exists())

    def test_up_to_date_skips_download(self):
        (self.libs / "BOSL2").mkdir()
        (self.libs / "BOSL2" / ".version").write_text("v2.0.1\n", encoding="utf-8")
        with patch("scadm.installer.urllib.request.urlretrieve") as dl:
            self.assertTrue(install_library(self.DEP, self.libs))
        dl.assert_not_called()

    def test_update_replaces_old_files(self):
        old = self.libs / "BOSL2"
        old.mkdir()
        (old / ".version").write_text("v1.0.0", encoding="utf-8")
        (old / "removed.scad").write_text("", encoding="utf-8")
        archive = _tar_gz_bytes({"BOSL2/std.scad": "std"})
        with patch("scadm.installer.urllib.request.urlretrieve", side_effect=_fake_download(archive)):
            self.assertTrue(install_library(self.DEP, self.libs))
        self.assertFalse((old / "removed.scad").exists())
        self.assertEqual(get_installed_lib_version(old), "v2.0.1")

    def test_unknown_source(self):
        self.assertFalse(install_library({**self.DEP, "source": "gitlab"}, self.libs))

    def test_download_error_cleans_up(self):
        def _partial(_url, dest):
            Path(dest).write_bytes(b"partial")
            raise urllib.error.URLError("reset")

        with patch("scadm.installer.urllib.request.urlretrieve", side_effect=_partial):
            self.assertFalse(install_library(self.DEP, self.libs))
        self.assertFalse((Path(self._tmp.name) / "BOSL2-v2.0.1.tar.gz").exists())

    def test_bad_archive(self):
        with patch("scadm.installer.urllib.request.urlretrieve", side_effect=_fake_download(b"not a tarball")):
            self.assertFalse(install_library(self.DEP, self.libs))


class InstallLibrariesTests(unittest.TestCase):
    """Tests for install_libraries."""

    def _workspace(self, tmpdir, content):
        root = Path(tmpdir)
        text = content if isinstance(content, str) else json.dumps(content)
        (root / "scadm.json").write_text(text, encoding="utf-8")
        return root

    def test_missing_file(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            self.assertFalse(install_libraries(workspace_root=Path(tmpdir)))

    def test_invalid_json(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            self.assertFalse(install_libraries(workspace_root=self._workspace(tmpdir, "{nope")))

    @patch("scadm.installer.install_library")
    def test_missing_required_fields(self, mock_install):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = self._workspace(tmpdir, {"dependencies": [{"name": "x", "version": "1"}]})
            self.assertFalse(install_libraries(workspace_root=root))
        mock_install.assert_not_called()

    @patch("scadm.installer.install_library", side_effect=[True, False])
    def test_installs_each_and_reports_failure(self, mock_install):
        deps = [
            {"name": "a", "repository": "o/a", "version": "1"},
            {"name": "b", "repository": "o/b", "version": "2"},
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            root = self._workspace(tmpdir, {"dependencies": deps})
            self.assertFalse(install_libraries(force=True, workspace_root=root))
            self.assertTrue((root / "bin" / "openscad" / "libraries").is_dir())
        self.assertEqual(mock_install.call_count, 2)
        self.assertTrue(mock_install.call_args.kwargs["force"])

    @patch("scadm.installer.install_library")
    def test_check_only(self, mock_install):
        deps = [
            {"name": "a", "repository": "o/a", "version": "1"},
            {"name": "b", "repository": "o/b", "version": "2"},
        ]
        with tempfile.TemporaryDirectory() as tmpdir:
            root = self._workspace(tmpdir, {"dependencies": deps})
            lib_a = root / "bin" / "openscad" / "libraries" / "a"
            lib_a.mkdir(parents=True)
            (lib_a / ".version").write_text("1", encoding="utf-8")
            self.assertFalse(install_libraries(check_only=True, workspace_root=root))
            (root / "bin" / "openscad" / "libraries" / "b").mkdir()
            (root / "bin" / "openscad" / "libraries" / "b" / ".version").write_text("2", encoding="utf-8")
            self.assertTrue(install_libraries(check_only=True, workspace_root=root))
        mock_install.assert_not_called()

    def test_auto_detects_workspace(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            root = self._workspace(tmpdir, {"dependencies": []})
            with patch("scadm.installer.get_workspace_root", return_value=root):
                self.assertTrue(install_libraries())


if __name__ == "__main__":
    unittest.main()
