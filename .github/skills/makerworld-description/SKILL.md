---
name: makerworld-description
description: >
  Extract MakerWorld model descriptions into git-tracked DESCRIPTION.md files,
  or convert them back to pasteable HTML for MakerWorld's CKEditor.
  USE FOR: extracting descriptions from MakerWorld model pages, creating new
  DESCRIPTION.md files, updating existing descriptions, converting markdown
  descriptions to HTML for MakerWorld publishing.
  DO NOT USE FOR: uploading files to MakerWorld, managing print profiles, or
  OpenSCAD model creation (use @makerworld-model agent instead).
---

# 🌐 MakerWorld Description Skill

## 📌 What

Manages MakerWorld model descriptions as git-tracked `DESCRIPTION.md` files. Supports two flows:

1. **Extract** (MakerWorld → Git): Scrape a MakerWorld model page and produce a clean `DESCRIPTION.md` + images
2. **Publish** (Git → MakerWorld): Convert `DESCRIPTION.md` to HTML for pasting into MakerWorld's CKEditor

## 🔧 Extract Flow

Given a MakerWorld model URL, extract the description into a `DESCRIPTION.md` file.

### Steps

1. **Ask the user** which model this is for and where to save it:
   - Target repo (`homeracker` or `homeracker-exclusive`)
   - Model name (e.g. `core`, `foot`, `frontpanel`)
   - Output path defaults to `models/<name>/makerworld/DESCRIPTION.md`

2. **Fetch the page** using `fetch_webpage` with query `"model description details"` and the MakerWorld URL.

3. **Parse the Description section**. The description content is between the `### Description` heading and the `### Comment & Rating` section. Extract only this content. Ignore:
   - Navigation elements, cookie banners, footer
   - Print Profile section, Bill of Materials
   - Comment & Rating section and all comments
   - Remixes, Related Models sections
   - "We use cookies" banner

