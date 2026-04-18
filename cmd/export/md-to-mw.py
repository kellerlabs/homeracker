#!/usr/bin/env python3
# pylint: disable=invalid-name
"""Convert a MakerWorld DESCRIPTION.md to pasteable HTML for CKEditor.

Reads a markdown description file, strips YAML frontmatter, converts to HTML,
and embeds local images as base64 data URIs so the HTML is fully self-contained.
External image URLs (http/https) are left unchanged.

Usage:
    python cmd/export/md-to-mw.py models/foot/makerworld/DESCRIPTION.md
    python cmd/export/md-to-mw.py models/foot/makerworld/DESCRIPTION.md --open
"""

import argparse
import base64
import mimetypes
import re
import subprocess
import sys
import webbrowser
from pathlib import Path

import markdown


def strip_frontmatter(text: str) -> str:
    """Remove YAML frontmatter delimited by --- from markdown content.

    Args:
        text: Raw markdown content possibly starting with YAML frontmatter.

    Returns:
        Markdown content without frontmatter.
    """
    match = re.match(r"^---[ \t]*\r?\n.*?\r?\n---[ \t]*(?:\r?\n|$)", text, flags=re.DOTALL)
    if match:
        return text[match.end() :]
    return text


def embed_local_images(html: str, base_path: Path) -> str:
    """Replace relative image src attributes with base64 data URIs.

    Local images are read from disk and embedded directly into the HTML so the
    output is fully self-contained. External URLs (http/https) are left as-is.

    Args:
        html: HTML content with potentially relative image paths.
        base_path: Directory containing the DESCRIPTION.md file.

    Returns:
        HTML with local images embedded as base64 data URIs.
    """

    def replace_src(match: re.Match) -> str:
        src = match.group(1)
        if src.startswith(("http://", "https://", "data:")):
            return match.group(0)
        abs_path = (base_path / src).resolve()
        if not abs_path.is_relative_to(base_path.resolve()):
            print(f"Warning: path escapes base directory, skipping embed: {src}", file=sys.stderr)
            return match.group(0)
        if not abs_path.is_file():
            print(f"Warning: local image not found, skipping embed: {abs_path}", file=sys.stderr)
            return match.group(0)
        mime_type = mimetypes.guess_type(str(abs_path))[0] or "application/octet-stream"
        encoded = base64.b64encode(abs_path.read_bytes()).decode("ascii")
        return f'src="data:{mime_type};base64,{encoded}"'

    return re.sub(r'src="([^"]*)"', replace_src, html)


def convert_youtube_embeds(html: str) -> str:
    """Replace YouTube linked thumbnail images with CKEditor media embeds.

    Detects patterns like ``<a href="youtube-url"><img src="thumb"></a>`` and
    replaces them with CKEditor 5's ``<figure class="media">`` structure that
    MakerWorld's editor recognises as an embedded video.

    Args:
        html: HTML content with potential YouTube linked thumbnails.

    Returns:
        HTML with YouTube links converted to CKEditor media embeds.
    """
    # Match <a> wrapping an <img> where href points to YouTube
    pattern = (
        r'<a\s+href="(https?://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]+)[^"]*)"[^>]*>'
        r"\s*<img[^>]*>\s*</a>"
    )

    def build_embed(match: re.Match) -> str:
        video_id = match.group(2)
        # Normalise to full youtube.com/watch URL for data-oembed-url
        watch_url = f"https://www.youtube.com/watch?v={video_id}"
        return (
            f'<figure class="media">'
            f'<div data-oembed-url="{watch_url}">'
            f'<div style="position: relative; height: 0; padding-bottom: 56.2493%;">'
            f'<iframe src="https://www.youtube.com/embed/{video_id}" '
            f'style="position: absolute; width: 100%; height: 100%; top: 0; left: 0;" '
            f'frameborder="0" allow="autoplay; encrypted-media" allowfullscreen=""></iframe>'
            f"</div></div></figure>"
        )

    return re.sub(pattern, build_embed, html)


