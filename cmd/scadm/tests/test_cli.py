"""Tests for the scadm CLI dispatch and argument validation."""

import unittest
from pathlib import Path
from unittest.mock import patch

from scadm import cli


def run_cli(*argv):
    """Run scadm main() with argv and return its exit code."""
    with patch("sys.argv", ["scadm", *argv]):
        with unittest.TestCase().assertRaises(SystemExit) as ctx:
            cli.main()
    return ctx.exception.code


class MainTests(unittest.TestCase):
    """Tests for top-level parsing."""

    @patch("argparse.ArgumentParser.print_help")
    def test_no_command_prints_help(self, mock_help):
        self.assertEqual(run_cli(), 0)
        mock_help.assert_called_once()

    def test_version_flag(self):
        with patch("sys.stdout"):
            self.assertEqual(run_cli("--version"), 0)


class VscodeTests(unittest.TestCase):
    """Tests for the vscode subcommand."""

    @patch("scadm.cli.setup_openscad_extension", return_value=True)
    def test_openscad_success(self, mock_setup):
        self.assertEqual(run_cli("vscode", "--openscad"), 0)
        mock_setup.assert_called_once()

    @patch("scadm.cli.setup_openscad_extension", return_value=False)
    def test_openscad_failure(self, _):
        self.assertEqual(run_cli("vscode", "--openscad"), 1)

    @patch("scadm.cli.setup_python_extension", return_value=True)
    def test_python_success(self, mock_setup):
        self.assertEqual(run_cli("vscode", "--python"), 0)
        mock_setup.assert_called_once()

    @patch("scadm.cli.setup_python_extension", return_value=False)
    def test_python_failure(self, _):
        self.assertEqual(run_cli("vscode", "--python"), 1)

    @patch("argparse.ArgumentParser.print_help")
    def test_no_flag_prints_help(self, mock_help):
        self.assertEqual(run_cli("vscode"), 0)
        mock_help.assert_called_once()


@patch("scadm.cli.install_libraries", return_value=True)
@patch("scadm.cli.install_openscad", return_value=True)
class InstallTests(unittest.TestCase):
    """Tests for the install subcommand."""

    def test_installs_both(self, mock_openscad, mock_libs):
        self.assertEqual(run_cli("install"), 0)
        mock_openscad.assert_called_once_with(force=False, check_only=False, info=False)
        mock_libs.assert_called_once_with(force=False, check_only=False)

    def test_passes_force_and_check(self, mock_openscad, mock_libs):
        self.assertEqual(run_cli("install", "--force", "--check"), 0)
        mock_openscad.assert_called_once_with(force=True, check_only=True, info=False)
        mock_libs.assert_called_once_with(force=True, check_only=True)

    def test_openscad_only_skips_libs(self, mock_openscad, mock_libs):
        self.assertEqual(run_cli("install", "--openscad-only"), 0)
        mock_openscad.assert_called_once()
        mock_libs.assert_not_called()

    def test_libs_only_skips_openscad(self, mock_openscad, mock_libs):
        self.assertEqual(run_cli("install", "--libs-only"), 0)
        mock_openscad.assert_not_called()
        mock_libs.assert_called_once()

    def test_info_skips_libs(self, mock_openscad, mock_libs):
        self.assertEqual(run_cli("install", "--info"), 0)
        mock_openscad.assert_called_once_with(force=False, check_only=False, info=True)
        mock_libs.assert_not_called()

    def test_openscad_failure_aborts_before_libs(self, mock_openscad, mock_libs):
        mock_openscad.return_value = False
        self.assertEqual(run_cli("install"), 1)
        mock_libs.assert_not_called()

    def test_openscad_outdated_on_check_still_checks_libs(self, mock_openscad, mock_libs):
        mock_openscad.return_value = False
        self.assertEqual(run_cli("install", "--check"), 1)
        mock_libs.assert_called_once()

    def test_openscad_failure_on_info_exits_1(self, mock_openscad, mock_libs):
        mock_openscad.return_value = False
        self.assertEqual(run_cli("install", "--info"), 1)
        mock_libs.assert_not_called()

    def test_libs_failure(self, _, mock_libs):
        mock_libs.return_value = False
        self.assertEqual(run_cli("install"), 1)

    def test_missing_scadm_json(self, mock_openscad, _):
        mock_openscad.side_effect = FileNotFoundError("scadm.json not found")
        self.assertEqual(run_cli("install"), 1)


