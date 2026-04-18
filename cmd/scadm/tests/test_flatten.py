"""Tests for scadm.flatten module."""

import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import scadm.flatten as flatten_mod
from scadm.flatten import (
    _Definition,
    _parse_definitions,
    _resolve_dependencies,
    compute_checksum,
    flatten_file,
)


def _make_workspace(root: Path, *, deps: str = '{"dependencies": []}') -> None:
    """Create a minimal scadm workspace at *root*."""
    (root / "bin" / "openscad" / "libraries").mkdir(parents=True)
    (root / "scadm.json").write_text(deps + "\n", encoding="utf-8")


def _flatten(root: Path, input_file: Path) -> str:
    """Run flatten_file and return the output text."""
    output_file = root / "out" / input_file.name
    flatten_file(input_file, output_file, workspace_root=root)
    return output_file.read_text(encoding="utf-8")


class ParseDefinitionsTests(unittest.TestCase):
    """Unit tests for the _parse_definitions helper."""

    def test_parses_simple_variable(self):
        defs = _parse_definitions("FOO = 42;")
        self.assertEqual(len(defs), 1)
        self.assertEqual(defs[0].kind, "variable")
        self.assertEqual(defs[0].name, "FOO")

    def test_parses_multiline_variable(self):
        defs = _parse_definitions("BAR =\n  [1,2,\n  3];")
        self.assertEqual(len(defs), 1)
        self.assertEqual(defs[0].name, "BAR")
        self.assertEqual(len(defs[0].lines), 3)

    def test_parses_module(self):
        defs = _parse_definitions("module foo() {\n  cube(1);\n}")
        self.assertEqual(len(defs), 1)
        self.assertEqual(defs[0].kind, "module")
        self.assertEqual(defs[0].name, "foo")

    def test_parses_function(self):
        defs = _parse_definitions("function bar(x) = x * 2;")
        self.assertEqual(len(defs), 1)
        self.assertEqual(defs[0].kind, "function")
        self.assertEqual(defs[0].name, "bar")

    def test_parses_mixed_content(self):
        content = "A = 1;\nmodule m() { cube(A); }\nB = 2;"
        defs = _parse_definitions(content)
        self.assertEqual(len(defs), 3)
        names = [d.name for d in defs]
        self.assertEqual(names, ["A", "m", "B"])

    def test_ignores_section_markers(self):
        content = "/* [Hidden] */\nX = 1;\nmodule m() { }"
        defs = _parse_definitions(content)
        names = [d.name for d in defs]
        self.assertIn("X", names)
        self.assertIn("m", names)

    def test_preserves_origin(self):
        defs = _parse_definitions("A = 1;", origin="constants.scad")
        self.assertEqual(defs[0].origin, "constants.scad")


