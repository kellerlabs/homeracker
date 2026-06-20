---
name: grill-my-plan
description: >
  Relentlessly interview the user about a plan or proposal — release plans,
  refactors, model rollouts, architectural changes — until every branch of the
  decision tree is resolved. Then fold the resolved plan into the right artifact:
  a decision record, a release roadmap, a PR description, or a tracking issue.
  USE FOR: stress-testing a plan before execution, pressure-testing scope and
  trade-offs, surfacing hidden assumptions, drafting MakerWorld/release rollouts,
  shaping a refactor or migration before code is touched, producing the artifact
  the plan needs.
  DO NOT USE FOR: grilling a built model's parameters and geometry (use
  grill-my-model), writing OpenSCAD code (use the @makerworld-model agent),
  routine config/version/dependency bumps.
---

# 🔥 Grill My Plan — homeracker Skill

## 📌 What

A relentless interview that walks every branch of a *plan's* decision tree — one
question at a time — and challenges every choice (scope, sequencing, trade-offs,
risk, definition of done) until the plan is shared and stress-tested. The
resolved answers are then folded into the artifact the plan actually needs.

The goal is not to be nice. The goal is the **clearest, shortest defensible
plan** — and the artifact that captures it (ADR, release roadmap, PR description,
or tracking issue), nothing more.

## 🤔 Why

Plans accrete vague goals, optimistic scopes, and hidden assumptions that only
hurt at execution time. Grilling surfaces those decisions while they are still
cheap to change and captures the rationale where future contributors (and AI
agents) will actually read it.

This skill is the **plan-shaped sibling** of [`grill-my-model`](../grill-my-model/SKILL.md)
(which grills built OpenSCAD models). Both adopt the same one-question-at-a-time
loop from the upstream
[mattpocock/skills `grilling`](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md);
they differ in **what they walk** (parameters vs. plan branches) and **what
they produce** (model docs vs. plan artifact).

---

## 1. When to Use

| Situation | What the grill produces |
|---|---|
| **Release rollout** (e.g. shipping a model family to MakerWorld) | A release roadmap: scope per release, ordering, prerequisites, acceptance — captured as a decision record or release plan doc |
| **Architectural / tooling change** | A decision record (ADR) with the resolved trade-off and rejected alternatives |
| **Refactor or migration** | A PR description scaffold listing scope, non-goals, sequencing, verification |
| **New feature with unclear scope** | A tracking issue with crisp acceptance criteria and a phased plan |

It works the same in every case: gather context, grill, then act on the right artifact.

---

## 2. Gather Context First (do not ask what you can read)

Before asking anything, read what already exists:

1. Any draft, sketch, or thread the user pointed at.
2. Code, models, and docs the plan touches — enumerate the surface area concretely.
3. Existing ADRs in `docs/decisions/` for prior decisions in this area.
4. Repo conventions: HomeRacker standards (15 mm base unit, 4 mm lock pins, 2 mm
   walls, 0.2 mm tolerance), markdown instructions, and the relevant model READMEs.

> **Rule (from the source pattern):** if a question can be answered by exploring
> the codebase, explore the codebase instead. Only ask the human what the code
> cannot tell you or where it is ambiguous — intent, trade-offs, priorities, and the "why".

Build a checklist of every decision the plan implies. That checklist is your grill agenda.

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

## 4. What to Grill — Plan Question Catalog

Walk these lenses for the plan as a whole **and for every distinct deliverable
inside it**. Skip only what context already answers conclusively.

### 4.1 Goal & scope

- **Problem:** What concrete problem does this plan solve? Whose problem is it?
- **Definition of done:** What does "shipped" look like? What is the user-visible
  outcome that lets us close it?
- **Out of scope:** What is explicitly *not* in this plan, and why? (YAGNI check.)
- **Why now:** What changed to make this worth doing now over later?

### 4.2 Every deliverable (ask for each one)

