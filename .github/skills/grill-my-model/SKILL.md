---
name: grill-my-model
description: >
  Relentlessly interview the creator of a HomeRacker OpenSCAD model about every
  design decision, then fold the answers into the model's documentation. Use this
  skill during planning of a new model, or after a model (or a change to one) is
  built, to pressure-test the design and produce the most comprehensive yet concise
  docs possible.
  USE FOR: grilling a model's parameters/defaults/geometry/print choices, filling
  gaps a newbie couldn't understand, improving model README / configuration &
  printing guides / MakerWorld descriptions, rendering missing parameter-config
  images, and creating or updating a model's decision record (ADR).
  DO NOT USE FOR: writing the OpenSCAD geometry itself (use the @makerworld-model
  agent), extracting MakerWorld descriptions from the web (use the
  makerworld-description skill), or routine version/config/dependency changes.
---

# 🔥 Grill My Model — homeracker Skill

## 📌 What

A relentless interview that walks every branch of a model's design tree and
challenges **each design decision** until a newbie could understand *why* the model
is the way it is. The resolved answers are then folded back into the model's
documentation (README, configuration/printing guide, MakerWorld description) and,
where warranted, a decision record (ADR).

The goal is not to be nice. The goal is the **most comprehensive yet concise
documentation possible**. Ask 10 questions or 100 — whatever it takes to leave no
unexplained decision behind.

## 🤔 Why

Models accrete parameters, magic defaults, and geometry tricks whose rationale lives
only in the author's head. New users (and future AI agents) then can't tell which
knob to turn or why a default is what it is. Grilling surfaces that hidden rationale
while it's still recoverable and captures it where people will actually read it.

This skill is the OpenSCAD-model translation of the popular "grill my plan" pattern
(e.g. [mattpocock/skills `grilling`](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md)):
a one-question-at-a-time, recommend-an-answer, explore-before-asking loop.

---

## 1. When to Use

| Situation | What the grill produces |
|---|---|
| **Planning** a new model | A clear design brief: justified parameters, defaults, scope, print plan — captured in a fresh README + ADR before code exists |
| **After building** a model or changing one | Gap-filled README, configuration/printing guide, MakerWorld description, refreshed config images, updated/created ADR |

It works the same way in both cases: gather context, grill, then act on docs.

---

## 2. Gather Context First (do not ask what you can read)

Before asking anything, read everything that already exists for the model:

1. The model source: `models/<name>/**/*.scad` (and any `lib/` it `use`s/`include`s).
   Enumerate **every** parameter (Customizer vars, module args), default, and
   `/* [Section] */` grouping.
2. Existing docs: `models/<name>/README.md`, any configuration/printing guide,
   `models/<name>/makerworld/DESCRIPTION.md` (if published), and `parts/renders/*.png`.
3. Existing ADRs: scan `docs/decisions/` for an entry about this model.
4. Repo conventions: `README.md` (HomeRacker standards: 15 mm base unit, 4 mm lock
   pins, 2 mm walls, 0.2 mm tolerance) and the markdown instructions.

> **Rule (from the source pattern):** if a question can be answered by exploring the
> codebase, explore the codebase instead of asking. Only ask the human what the code
> cannot tell you — intent, trade-offs, target user, and the "why".

Build a checklist of every decision you found. That checklist is your grill agenda.

---

## 3. The Grilling Loop

Run the interview **one question at a time**. Asking several at once is bewildering.

For each question:

1. State the decision under scrutiny and **why it matters**.
2. Give your **recommended answer** with reasoning (so the user can just confirm).
3. Wait for the answer before moving on.
4. Resolve dependencies first: if decision B depends on A, settle A first.
5. When an answer reveals a new branch, push onto the agenda and keep going.

Stay relentless but constructive. Keep each question tight — no walls of text.

---

## 4. What to Grill — Question Catalog

Walk these lenses for the model as a whole **and for every single parameter**. Skip
only what context already answers conclusively.

### 4.1 Every parameter (ask for each one)

- **Existence:** Why does this parameter exist at all? Which concrete user use case
  does it solve? What breaks if we delete it (YAGNI check)?
- **Value to the user:** Does a real user ever change this, or is it an internal
  constant masquerading as a parameter? Should it be hidden / promoted / removed?
- **Default:** Why *this* default and not another? Is it the most common real-world
  case? Does it satisfy HomeRacker standards out of the box?
- **Range & step:** Are the Customizer `[min:step:max]` / enum choices justified?
  What happens at the extremes — does it still print and fit?
- **Name:** Does the name spell out intent for a newbie? (See naming conventions in
  the OpenSCAD instructions — descriptive over abbreviated.)
