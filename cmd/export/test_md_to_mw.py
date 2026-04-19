"""Tests for md-to-mw.py — MakerWorld description converter."""

import importlib
import subprocess
from pathlib import Path
from unittest.mock import patch

import pytest

# Import the module from its hyphenated filename
spec = importlib.util.spec_from_file_location("md_to_mw", Path(__file__).parent / "md-to-mw.py")
md_to_mw = importlib.util.module_from_spec(spec)
spec.loader.exec_module(md_to_mw)


class TestStripFrontmatter:
    def test_removes_yaml_frontmatter(self):
        text = "---\nfoo: bar\n---\n# Hello"
        assert md_to_mw.strip_frontmatter(text) == "# Hello"

    def test_no_frontmatter(self):
        text = "# Hello\nWorld"
        assert md_to_mw.strip_frontmatter(text) == text

    def test_empty_frontmatter_not_stripped(self):
        text = "---\n---\n# Hello"
        assert md_to_mw.strip_frontmatter(text) == text


class TestEmbedLocalImages:
    def test_external_urls_unchanged(self):
        html = '<img src="https://example.com/img.png">'
        assert md_to_mw.embed_local_images(html, Path("/tmp")) == html

    def test_data_uris_unchanged(self):
        html = '<img src="data:image/png;base64,abc">'
        assert md_to_mw.embed_local_images(html, Path("/tmp")) == html

    def test_missing_local_image_unchanged(self, tmp_path):
        html = '<img src="nonexistent.png">'
        assert md_to_mw.embed_local_images(html, tmp_path) == html

    def test_local_image_embedded(self, tmp_path):
        img = tmp_path / "test.png"
        img.write_bytes(b"\x89PNG\r\n\x1a\n")
        html = '<img src="test.png">'
        result = md_to_mw.embed_local_images(html, tmp_path)
        assert 'src="data:image/png;base64,' in result


class TestConvertYoutubeEmbeds:
    def test_youtube_linked_thumbnail_converted(self):
        html = (
            '<a href="https://www.youtube.com/watch?v=abc123">'
            '<img src="https://img.youtube.com/vi/abc123/maxresdefault.jpg">'
            "</a>"
        )
        result = md_to_mw.convert_youtube_embeds(html)
        assert '<figure class="media">' in result
        assert "youtube.com/embed/abc123" in result

    def test_non_youtube_link_unchanged(self):
        html = '<a href="https://example.com"><img src="img.png"></a>'
        assert md_to_mw.convert_youtube_embeds(html) == html


class TestAddBlockSpacing:
    def test_spacing_between_blocks(self):
        html = "</p><p>next"
        result = md_to_mw.add_block_spacing(html)
        assert "&nbsp;" in result

    def test_no_spacing_inside_block(self):
        html = "<p>hello world</p>"
        result = md_to_mw.add_block_spacing(html)
        assert "&nbsp;" not in result


class TestResolveRelativeLinks:
    @pytest.fixture()
    def git_env(self, tmp_path):
        """Set up a fake git repo structure for testing."""
        repo = tmp_path / "repo"
        repo.mkdir()
        model_dir = repo / "models" / "foot" / "makerworld"
        model_dir.mkdir(parents=True)
        desc = model_dir / "DESCRIPTION.md"
        desc.write_text("test")
        custom = model_dir / "CUSTOMIZATION.md"
        custom.write_text("test")
        return repo, desc

    def _mock_git(self, repo_root: Path):
        """Return a side_effect for subprocess.check_output that fakes git commands."""

        def side_effect(cmd, **kwargs):  # pylint: disable=unused-argument  # subprocess.check_output signature
            if "rev-parse" in cmd:
                return str(repo_root) + "\n"
            if "get-url" in cmd:
                return "git@github.com:kellerlabs/homeracker-exclusive.git\n"
            raise subprocess.CalledProcessError(1, cmd)

        return side_effect

    def test_relative_md_link_resolved(self, git_env):
        repo, desc = git_env
        html = '<a href="CUSTOMIZATION.md">Guide</a>'
        with patch("subprocess.check_output", side_effect=self._mock_git(repo)):
            result = md_to_mw.resolve_relative_links(html, desc)
        assert "github.com/kellerlabs/homeracker-exclusive/blob/main/models/foot/makerworld/CUSTOMIZATION.md" in result

    def test_absolute_url_unchanged(self, git_env):
        _, desc = git_env
        html = '<a href="https://example.com">Link</a>'
        result = md_to_mw.resolve_relative_links(html, desc)
        assert 'href="https://example.com"' in result

    def test_anchor_link_unchanged(self, git_env):
        _, desc = git_env
        html = '<a href="#section">Jump</a>'
        result = md_to_mw.resolve_relative_links(html, desc)
        assert 'href="#section"' in result

    def test_mailto_unchanged(self, git_env):
        _, desc = git_env
        html = '<a href="mailto:a@b.com">Email</a>'
        result = md_to_mw.resolve_relative_links(html, desc)
        assert 'href="mailto:a@b.com"' in result

    def test_git_unavailable_returns_unchanged(self, tmp_path):
        desc = tmp_path / "DESCRIPTION.md"
        desc.write_text("test")
        html = '<a href="CUSTOMIZATION.md">Guide</a>'
        with patch("subprocess.check_output", side_effect=FileNotFoundError):
            result = md_to_mw.resolve_relative_links(html, desc)
        assert 'href="CUSTOMIZATION.md"' in result

    def test_parent_relative_link(self, git_env):
        repo, desc = git_env
        html = '<a href="../README.md">README</a>'
        with patch("subprocess.check_output", side_effect=self._mock_git(repo)):
            result = md_to_mw.resolve_relative_links(html, desc)
        assert "github.com/kellerlabs/homeracker-exclusive/blob/main/models/foot/README.md" in result
