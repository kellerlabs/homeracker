"""Tests for scadm.render module."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scadm.render import discover_flatten_files, render_files


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

    def test_missing_configured_dir_raises(self):
        """Raises ValueError when a configured flatten dir doesn't exist."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = {"dependencies": [], "flatten": [{"src": "missing/src", "dest": "missing/dest"}]}
            (root / "scadm.json").write_text(json.dumps(config), encoding="utf-8")
            with self.assertRaises(ValueError, msg="Configured flatten directories not found"):
                discover_flatten_files(root, flattened=True)

    def test_malformed_flatten_entry_raises(self):
        """Raises ValueError when a flatten entry is missing src or dest."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = {"dependencies": [], "flatten": [{"src": "models/parts"}]}
            (root / "scadm.json").write_text(json.dumps(config), encoding="utf-8")
            with self.assertRaises(ValueError):
                discover_flatten_files(root, source=True)

    def test_invalid_json_raises(self):
        """Raises ValueError when scadm.json contains invalid JSON."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "scadm.json").write_text("{invalid json", encoding="utf-8")
            with self.assertRaises(ValueError):
                discover_flatten_files(root, source=True)


class RenderFilesTests(unittest.TestCase):
    @patch("scadm.render.render_file", return_value=True)
    @patch("scadm.render.get_workspace_root", return_value=Path("/fake"))
    def test_all_pass_returns_true(self, _mock_root, mock_render):
        """Returns True when all renders succeed."""
        files = [Path("a.scad"), Path("b.scad"), Path("c.scad")]
        self.assertTrue(render_files(files, max_workers=2))
        self.assertEqual(mock_render.call_count, 3)

    @patch("scadm.render.render_file", side_effect=[True, False, True])
    @patch("scadm.render.get_workspace_root", return_value=Path("/fake"))
    def test_partial_failure_returns_false(self, _mock_root, _mock_render):
        """Returns False when any render fails."""
        files = [Path("a.scad"), Path("b.scad"), Path("c.scad")]
        self.assertFalse(render_files(files, max_workers=1))

    def test_zero_jobs_raises(self):
        """Raises ValueError for max_workers=0."""
        with self.assertRaises(ValueError, msg="--jobs must be at least 1"):
            render_files([Path("a.scad")], workspace_root=Path("/fake"), max_workers=0)

    def test_negative_jobs_raises(self):
        """Raises ValueError for negative max_workers."""
        with self.assertRaises(ValueError, msg="--jobs must be at least 1"):
            render_files([Path("a.scad")], workspace_root=Path("/fake"), max_workers=-1)

    @patch("scadm.render.render_file", return_value=True)
    @patch("scadm.render.get_workspace_root", return_value=Path("/fake"))
    def test_workers_capped_to_file_count(self, _mock_root, mock_render):
        """Workers are capped to file count even if max_workers is higher."""
        files = [Path("a.scad"), Path("b.scad")]
        self.assertTrue(render_files(files, max_workers=100))
        self.assertEqual(mock_render.call_count, 2)


if __name__ == "__main__":
    unittest.main()