- **Existence:** Why does this deliverable exist in the plan? Which goal does it
  serve? What breaks if we drop it?
- **Sequencing:** What must land before this? What can ride along vs. follow up?
- **Size:** Is it one PR, one release, or a series? Is it splittable into
  independently-shippable slices?
- **Acceptance:** How will *we* know this deliverable is done — concretely?
- **Risk & rollback:** What's the worst plausible failure mode? Can we revert?

### 4.3 Trade-offs & alternatives

- **Alternatives:** Which approaches were considered and rejected? Why?
- **Cost:** What does this plan cost in time, complexity, or future maintenance?
- **Reversibility:** Which decisions are one-way doors vs. easily revisited later?
- **Dependencies you don't own:** Upstream releases, external services, user
  action — what's the worst that happens if they stall?

### 4.4 Audience & rollout

- **Who consumes it:** Users? Other contributors? MakerWorld visitors?
- **How they learn about it:** README diff, MakerWorld description, changelog,
  release notes — which channels actually reach the audience?
- **Migration story:** What do existing users need to do? Breaking change or
  drop-in upgrade?

---

## 5. Act on the Plan — Pick the Right Artifact

Only **after** the relevant branch is resolved, write the plan into the artifact
that fits. Pick **one primary** artifact; cross-link the others.

| Plan shape | Primary artifact | Where it lives |
|---|---|---|
| Architectural / tooling / convention decision | Decision record (ADR) | `docs/decisions/<kebab-title>.md` — load the [`decision-records`](../decision-records/SKILL.md) skill |
| Multi-step release rollout (e.g. MakerWorld family) | Release plan doc or ADR | `docs/<topic>/release-plan.md` if multi-release; ADR if it's mainly the decision |
| Single PR-sized change | PR description scaffold | The PR body; follow `.github/pull_request_template.md` (What / Why / How) |
| Multi-step feature without a single owner | Tracking issue | A GitHub issue with checklist; one sub-issue per deliverable |

### 5.1 Writing quality

- Be **brief** — bullet points over prose, < ~100 lines where possible.
- Capture the *why*, the *non-goals*, and the *alternatives rejected* — never
  restate what code or commits already say.
- Use HomeRacker emoji headers (📦 What · 💡 Why · 🔧 How · ⚠ Risk · 📊 Trade-offs).
- Cross-link from related docs (ADR ↔ README ↔ issue ↔ PR).

### 5.2 Don't invent docs

Do not spawn new top-level doc files when an ADR, PR body, or issue already fits.
Improve what exists; link rather than duplicate.

---

## 6. Decision Record (ADR) Rules

When the artifact *is* an ADR, follow the [`decision-records`](../decision-records/SKILL.md)
skill verbatim for template, naming, index update, and supersede flow.

A plan grill may surface that an **existing** ADR is outdated. In that case,
prefer **superseding** the old ADR (per the decision-records skill) over editing
it in place — git history then carries the why-it-changed.

---

## 7. Completion Criteria

The grill is done when:

- Every deliverable has a justified existence, acceptance criterion, and place
  in the sequence — or was dropped from scope.
- Trade-offs and rejected alternatives are recorded.
- The chosen artifact (ADR / release plan / PR body / issue) is written and
  cross-linked from related docs.
- A newbie could read the artifact and predict what will ship, in what order, and why.

---

## 📚 References

- [`grill-my-model` skill](../grill-my-model/SKILL.md) — the model-shaped sibling (use it for built OpenSCAD models, not plans)
- [`decision-records` skill](../decision-records/SKILL.md) — ADR template, index, supersede flow
- [Markdown guidelines](../../instructions/markdown.instructions.md) — emoji headers, structure
- [Pull request template](../../pull_request_template.md) — What / Why / How sections for PR-shaped artifacts
- [mattpocock/skills `grilling`](https://github.com/mattpocock/skills/blob/main/skills/productivity/grilling/SKILL.md) — the upstream "grill my plan" pattern this adapts
