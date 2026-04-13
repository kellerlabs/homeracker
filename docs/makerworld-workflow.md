# 🌐 MakerWorld Description Workflow

## 📌 What

How to manage MakerWorld model descriptions as git-tracked `DESCRIPTION.md` files and publish them to MakerWorld.

## 🔧 Workflow

### Extract (MakerWorld → Git)

Use the `@makerworld-description` Copilot skill to extract a description from a MakerWorld model page:

1. Provide the MakerWorld model URL
2. The skill scrapes the page, downloads images to the **assets repo**, and creates `DESCRIPTION.md`
3. Commit the `DESCRIPTION.md` to the source repo and images to `kellerlabs/assets`

### Publish (Git → MakerWorld)

```bash
python cmd/export/md-to-mw.py models/<name>/makerworld/DESCRIPTION.md
```

This generates `DESCRIPTION.html` (gitignored). Open it in a browser, `Ctrl+A`, `Ctrl+C`, paste into MakerWorld's description editor.

### Edit

1. Edit `DESCRIPTION.md` directly in the source repo
2. Re-run `md-to-mw.py` to regenerate HTML
3. Re-paste into MakerWorld

## 📁 Image Hosting

Images are stored in **[kellerlabs/assets](https://github.com/kellerlabs/assets)**, not in the source repos.

```
https://raw.githubusercontent.com/kellerlabs/assets/main/<repo>/models/<name>/makerworld/images/<file>
```

`md-to-mw.py` passes absolute URLs through unchanged. Base64 embedding only applies to local relative paths.

## 📚 References

- [ADR-001](../decisions/ADR-001-image-hosting-assets-repo.md) — why images live in a separate repo
- `.github/skills/makerworld-description/SKILL.md` — Copilot skill for extraction
- `cmd/export/md-to-mw.py` — conversion script