- **Interactions:** Which other parameters does it couple with? Any invalid
  combinations that need an `assert` or a doc warning?
- **Units & frame:** mm? degrees? Which axis/anchor? Is that obvious from the name/doc?

### 4.2 The model as a whole

- **Problem:** What problem does this model solve, in one sentence a newbie gets?
- **Scope:** What is explicitly *out* of scope, and why?
- **Geometry & build method:** Why this construction approach (e.g. BOSL2 vs native,
  diff vs union, attach vs translate)? What were the alternatives and why rejected?
- **Dimensions:** Why these sizes? Which derive from HomeRacker standards vs the
  target object (jack, drive, panel, etc.)? Cite the source of any magic number.
- **Tolerances & fit:** Where is clearance applied and why that much? Print-tested?
- **Print orientation & supports:** How is it meant to be printed? Why that
  orientation? Any multi-part / assembly considerations?
- **Compatibility:** How does it mate with the rest of the HomeRacker system?

---

## 5. Act on the Documentation

Only **after** the relevant branch is resolved, update docs. Act on **existing** docs;
create only the crucial README if it is missing.

### 5.1 Which docs

| Doc | Action |
|---|---|
| `models/<name>/README.md` | **Create if missing** (crucial). Otherwise update in place. Follow the Model README template in the markdown instructions (What / Why / How / 📸 Catalog / References). |
| Configuration / printing guide | Update **only if it already exists**. Fold in the justified parameters, valid ranges, and print plan. |
| `models/<name>/makerworld/DESCRIPTION.md` | Update **only if it already exists**. Reflect resolved rationale and any new config images. |
| `models/README.md` (index) | Update the model's row if its description/preview changed. |

> Do not invent new doc files beyond the crucial README. Improve what exists; link
> to the single source of truth rather than duplicating.

### 5.2 Missing parameter-config images

If a parameter configuration that matters for understanding has **no** illustrating
render:

1. **Ask the user** whether to render it (and at which parameter values).
2. On confirmation, render with `scadm export-png` — full F6 renders, `BeforeDawn`
   colorscheme (the intentional default). Use a preset or `-D var=val` overrides:
   - `scadm export-png models/<name>/parts/<part>.scad -D 'param=value' --output models/<name>/parts/renders/<name>_<variant>.png`
   - or with a preset: `scadm export-png <file> -p <presets.json> -P <preset>`
3. Add the new image to the README 📸 Catalog and, if used there, the MakerWorld
   description. Manually-authored images go to the `kellerlabs/assets` repo;
   auto-generated renders stay in `parts/renders/`.

### 5.3 Writing quality

- Be **brief** — bullet points over prose, < ~100 lines where possible.
- Add the *context the code cannot convey*; never restate what the code already says.
- Use HomeRacker emoji section headers and cross-link from the parent index.

---

## 6. Decision Record (ADR) Rules

A model carries **one** decision record capturing its core design rationale. Apply:

| Situation | Action |
|---|---|
| **No ADR exists** for this model | Build one **from the ground up** in `docs/decisions/<model>.md` capturing the grilled rationale (problem, key parameters/defaults, geometry & build method, alternatives rejected, consequences). Load the `decision-records` skill for the exact template and index update. |
| **ADR exists but has gaps** | **Adapt** the existing ADR — fill the missing context the grill surfaced. Do not create a second record. |
| **Behavior changed significantly** (geometry or build method materially different) | Create a **new** ADR that supersedes the old one (per the supersede flow in the `decision-records` skill). |

> A single ADR per model is enough unless geometry or building methods change
> significantly. Routine parameter tweaks update the README/guide, not a new ADR.

---

## 7. Completion Criteria

The grill is done when:

- Every parameter has a justified existence, default, and range — or was removed.
- A newbie could read the README and understand *why*, not just *how*.
- Configuration/printing guide and MakerWorld description (where they exist) reflect
  the resolved rationale and any new config images.
- The model's ADR exists and is current per §6.
- The parent `models/README.md` index is consistent.

---

## 📚 References

- [`grill-my-plan` skill](../grill-my-plan/SKILL.md) — the plan-shaped sibling (use it to stress-test a plan before code exists)
- [`decision-records` skill](../decision-records/SKILL.md) — ADR template, index, supersede flow
- [`makerworld-description` skill](../makerworld-description/SKILL.md) — MakerWorld `DESCRIPTION.md` handling
- [Markdown guidelines](../../instructions/markdown.instructions.md) — Model README template, Catalog rules
- [OpenSCAD guidelines](../../instructions/openscad.instructions.md) — naming, geometry conventions
- [mattpocock/skills `grilling`](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md) — the upstream "grill my plan" pattern this adapts
