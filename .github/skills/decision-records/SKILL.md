---
name: decision-records
description: >
  Create, update, or manage decision records in homeracker.
  Use this skill when comparing alternative solutions and choosing one, changing
  behavior of CLI tools or build processes or model conventions, making trade-offs
  that future contributors need to understand, or superseding a previous decision.
  USE FOR: creating new decision records, looking up existing decisions, superseding
  outdated decisions, documenting rationale behind tooling or architecture choices.
  DO NOT USE FOR: routine config changes, version bumps, dependency updates, or
  changes that are self-explanatory from the code or commit message.
---

# 📋 Decision Records — homeracker Skill

This skill guides the creation and management of lightweight decision records that capture
the **why** behind architecture, tooling, and workflow decisions.

Decision records help contributors and AI agents understand the original intent behind
choices, especially when the reasoning isn't obvious from the code alone.

---

## 1. Determine the Action

| Request | Action |
|---|---|
| "Record/document this decision" | → §3 (Create a new decision) |
| "What was decided about X?" | → §2 (Look up existing decisions) |
| "Supersede/update decision about X" | → §4 (Supersede a decision) |
| "List all decisions" | → Read `docs/decisions/README.md` |

---

## 2. Look Up Existing Decisions

Before creating a new decision, **always check** if one already exists:

1. Read `docs/decisions/README.md` for the active decisions table.
2. If a related decision exists, determine whether to **supersede** it (§4) or reference it.

---

## 3. Create a New Decision

### 3.1 File Location & Naming

- **Location:** `docs/decisions/`
- **Naming:** `kebab-case-title.md` — name after the component/topic and action.
  - ✅ `image-hosting-assets-repo.md`
  - ✅ `unify-export-png-into-scadm.md`
  - ❌ `ADR-001-image-hosting.md` (no numeric prefixes)
- The title should use a present-tense imperative verb phrase describing the decision.

### 3.2 Template

Use this exact structure:

```markdown
# 📋 Title (present-tense imperative verb phrase)

## 📌 Status

**Accepted** — YYYY-MM-DD

## 🤔 Context

What problem or situation triggered this decision? What constraints exist?
If this supersedes a previous decision, link the predecessor commit here.

## 🔧 Decision

What did we decide and why? Include alternatives considered and why they were rejected.

## 📊 Consequences

What follows from this decision? Include both positive and negative effects.
```

### 3.3 Writing Quality Criteria

- **Context** must explain the problem clearly enough that someone unfamiliar can understand it.
- **Decision** must state the choice explicitly and include alternatives considered with brief reasons for rejection.
- **Consequences** must include both positive and negative effects — every decision has trade-offs.
- Keep it concise. Prefer bullet points over prose. Link to code, PRs, or other docs rather than duplicating content.
- Use the homeracker emoji conventions (📋 title, 📌 Status, 🤔 Context, 🔧 Decision, 📊 Consequences).

### 3.4 After Creating the Decision

1. **Update the decisions index:** Add a row to `docs/decisions/README.md` (keep sorted by date descending).
2. **Cross-link from related docs:** Reference the decision from READMEs, instructions, or other decisions where viable.

---

## 4. Supersede a Decision

When a previous decision is being replaced:

1. Create a new decision record (§3) explaining the new choice.
2. In the new record's **Context**, link to the last commit containing the old decision so readers can find it in history.
   Format: `Supersedes [old-decision.md](https://github.com/kellerlabs/homeracker/blob/<commit-sha>/docs/decisions/old-decision.md)`
3. **Delete the old decision file** — it remains available in git history.
4. Update `docs/decisions/README.md` to remove the old entry and add the new one.

---

## 5. When NOT to Write a Decision

Skip decision records for:

- Routine config changes, version bumps, or dependency updates
- Changes that are self-explanatory from the code or commit message
- Temporary workarounds (use code comments instead)
- Single-option situations where there was nothing to decide

---

## 6. Reference Example

See [docs/decisions/image-hosting-assets-repo.md](../../../docs/decisions/image-hosting-assets-repo.md) for a well-structured example covering context, alternatives considered, and positive/negative consequences.

---

## 7. Humanize the Prose

After writing or editing a decision record, run the [`humanizer`](../humanizer/SKILL.md) skill over it to strip AI tells. ADRs are reference text, so use its neutral register (no first person or injected opinions), just plain, concrete prose.
