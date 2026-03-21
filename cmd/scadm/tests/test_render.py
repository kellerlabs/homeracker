"""Tests for scadm.render module."""

import json
import tempfile
import unittest
from pathlib import Path

from scadm.render import discover_flatten_files


class DiscoverFlattenFilesTests(unittest.TestCase):
    def _make_workspace(self, tmp, flatten_config, src_files=None, dest_files=None):
        """Create a minimal workspace with scadm.json and .scad files.

        Args:
            tmp: Temporary directory root.
            flatten_config: List of {"src": ..., "dest": ...} dicts.
            src_files: List of relative paths to create in src dirs.
            dest_files: List of relative paths to create in dest dirs.

        Returns:
            Path to workspace root.
        """
        root = Path(tmp)
        config = {"dependencies": [], "flatten": flatten_config}
        (root / "scadm.json").write_text(json.dumps(config), encoding="utf-8")

        for entry in flatten_config:
            (root / entry["src"]).mkdir(parents=True, exist_ok=True)
            (root / entry["dest"]).mkdir(parents=True, exist_ok=True)

        for f in src_files or []:
            p = root / f
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("cube(1);\n", encoding="utf-8")

        for f in dest_files or []:
            p = root / f
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("cube(1);\n", encoding="utf-8")

        return root

    def test_flattened_discovers_dest_files(self):
        """--flattened discovers .scad files from flatten dest dirs."""
        with tempfile.TemporaryDirectory() as tmp:
            root = self._make_workspace(
                tmp,
                [{"src": "models/parts", "dest": "models/flattened"}],
                dest_files=["models/flattened/a.scad", "models/flattened/b.scad"],
            )
            files = discover_flatten_files(root, flattened=True)
            names = [f.name for f in files]
            self.assertEqual(names, ["a.scad", "b.scad"])

    def test_source_discovers_src_files(self):
        """--source discovers .scad files from flatten src dirs."""
        with tempfile.TemporaryDirectory() as tmp:
            root = self._make_workspace(
                tmp,
                [{"src": "models/parts", "dest": "models/flattened"}],
                src_files=["models/parts/x.scad"],
            )
            files = discover_flatten_files(root, source=True)
            self.assertEqual([f.name for f in files], ["x.scad"])

    def test_source_excludes_dest_subdir(self):
        """--source excludes files under the dest dir even if nested in src."""
        with tempfile.TemporaryDirectory() as tmp:
            root = self._make_workspace(
                tmp,
                [{"src": "models", "dest": "models/flattened"}],
                src_files=["models/a.scad"],
                dest_files=["models/flattened/a.scad"],
            )
            files = discover_flatten_files(root, source=True)
            names = [f.name for f in files]
            self.assertEqual(names, ["a.scad"])
            # Must be the src file, not the dest file
            self.assertNotIn("flattened", str(files[0]))

    def test_combined_source_and_flattened(self):
        """--source --flattened returns both sets, deduplicated and sorted."""
        with tempfile.TemporaryDirectory() as tmp:
            root = self._make_workspace(
                tmp,
                [{"src": "models/parts", "dest": "models/flattened"}],
                src_files=["models/parts/main.scad"],
                dest_files=["models/flattened/main.scad"],
            )
            files = discover_flatten_files(root, source=True, flattened=True)
            self.assertEqual(len(files), 2)

    def test_multiple_flatten_entries(self):
        """Discovers files across multiple flatten config entries."""
        with tempfile.TemporaryDirectory() as tmp:
            root = self._make_workspace(
                tmp,
                [
                    {"src": "models/core/parts", "dest": "models/core/flattened"},
                    {"src": "models/grid/parts", "dest": "models/grid/flattened"},
                ],
                dest_files=[
                    "models/core/flattened/a.scad",
                    "models/grid/flattened/b.scad",
                ],
            )
            files = discover_flatten_files(root, flattened=True)
            names = [f.name for f in files]
            self.assertIn("a.scad", names)
            self.assertIn("b.scad", names)

    def test_no_files_found_raises(self):
        """Raises ValueError when no .scad files are found."""
        with tempfile.TemporaryDirectory() as tmp:
            root = self._make_workspace(
                tmp,
                [{"src": "models/parts", "dest": "models/flattened"}],
            )
            with self.assertRaises(ValueError):
                discover_flatten_files(root, flattened=True)

    def test_no_flatten_config_raises(self):
        """Raises ValueError when scadm.json has no flatten entries."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "scadm.json").write_text(json.dumps({"dependencies": []}), encoding="utf-8")
            with self.assertRaises(ValueError):
                discover_flatten_files(root, flattened=True)

    def test_missing_scadm_json_raises(self):
        """Raises FileNotFoundError when scadm.json doesn't exist."""
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(FileNotFoundError):
                discover_flatten_files(Path(tmp), source=True)

    def test_neither_flag_raises(self):
        """Raises ValueError when neither source nor flattened is set."""
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError, msg="At least one of source or flattened must be True."):
                discover_flatten_files(Path(tmp))


if __name__ == "__main__":
    unittest.main()