class ResolveDependenciesTests(unittest.TestCase):
    """Unit tests for the _resolve_dependencies helper."""

    def test_includes_direct_dependency(self):
        defs = [
            _Definition("variable", "A", ["A = 1;"]),
            _Definition("variable", "B", ["B = 2;"]),
        ]
        result = _resolve_dependencies({"A"}, defs)
        names = [d.name for d in result]
        self.assertIn("A", names)
        self.assertNotIn("B", names)

    def test_includes_transitive_dependency(self):
        defs = [
            _Definition("variable", "BASE", ["BASE = 10;"]),
            _Definition("variable", "DERIVED", ["DERIVED = BASE + 1;"]),
        ]
        result = _resolve_dependencies({"DERIVED"}, defs)
        names = [d.name for d in result]
        self.assertIn("BASE", names)
        self.assertIn("DERIVED", names)

    def test_excludes_unused(self):
        defs = [
            _Definition("variable", "USED", ["USED = 1;"]),
            _Definition("variable", "UNUSED", ["UNUSED = 2;"]),
            _Definition("module", "needed", ["module needed() { cube(USED); }"]),
        ]
        result = _resolve_dependencies({"needed"}, defs)
        names = [d.name for d in result]
        self.assertIn("needed", names)
        self.assertIn("USED", names)
        self.assertNotIn("UNUSED", names)

    def test_module_calling_module(self):
        defs = [
            _Definition("module", "inner", ["module inner() { cube(1); }"]),
            _Definition("module", "outer", ["module outer() { inner(); }"]),
        ]
        result = _resolve_dependencies({"outer"}, defs)
        names = [d.name for d in result]
        self.assertIn("inner", names)
        self.assertIn("outer", names)


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
                        "cube(helper_fn());",
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

    def test_checksum_independent_of_flatten_py_location(self):
        """compute_checksum hashes flatten.py at a fixed position, so its
        install location never affects the digest — even when library deps
        in bin/openscad/libraries/ would sort between possible flatten.py
        positions.
        """
        with tempfile.TemporaryDirectory() as tmp_workspace, tempfile.TemporaryDirectory() as tmp_site:
            root = Path(tmp_workspace)

            # Set up a scadm dependency so bin/openscad/libraries/ files
            # are included in the transitive dep tree.
            lib_dir = root / "bin" / "openscad" / "libraries" / "mylib" / "lib"
            lib_dir.mkdir(parents=True)
            (lib_dir / "helper.scad").write_text("function h() = 1;\n", encoding="utf-8")

            (root / "scadm.json").write_text(
                '{"dependencies": [{"name": "mylib"}]}\n',
                encoding="utf-8",
            )

            src_dir = root / "src"
            src_dir.mkdir()
            input_file = src_dir / "main.scad"
            input_file.write_text(
                "include <mylib/lib/helper.scad>\ncube(1);\n",
                encoding="utf-8",
            )

            checksum = compute_checksum(input_file, workspace_root=root)

            # Place flatten.py completely outside the workspace tree.
            alt_dir = Path(tmp_site) / "alt_site_packages" / "scadm"
            alt_dir.mkdir(parents=True)
            alt_flatten = alt_dir / "flatten.py"
            shutil.copy2(flatten_mod.__file__, alt_flatten)

            with patch.object(flatten_mod, "__file__", str(alt_flatten)):
                checksum_alt = compute_checksum(input_file, workspace_root=root)

            self.assertEqual(checksum, checksum_alt)

    # --- New resilience tests ---

    def test_lib_with_section_markers_no_error(self):
        """Library files with section markers must NOT raise ValueError.
        The markers should be silently ignored.
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            # Library with section markers (previously caused ValueError)
            (lib_dir / "marked.scad").write_text(
                "\n".join(
                    [
                        "/* [Constants] */",
                        "MAGIC = 42;",
                        "",
                        "/* [Hidden] */",
                        "SECRET = 7;",
                        "",
                        "module magic_cube() { cube(MAGIC); }",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/marked.scad>",
                        "",
                        "/* [General] */",
                        "size = 10;",
                        "",
                        "/* [Hidden] */",
                        "$fn=100;",
                        "",
                        "magic_cube();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            # Should NOT raise
            out = _flatten(root, input_file)
            self.assertIn("magic_cube", out)
            self.assertIn("MAGIC", out)

    def test_only_used_variables_included(self):
        """Only variables that are transitively used should appear in output."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "constants.scad").write_text(
                "\n".join(
                    [
                        "USED_VAR = 42;",
                        "UNUSED_VAR = 99;",
                        "CHAIN_A = 1;",
                        "CHAIN_B = CHAIN_A + 1;",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/constants.scad>",
                        "",
                        "/* [Hidden] */",
                        "$fn=100;",
                        "",
                        "cube(USED_VAR);",
                        "echo(CHAIN_B);",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("USED_VAR", out)
            self.assertNotIn("UNUSED_VAR", out)
            # Transitive: CHAIN_B uses CHAIN_A
            self.assertIn("CHAIN_B", out)
            self.assertIn("CHAIN_A", out)

    def test_only_used_modules_included(self):
        """Unused modules from libraries should be omitted."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "shapes.scad").write_text(
                "\n".join(
                    [
                        "module used_shape() { cube(1); }",
                        "module unused_shape() { sphere(1); }",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/shapes.scad>",
                        "",
                        "used_shape();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("used_shape", out)
            self.assertNotIn("unused_shape", out)

    def test_transitive_module_dependency(self):
        """Modules calling other modules must pull in the entire chain."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "base.scad").write_text(
                "BASE_SIZE = 10;\nmodule base_block() { cube(BASE_SIZE); }\n",
                encoding="utf-8",
            )

            (lib_dir / "composite.scad").write_text(
                "\n".join(
                    [
                        "include <base.scad>",
                        "module composite() { base_block(); }",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/composite.scad>",
                        "",
                        "composite();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("composite", out)
            self.assertIn("base_block", out)
            self.assertIn("BASE_SIZE", out)

    def test_sections_only_from_root_file(self):
        """Section markers from lib files must NOT appear in output.
        Only root file sections should be preserved.
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "lib_with_sections.scad").write_text(
                "\n".join(
                    [
                        "/* [LibSection] */",
                        "LIB_CONST = 5;",
                        "module lib_mod() { cube(LIB_CONST); }",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/lib_with_sections.scad>",
                        "",
                        "/* [RootSection] */",
                        "root_param = 10;",
                        "",
                        "/* [Hidden] */",
                        "$fn=100;",
                        "",
                        "lib_mod();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            # Root section preserved
            self.assertIn("/* [RootSection] */", out)
            # Library section marker NOT in output
            self.assertNotIn("/* [LibSection] */", out)
            # But library content IS present
            self.assertIn("LIB_CONST", out)
            self.assertIn("lib_mod", out)

    def test_variables_scattered_in_root_file(self):
        """Variables in root file outside sections go to hidden section.
        Variables inside named sections stay in those sections.
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            src_dir.mkdir()

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "/* [General] */",
                        "width = 10;",
                        "",
                        "/* [Debug Parameters] */",
                        "debug = false;",
                        "",
                        "/* [Hidden] */",
                        "$fn = 100;",
                        "EPSILON = 0.01;",
                        "",
                        "module main_mod() { cube(width); }",
                        "main_mod();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            # Section params stay in sections
            self.assertIn("/* [General] */", out)
            self.assertIn("width = 10;", out)
            self.assertIn("/* [Debug Parameters] */", out)
            self.assertIn("debug = false;", out)
            # Hidden vars preserved
            self.assertIn("$fn = 100;", out)
            self.assertIn("EPSILON = 0.01;", out)
            # Module and call preserved
            self.assertIn("main_mod", out)

    def test_lib_variables_get_origin_comment(self):
        """Variables from library files should have origin comments."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "myconst.scad").write_text("MY_CONST = 42;\n", encoding="utf-8")

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/myconst.scad>",
                        "",
                        "/* [Hidden] */",
                        "$fn=100;",
                        "",
                        "cube(MY_CONST);",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("MY_CONST = 42;", out)
            self.assertIn("// --- from myconst.scad ---", out)

    def test_multiline_variable_in_lib(self):
        """Multiline variable assignments in libraries are handled correctly."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "multi.scad").write_text(
                "CONFIGS = [\n  [1, 2],\n  [3, 4]\n];\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/multi.scad>",
                        "echo(CONFIGS);",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("CONFIGS", out)
            self.assertIn("[1, 2]", out)
            self.assertIn("[3, 4]", out)

    def test_function_in_lib_included_when_used(self):
        """Functions from libraries should be included when called."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "funcs.scad").write_text(
                "\n".join(
                    [
                        "function used_fn(x) = x * 2;",
                        "function unused_fn(x) = x + 1;",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/funcs.scad>",
                        "echo(used_fn(5));",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("used_fn", out)
            self.assertNotIn("unused_fn", out)

    def test_dollar_variable_in_lib(self):
        """$-prefixed variables from libraries are handled correctly."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "special.scad").write_text(
                "$custom_var = 50;\nmodule special() { cube($custom_var); }\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/special.scad>",
                        "special();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("special", out)

    def test_nested_module_definitions(self):
        """Modules containing nested module definitions are handled correctly."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "nested.scad").write_text(
                "\n".join(
                    [
                        "module outer() {",
                        "  module inner() {",
                        "    cube(1);",
                        "  }",
                        "  inner();",
                        "}",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/nested.scad>",
                        "outer();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("module outer()", out)
            self.assertIn("module inner()", out)
            self.assertIn("outer();", out)

    def test_deep_include_chain(self):
        """Three-level include chain: root -> lib_a -> lib_b -> lib_c."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "c.scad").write_text("C_VAL = 1;\n", encoding="utf-8")
            (lib_dir / "b.scad").write_text(
                "include <c.scad>\nB_VAL = C_VAL + 1;\n",
                encoding="utf-8",
            )
            (lib_dir / "a.scad").write_text(
                "include <b.scad>\nmodule use_chain() { cube(B_VAL); }\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "include <lib/a.scad>\nuse_chain();\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("C_VAL", out)
            self.assertIn("B_VAL", out)
            self.assertIn("use_chain", out)

    def test_lib_vars_before_root_hidden(self):
        """Library variables must appear before root hidden section
        so root hidden can reference library constants.
        """
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "colors.scad").write_text(
                'HR_YELLOW = "#f7b600";\n',
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/colors.scad>",
                        "",
                        "/* [Hidden] */",
                        "PRIMARY_COLOR = HR_YELLOW;",
                        "",
                        "module m() { echo(PRIMARY_COLOR); }",
                        "m();",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            # HR_YELLOW from lib must come before PRIMARY_COLOR from root hidden
            self.assertLess(out.find("HR_YELLOW"), out.find("PRIMARY_COLOR"))

    def test_unused_include_file_content_omitted(self):
        """If an included file's definitions are not used, its content is omitted."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "unused_lib.scad").write_text(
                "UNUSED_CONST = 999;\nmodule unused_mod() { cube(1); }\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/unused_lib.scad>",
                        "",
                        "cube(1);",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertNotIn("UNUSED_CONST", out)
            self.assertNotIn("unused_mod", out)

    def test_dollar_variable_only_usage_from_lib(self):
        """A $-variable as the only usage from a lib must still be included."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _make_workspace(root)

            src_dir = root / "src"
            lib_dir = src_dir / "lib"
            lib_dir.mkdir(parents=True)

            (lib_dir / "defaults.scad").write_text(
                "$my_resolution = 64;\nUNUSED = 999;\n",
                encoding="utf-8",
            )

            input_file = src_dir / "main.scad"
            input_file.write_text(
                "\n".join(
                    [
                        "include <lib/defaults.scad>",
                        "",
                        "sphere($my_resolution);",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            out = _flatten(root, input_file)
            self.assertIn("$my_resolution", out)
            self.assertNotIn("UNUSED", out)


if __name__ == "__main__":
    unittest.main()