class FlattenTests(unittest.TestCase):
    """Tests for the flatten subcommand."""

    @patch("scadm.cli.compute_checksum", return_value="abc123")
    def test_checksum_prints(self, mock_checksum):
        with patch("builtins.print") as mock_print:
            self.assertEqual(run_cli("flatten", "--checksum", "a.scad"), 0)
        mock_checksum.assert_called_once_with(Path("a.scad").resolve())
        mock_print.assert_called_once_with("abc123")

    @patch("scadm.cli.compute_checksum")
    def test_checksum_requires_file(self, mock_checksum):
        self.assertEqual(run_cli("flatten", "--checksum"), 1)
        mock_checksum.assert_not_called()

    @patch("scadm.cli.flatten_all", return_value=True)
    def test_all_success(self, mock_all):
        self.assertEqual(run_cli("flatten", "--all"), 0)
        mock_all.assert_called_once()

    @patch("scadm.cli.flatten_all", return_value=False)
    def test_all_failure(self, _):
        self.assertEqual(run_cli("flatten", "--all"), 1)

    @patch("scadm.cli.flatten_file")
    def test_single_file(self, mock_flatten):
        self.assertEqual(run_cli("flatten", "a.scad", "-o", "out.scad"), 0)
        mock_flatten.assert_called_once_with(Path("a.scad").resolve(), Path("out.scad").resolve())

    @patch("scadm.cli.flatten_file")
    def test_single_file_requires_output(self, mock_flatten):
        self.assertEqual(run_cli("flatten", "a.scad"), 1)
        mock_flatten.assert_not_called()

    @patch("argparse.ArgumentParser.print_help")
    def test_no_args_prints_help_and_fails(self, mock_help):
        self.assertEqual(run_cli("flatten"), 1)
        mock_help.assert_called_once()

    @patch("scadm.cli.flatten_file", side_effect=ValueError("bad include"))
    def test_flatten_error_exits_1(self, _):
        self.assertEqual(run_cli("flatten", "a.scad", "-o", "out.scad"), 1)


class RenderTests(unittest.TestCase):
    """Tests for the render subcommand."""

    @patch("scadm.cli.render_files", return_value=True)
    def test_explicit_files(self, mock_render):
        self.assertEqual(run_cli("render", "a.scad", "-j", "2"), 0)
        mock_render.assert_called_once_with([Path("a.scad").resolve()], max_workers=2)

    @patch("scadm.cli.render_files", return_value=False)
    def test_render_failure(self, _):
        self.assertEqual(run_cli("render", "a.scad"), 1)

    @patch("scadm.cli.render_files", return_value=True)
    @patch("scadm.cli.discover_flatten_files", return_value=[Path("x.scad")])
    def test_source_flag_discovers(self, mock_discover, mock_render):
        self.assertEqual(run_cli("render", "--source"), 0)
        mock_discover.assert_called_once_with(source=True, flattened=False)
        mock_render.assert_called_once_with([Path("x.scad")], max_workers=None)

    @patch("scadm.cli.render_files")
    def test_files_and_flags_conflict(self, mock_render):
        self.assertEqual(run_cli("render", "a.scad", "--flattened"), 1)
        mock_render.assert_not_called()

    @patch("argparse.ArgumentParser.print_help")
    def test_no_args_prints_help_and_fails(self, mock_help):
        self.assertEqual(run_cli("render"), 1)
        mock_help.assert_called_once()

    @patch("scadm.cli.discover_flatten_files", side_effect=ValueError("no files"))
    def test_discovery_error_exits_1(self, _):
        self.assertEqual(run_cli("render", "--flattened"), 1)


class ExportPngTests(unittest.TestCase):
    """Tests for the export-png subcommand."""

    @patch("scadm.cli.export_png", return_value=True)
    def test_defaults(self, mock_export):
        self.assertEqual(run_cli("export-png", "a.scad"), 0)
        mock_export.assert_called_once_with(
            Path("a.scad").resolve(),
            camera=cli.DEFAULT_CAMERA,
            imgsize=cli.DEFAULT_IMGSIZE,
            colorscheme=cli.DEFAULT_COLORSCHEME,
            output=None,
            projection=None,
            defines=None,
            param_file=None,
            param_set=None,
        )

    @patch("scadm.cli.export_png", return_value=True)
    def test_all_options(self, mock_export):
        argv = ["export-png", "a.scad", "--output", "o.png", "--projection", "p"]
        argv += ["-D", "x=1", "-D", "y=2", "-p", "params.json", "-P", "set1"]
        self.assertEqual(run_cli(*argv), 0)
        kwargs = mock_export.call_args.kwargs
        self.assertEqual(kwargs["output"], Path("o.png").resolve())
        self.assertEqual(kwargs["projection"], "p")
        self.assertEqual(kwargs["defines"], ["x=1", "y=2"])
        self.assertEqual(kwargs["param_file"], Path("params.json"))
        self.assertEqual(kwargs["param_set"], "set1")

    @patch("scadm.cli.export_png")
    def test_param_set_requires_param_file(self, mock_export):
        self.assertEqual(run_cli("export-png", "a.scad", "-P", "set1"), 1)
        mock_export.assert_not_called()

    @patch("scadm.cli.export_png", return_value=False)
    def test_export_failure(self, _):
        self.assertEqual(run_cli("export-png", "a.scad"), 1)

    @patch("scadm.cli.export_png", side_effect=FileNotFoundError("missing"))
    def test_export_error_exits_1(self, _):
        self.assertEqual(run_cli("export-png", "a.scad"), 1)

    @patch("scadm.cli.export_png")
    def test_empty_file_arg(self, mock_export):
        self.assertEqual(run_cli("export-png", ""), 1)
        mock_export.assert_not_called()


if __name__ == "__main__":
    unittest.main()
