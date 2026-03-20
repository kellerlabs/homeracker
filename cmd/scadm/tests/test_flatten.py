"""Tests for scadm.flatten module."""

import tempfile
import unittest
from pathlib import Path

from scadm.flatten import flatten_file


class FlattenTests(unittest.TestCase):
    def test_inlines_scadm_library_before_hidden_assignments(self):
        """Library include resolved via scadm.json is inlined BEFORE the root
        file's [Hidden] assignments, so root code can reference library constants
        (e.g. PANEL_PRIMARY_COLOR = HR_YELLOW where HR_YELLOW comes from the library).
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            (root / "bin" / "openscad" / "libraries" / "homeracker" / "models" / "core" / "lib").mkdir(parents=True)

            (root / "scadm.json").write_text(
                '{"dependencies": [{"name": "BOSL2"}, {"name": "homeracker"}]}\n',
                encoding="utf-8",
            )

            constants = (
                root / "bin" / "openscad" / "libraries" / "homeracker" / "models" / "core" / "lib" / "constants.scad"
            )
            constants.write_text("HR_YELLOW = [1,1,0];\n", encoding="utf-8")

            src_dir = root / "src"
            src_dir.mkdir()
            input_file = src_dir / "panel.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <BOSL2/std.scad>",
                        "include <homeracker/models/core/lib/constants.scad>",
                        "",
                        "/* [General] */",
                        "variant = 1;",
                        "",
                        "/* [Hidden] */",
                        "$fn=100;",
                        "EPSILON = 0.01;",
                        "PANEL_PRIMARY_COLOR = HR_YELLOW;",
                        "",
                        "module main() { }",
                        "main();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            output_file = root / "out" / "panel.scad"
            flatten_file(input_file, output_file, workspace_root=root)

            out = output_file.read_text(encoding="utf-8")
            self.assertIn("include <BOSL2/std.scad>", out)
            self.assertIn("$fn=100;", out)
            self.assertEqual(out.count("$fn=100;"), 1)
            self.assertIn("EPSILON = 0.01;", out)
            # Library constants emitted before root Hidden assignments
            self.assertLess(out.find("HR_YELLOW"), out.find("PANEL_PRIMARY_COLOR"))

    def test_preserves_keyword_arg_lines_in_multiline_calls(self):
        """Lines like `view_mode=1);` inside module bodies look like assignments
        but are actually keyword arguments in multi-line function calls.
        They must NOT be stripped by the leading-assignment skipper.
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "scadm.json").write_text('{"dependencies": []}\n', encoding="utf-8")

            src_dir = root / "src"
            src_dir.mkdir()
            input_file = src_dir / "unimount.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "/* [General] */",
                        "variant = 1;",
                        "",
                        "/* [Hidden] */",
                        "$fn=100;",
                        "EPSILON = 0.01;",
                        "",
                        "module mw_assembly_view() {",
                        "  bracket_color = true ? 1 : 2;",
                        "  frontpanel(variant,",
                        "    view_mode=1);",
                        "}",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            output_file = root / "out" / "unimount.scad"
            flatten_file(input_file, output_file, workspace_root=root)
            out = output_file.read_text(encoding="utf-8")

            self.assertEqual(out.count("$fn=100;"), 1)
            self.assertIn("view_mode=1);", out)
            self.assertIn("bracket_color = true ? 1 : 2;", out)

    def test_inlines_relative_include(self):
        """A relative include like `include <lib/helper.scad>` is resolved
        relative to the input file and its content is inlined into the output.
        The original include directive is removed.
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "scadm.json").write_text('{"dependencies": []}\n', encoding="utf-8")

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "helper.scad").write_text("function helper_fn() = 42;\n", encoding="utf-8")

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/helper.scad>",
                        "",
                        "/* [General] */",
                        "size = 10;",
                        "",
                        "/* [Hidden] */",
                        "$fn=50;",
                        "",
                        "cube(size);",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            output_file = root / "out" / "main.scad"
            flatten_file(input_file, output_file, workspace_root=root)
            out = output_file.read_text(encoding="utf-8")

            self.assertIn("helper_fn", out)
            self.assertNotIn("include <lib/helper.scad>", out)

    def test_output_ends_with_single_newline(self):
        """Output must end with exactly one newline (POSIX convention).
        No trailing blank lines.
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)

            (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
            (root / "scadm.json").write_text('{"dependencies": []}\n', encoding="utf-8")

            src_dir = root / "src"
            src_dir.mkdir()
            input_file = src_dir / "simple.scad"
            input_file.write_text("cube(1);\n", encoding="utf-8")

            output_file = root / "out" / "simple.scad"
            flatten_file(input_file, output_file, workspace_root=root)
            out = output_file.read_text(encoding="utf-8")

            self.assertTrue(out.endswith("\n"))
            self.assertFalse(out.endswith("\n\n"))


if __name__ == "__main__":
    unittest.main()
