# 🌐 MakerWorld Description Workflow

## 📌 What

How to manage MakerWorld model descriptions as git-tracked `DESCRIPTION.md` files and publish them to MakerWorld.

## 🤔 Why

- ✅ Keep MakerWorld descriptions versioned, reviewable, and easy to update alongside model changes
- 🖼️ Store images in the shared assets repo so source repos stay lean and links remain stable
- 🔁 Use one Markdown source that can be edited in Git and republished to MakerWorld as HTML

## 🔧 How

### Extract (MakerWorld → Git)

Use the `@makerworld-description` Copilot skill to extract a description from a MakerWorld model page:

1. Provide the MakerWorld model URL
2. The skill scrapes the page, downloads images to the **assets repo**, and creates `DESCRIPTION.md`
3. Commit the `DESCRIPTION.md` to the source repo and images to `kellerlabs/assets`

### Publish (Git → MakerWorld)

```bash
pip install -r requirements.txt
python cmd/export/md-to-mw.py models/<name>/makerworld/DESCRIPTION.md
```

This generates `DESCRIPTION.html` (gitignored). Open it in a browser, `Ctrl+A`, `Ctrl+C`, paste into MakerWorld's description editor.

### Edit

1. Edit `DESCRIPTION.md` directly in the source repo
2. Re-run `md-to-mw.py` to regenerate HTML
3. Re-paste into MakerWorld

## 📁 Image & Layout Formatting

> ⚠️ **Cross-repo workflow**: This skill requires both the source repo and [`kellerlabs/assets`](https://github.com/kellerlabs/assets). Maintainers push images directly to `assets/main`. Outside collaborators must open a PR on the assets repo for image changes.

Images are stored in **[kellerlabs/assets](https://github.com/kellerlabs/assets)**, not in the source repos.

```
https://raw.githubusercontent.com/kellerlabs/assets/main/<repo>/models/<name>/makerworld/images/<file>
```

- Use `<img>` tags with `width` (no `height`) so images scale proportionally
- Use `<h2 style="text-align: center">` and `<p style="text-align: center">` for centered elements
- These HTML blocks render correctly on GitHub and pass through to `md-to-mw.py`

`md-to-mw.py` passes absolute URLs through unchanged. Base64 embedding only applies to local relative paths.

### Create (New Description)

Use the `@makerworld-description` Copilot agent to create a new `DESCRIPTION.md` from scratch:

1. Invoke: `@makerworld-description foot homeracker-exclusive`
2. The agent interviews you for model details, verifies images in the assets repo, creates `DESCRIPTION.md`, enhances `CUSTOMIZATION.md` with images, and opens a PR
3. Optionally publish with `md-to-mw.py` (see above)

## 📚 References

- [ADR-001](decisions/ADR-001-image-hosting-assets-repo.md) — why images live in a separate repo
- `.github/agents/makerworld-description.agent.md` — Copilot agent for creating new descriptions
- `.github/skills/makerworld-description/SKILL.md` — Copilot skill for extracting existing descriptions
- `cmd/export/md-to-mw.py` — conversion script