4. **Clean the markdown**:
   - Convert extracted content to well-formatted markdown
   - Preserve: headings (##, ###), bold/italic, bullet lists, numbered lists, links, images, linked images (`[![alt](img)](url)`), horizontal rules
   - Strip: `[Image: Image]` placeholders, duplicate blank lines, trailing whitespace
   - Keep image URLs as-is initially (they'll be downloaded next)
   - **Use `<img>` tags instead of markdown image syntax** for all images. This allows preserving the `width` attribute. After downloading an image (step 5), read its actual pixel width and set `width` on the tag (do NOT set `height` — omitting it lets the browser scale proportionally). The user can then adjust the width to match the MakerWorld layout. Example:
     ```html
     <img src="https://raw.githubusercontent.com/.../logo.webp" alt="Logo" width="800">
     ```
     For linked images, wrap the `<img>` in an `<a>` tag:
     ```html
     <a href="https://target-url"><img src="https://raw.githubusercontent.com/.../image.webp" alt="Alt" width="400"></a>
     ```
   - **Alignment is lost during extraction**: `fetch_webpage` strips `style` attributes, so centered text/headings from MakerWorld come through as plain markdown. This is a known limitation. After extraction, add a note at the bottom of the DESCRIPTION.md:
     ```markdown
     <!-- TODO: Review alignment — fetch_webpage strips style attributes. Compare with MakerWorld page and wrap centered elements in HTML blocks. -->
     ```
     When fixing alignment, use:
     - `<h2 style="text-align: center">Title</h2>` for centered headings
     - `<p style="text-align: center">...</p>` for centered paragraphs, images, or links
     - This renders correctly on GitHub (HTML passthrough) and in `md-to-mw.py`
   - **Detect orphan linked images**: `fetch_webpage` drops `<img>` elements inside `<a>` tags, producing empty links like `[](https://...)`. Collect all such `[](url)` patterns — these are linked images whose `src` was lost. See step 5a for resolution
   - **Be aware of invisible drops**: `fetch_webpage` silently drops `<iframe>` embeds (YouTube videos, etc.) with no trace at all — just blank whitespace. See step 5b for resolution

5. **Download images**:
   - Identify all image URLs in the description (from `makerworld.bblmw.com` CDN or other sources)
   - Skip external reference images (e.g. `encrypted-tbn0.gstatic.com` meme images) — keep those as URLs
   - Download MakerWorld CDN images to the **assets repo**: `assets/<target-repo>/models/<name>/makerworld/images/`
   - Use descriptive filenames based on context (e.g. `diagonal_supports.png`, `showcase_rack.jpg`)
   - After downloading, read the actual pixel width of each image and use `<img>` tags with `width` set to the image's native width (omit `height` for proper scaling)
   - Reference images using absolute URLs in `<img>` tags: `<img src="https://raw.githubusercontent.com/kellerlabs/assets/main/<target-repo>/models/<name>/makerworld/images/filename.png" alt="Description" width="W">`

5a. **Resolve orphan linked images** (from step 4):
   - For each `[](url)` pattern found, present the user with a numbered list showing the link target URL
   - Ask the user to open the MakerWorld page in a browser and identify what image is displayed for each link (e.g. a logo, a model thumbnail, a collection banner)
   - The user should provide the image URL (right-click → "Copy image address") or a description
   - Once URLs are obtained: download to `assets/<target-repo>/models/<name>/makerworld/images/`, replace the empty link with a proper linked image using absolute URL: `[![alt text](https://raw.githubusercontent.com/kellerlabs/assets/main/<target-repo>/models/<name>/makerworld/images/filename.png)](url)`
   - If the user cannot provide the URL, insert a TODO comment in the markdown: `<!-- TODO: linked image missing for url -->`

5b. **Resolve missing embeds** (from step 4):
   - Ask the user: "Are there any embedded videos (YouTube, etc.) on the MakerWorld description page that should be included?"
   - If yes, ask for the YouTube video URL(s) and where they appear in the description
   - Insert a markdown-compatible YouTube link in the appropriate location. Use a linked thumbnail image:
     ```markdown
     [![Video Title](https://img.youtube.com/vi/<VIDEO_ID>/maxresdefault.jpg)](https://www.youtube.com/watch?v=<VIDEO_ID>)
     ```
   - `md-to-mw.py` automatically converts these to CKEditor `<figure class="media">` embeds during publish

6. **Add YAML frontmatter** to the top of `DESCRIPTION.md`:
   ```yaml
   ---
   makerworld_url: https://makerworld.com/en/models/<id>-<slug>
   extracted: YYYY-MM-DD
   ---
   ```

7. **Save** the file to the target path.

8. **Verify** by reading back the file and checking:
   - Frontmatter is valid YAML
   - All images have been downloaded
   - No `[Image: Image]` placeholders remain
   - No orphan `[](url)` empty links remain (all resolved or marked with TODO)
   - Embedded videos are accounted for (user confirmed none missing, or added)
   - Markdown renders with proper heading hierarchy

## 📤 Publish Flow

Convert a `DESCRIPTION.md` file to HTML for pasting into MakerWorld.

### Steps

1. Direct the user to run the conversion script:
   ```bash
   python cmd/export/md-to-mw.py models/<name>/makerworld/DESCRIPTION.md
   ```
2. This generates `DESCRIPTION.html` in the same directory (gitignored).
3. Instruct the user to open the HTML file in a browser, select all (`Ctrl+A`), copy (`Ctrl+C`), then paste into MakerWorld's description editor.

## 📁 File Convention

```
models/<name>/makerworld/
├── <name>.scad                    # MakerWorld parametric source
├── DESCRIPTION.md                 # Model description (source of truth)
├── DESCRIPTION.html               # Generated HTML (gitignored)
├── renders/                       # Auto-generated render previews
│   ├── <name>_mw_assembly_view.png
│   └── <name>_mw_plate_1.png
```

Images are stored in the **assets repo** (`kellerlabs/assets`):
```
assets/<repo>/models/<name>/makerworld/images/
├── showcase.jpg
└── diagonal_supports.png
```

## ⚠️ Important Notes

- **Cross-repo skill**: Requires both the source repo (`homeracker` or `homeracker-exclusive`) and the [`kellerlabs/assets`](https://github.com/kellerlabs/assets) repo. Maintainers push images directly to `assets/main`. Outside collaborators must open a PR on the assets repo for image changes.
- `DESCRIPTION.md` is the **source of truth**. Always edit it in git, never in MakerWorld directly.
- After editing `DESCRIPTION.md`, re-run `md-to-mw.py` and re-paste into MakerWorld.
- The conversion script embeds local images as base64 data URIs so the HTML is fully self-contained — no broken links, no browser permissions needed. External image URLs (http/https) are passed through unchanged.
- Since images are now hosted in the `kellerlabs/assets` repo with absolute URLs, `md-to-mw.py` passes them through directly — no base64 encoding needed for assets-hosted images.
- **Alignment**: Use inline HTML blocks (`<h2 style="text-align: center">`, `<p style="text-align: center">`) to preserve centered headings, images, and text from MakerWorld. These render correctly on GitHub and pass through to `md-to-mw.py` HTML output.
- **Image sizing**: `fetch_webpage` strips HTML attributes, so image dimensions are not available from the source page. Use `<img>` tags with `width` set to the actual downloaded image width (omit `height` so images scale proportionally). The user can then adjust the width to match the MakerWorld layout.
- MakerWorld CDN images (from `makerworld.bblmw.com`) should be downloaded to the assets repo during extraction. External reference images (memes, badges, etc.) can stay as external URLs.

## 🐛 Known Limitations

### `fetch_webpage` drops linked images

`fetch_webpage` converts HTML to markdown but loses `<img>` elements nested inside `<a>` tags. This produces empty links like `[](https://some-url)` where a linked image (`<a href="..."><img src="..."></a>`) existed in the original HTML.

**Common patterns affected**:
- Logo/banner images linking to external sites (e.g. HomeRacker logo → homeracker.org)
- Model thumbnail images linking to other MakerWorld models
- Collection banner images linking to MakerWorld collections

**Workaround**: Step 5a in the Extract Flow asks the user to manually supply the missing image URLs by inspecting the page in a browser.

### `fetch_webpage` silently drops embedded iframes

`fetch_webpage` completely discards `<iframe>` elements (YouTube embeds, etc.) with **no trace** — no placeholder, no URL, just blank whitespace. Unlike linked images which leave a detectable `[](url)` pattern, embedded videos are entirely invisible in the output.

**Common patterns affected**:
- YouTube video embeds in description sections
- Any other `<iframe>`-based content

**Workaround**: Step 5b in the Extract Flow explicitly asks the user whether embedded videos exist on the page. Videos are stored as linked YouTube thumbnails in `DESCRIPTION.md`. During publish, `md-to-mw.py` automatically converts these to CKEditor 5 `<figure class="media">` embeds with `data-oembed-url`, which MakerWorld's editor recognises as native video embeds.