def add_block_spacing(html: str) -> str:
    """Insert &nbsp; between consecutive block elements for CKEditor spacing.

    MakerWorld's CKEditor strips paragraph margins, causing blocks to run
    together. A bare ``&nbsp;`` between closing and opening block tags produces
    a single visual empty line in the editor.

    Args:
        html: HTML content with consecutive block elements.

    Returns:
        HTML with ``&nbsp;`` spacers between block elements.
    """
    return re.sub(
        r"(</(?:p|ul|ol|pre|blockquote|table|hr)>)\s*(<(?:p|h[1-6]|ul|ol|pre|blockquote|table|hr)[ >/])",
        r"\1\n&nbsp;\n\2",
        html,
    )


def github_source_url(file_path: Path) -> str | None:
    """Derive a GitHub blob URL for a file from git remote and repo root.

    Args:
        file_path: Absolute path to a file inside a git repository.

    Returns:
        GitHub URL string, or None if git info unavailable.
    """
    try:
        repo_root = Path(
            subprocess.check_output(["git", "rev-parse", "--show-toplevel"], cwd=file_path.parent, text=True).strip()
        )
        remote = subprocess.check_output(["git", "remote", "get-url", "origin"], cwd=repo_root, text=True).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

    # Normalise git@github.com:owner/repo.git and https://github.com/owner/repo.git
    match = re.search(r"github\.com[:/](.+?)(?:\.git)?$", remote)
    if not match:
        return None
    owner_repo = match.group(1)
    try:
        rel_path = file_path.relative_to(repo_root).as_posix()
    except ValueError:
        return None
    return f"https://github.com/{owner_repo}/blob/main/{rel_path}"


def convert(input_path: Path) -> str:
    """Convert a DESCRIPTION.md file to HTML with embedded local images.

    Args:
        input_path: Path to the DESCRIPTION.md file.

    Returns:
        HTML string ready for pasting into MakerWorld CKEditor.
    """
    md_content = input_path.read_text(encoding="utf-8")
    md_content = strip_frontmatter(md_content)

    html = markdown.markdown(md_content, extensions=["tables", "fenced_code", "sane_lists"])
    html = embed_local_images(html, input_path.parent)
    html = convert_youtube_embeds(html)
    html = add_block_spacing(html)

    source_url = github_source_url(input_path)
    from_md = f'from <a href="{source_url}">Markdown</a>' if source_url else "from Markdown"
    footer = (
        f"\n&nbsp;\n<p><em>This description was generated {from_md} using "
        '<a href="https://github.com/kellerlabs/homeracker/blob/main/docs/makerworld-workflow.md">'
        "md-to-mw</a> \u2014 version-controlled descriptions for easier maintenance.</em></p>"
    )
    html += footer

    return html


def wrap_html(body: str) -> str:
    """Wrap HTML body in a minimal document for browser preview.

    Args:
        body: HTML body content.

    Returns:
        Complete HTML document string.
    """
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MakerWorld Description Preview</title>
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
         max-width: 800px; margin: 2rem auto; padding: 0 1rem; line-height: 1.6; }}
  h1, h2, h3, h4, h5, h6, p, ul, ol, pre, blockquote, table {{ margin: 0; padding-top: 0; padding-bottom: 0; }}
  img {{ max-width: 100%; height: auto; }}
  pre {{ background: #f4f4f4; padding: 1rem; overflow-x: auto; border-radius: 4px; }}
  code {{ background: #f4f4f4; padding: 0.2em 0.4em; border-radius: 3px; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
</style>
</head>
<body>
{body}
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser(description="Convert DESCRIPTION.md to pasteable HTML for MakerWorld CKEditor")
    parser.add_argument("input", type=Path, help="Path to DESCRIPTION.md")
    parser.add_argument("--output", "-o", type=Path, help="Output HTML path (default: DESCRIPTION.html next to input)")
    parser.add_argument("--open", action="store_true", help="Open the generated HTML in the default browser")
    args = parser.parse_args()

    if not args.input.exists():
        print(f"Error: {args.input} not found", file=sys.stderr)
        sys.exit(1)

    body_html = convert(args.input.resolve())

    output_path = args.output or args.input.parent / "DESCRIPTION.html"
    full_html = wrap_html(body_html)
    output_path.write_text(full_html, encoding="utf-8")
    print(f"Generated: {output_path}")

    if args.open:
        webbrowser.open(output_path.resolve().as_uri())
        print("Opened in browser")


if __name__ == "__main__":
    main()
