---
name: humanizer
description: >
  Remove signs of AI-generated writing from any text so it reads as natural,
  human-written prose in the author's voice. Detects and fixes inflated
  significance, promotional language, -ing padding, vague attributions, em-dash
  overuse, rule-of-three, AI vocabulary, copula avoidance, passive voice,
  negative parallelisms, emoji/boldface decoration, and filler.
  USE FOR: humanizing MakerWorld descriptions, social posts, READMEs, changelogs,
  release notes, decision records, PR/issue text — any prose a skill or the user
  just generated or edited. Other text-creating skills reference this one as a
  recommended final pass.
  DO NOT USE FOR: OpenSCAD geometry, code logic, or data files; the keep-list in
  §Detection protects legitimate human prose from over-editing.
---

# ✍️ Humanizer — homeracker Skill

## 📌 What

Rewrites already-drafted text to strip the statistical "tells" of LLM writing
while keeping every fact, link, and the author's intended voice. It is an editing
pass, not a content generator: same meaning, same length, same structure — just
without the slop.

Adapted for HomeRacker (VS Code + Copilot) from
[blader/humanizer](https://github.com/blader/humanizer/blob/main/SKILL.md), which
distills [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing).

## 🤔 Why

- **Our text is public-facing.** MakerWorld descriptions and social posts are read
  by makers who can smell AI copy instantly. Slop erodes trust; the author's real
  voice builds it.
- **One pass, applied everywhere.** Centralising the rules means every text skill
  produces consistent, human-sounding output without re-explaining the patterns.

## 🧭 How to Use

1. **Get the target text.** Either the user names a file (read it) or pastes text
   inline. If a text-creating skill just wrote a file, run this pass on that file.
2. **Match the voice** in [§ Voice Calibration](#-voice-calibration) (the author's
   baked-in sample). If the user supplies a different sample for this run, prefer it.
3. **Draft → audit → final** ([§ Process](#-process)). Rewrite, then scan for any
   remaining tells (em dashes especially), then deliver the final.
4. **Write it back.** For a file, replace its contents with the humanized version.
   For inline text, return the final rewrite. Keep front-matter, links, image
   tags, and code blocks intact.

> **Register matters.** Blog/social/opinion text gets voice and personality.
> Reference text (READMEs, ADRs, changelogs) stays plain and neutral — neutral *is*
> the human voice there. Do not inject opinions or first person into reference docs.

---

## 🎙️ Voice Calibration

When rewriting **the author's own voice** (social posts, MakerWorld descriptions,
video-style copy), match the sample below. Don't just remove AI patterns, replace
them with this rhythm, word choice, and habits. If the user provides a fresher
sample for a given run, that overrides this default.

The author is **Patrick** (KellerLab / HomeRacker). Sample drawn from his YouTube
narration (stage directions stripped):

```text
Hi, my name is Patrick! Welcome to KellerLab, the channel where I present the
latest developments in my homelab journey. And the one I am gonna show you today
turned out great, even though it was also hugely time-consuming to develop. But
let's not get ahead of ourselves.

I know... Let's KISS and YAGNI and all that, but my overthinking, caffeine-fueled
brain couldn't help itself. I needed a truly modular solution. Something that
wouldn't just fit Raspberry Pis now, but could also grow with me: switches, 10"
gear, maybe even full-blown 19" devices down the road. And maybe also... just stuff.

These few ingredients give you the freedom to basically scale racks infinitely and
create whatever it is you want to "rack"... at least to the point where a rack
collapses under its own weight and might turn into a black hole. Physics, yeay.

TL;DR: the biggest strength is also its biggest challenge, versatility. If you're
looking for a plug-and-play rack, this might feel overwhelming. But if you love
customizing and want something exactly right for your setup, HomeRacker delivers.
It's also pretty bulky compared to specialized solutions. Frugality is not one of
its virtues.

So there you have it... HomeRacker! A fully modular universal rack building system
where only the sky's the limit. Or printing dimensions, load bearing, complexity,
cost. Man, who approved this script?
```

### Voice notes (what makes it his)

- **First person, talking straight to the viewer** ("trust me", "stick around",
  "just sayin..."). Never corporate, never third-person.
- **Casual and nerdy**: pop-culture refs, coffee jokes, mock-grandiose buildups he
  then undercuts ("A rack that looks like it already survived a nuclear explosion").
- **Self-deprecating and self-correcting mid-thought** ("...and that came out wrong,
  moving on", "who approved this script?").
- **Mixed rhythm**: a long flowing sentence, then a short punchline or fragment.
- **Honest about trade-offs** — he names the downsides plainly instead of selling.
- **Tics**: "Holy cow", "let's be real", "moving on", trailing "..." pauses, ironic
  air-quotes, dry metric/European humor.
- **Punctuation**: the em dashes in his source script are LLM residue, not his voice,
  so cut them freely per §14 (comma, period, or parentheses). The trailing ellipses
  (`...`) are genuinely his, so keep those, sparingly.

How to read any sample before rewriting:

- Sentence length pattern (short and punchy? long and flowing? mixed?)
- Word-choice level (casual? technical? in-between?)
- Paragraph openings (jump in, or set context first?)
- Punctuation habits and any recurring phrases or verbal tics
- How transitions are handled (explicit connectors, or just the next point?)

---

## 🧱 The Patterns (detect → fix)

Scan for these. Each is a reliable AI tell; rewrite, never just delete.

### Content
1. **Inflated significance / legacy** — "stands as a testament", "marks a pivotal
   moment", "reflects broader", "setting the stage for". State the fact plainly.
2. **Notability padding** — listing outlets/follower counts to assert importance.
   Give one specific, sourced fact instead.
3. **Superficial -ing analyses** — "…, highlighting/symbolizing/ensuring…" tacked
   on for fake depth. Cut the participle or make it a real clause.
4. **Promotional language** — "boasts", "vibrant", "nestled", "in the heart of",
   "breathtaking", "must-visit". Neutral, concrete description.
5. **Vague attributions / weasel words** — "experts argue", "observers note",
   "studies show" (with none cited). Name the source or drop the claim.
6. **Formulaic "Challenges / Future Prospects" sections** — replace with concrete
   specifics.

### Language & grammar
7. **AI vocabulary** — delve, crucial, pivotal, enhance, foster, showcase,
   tapestry, testament, underscore, intricate, vibrant, landscape (abstract). They
   co-occur; strip them.
8. **Copula avoidance** — "serves as", "boasts", "features" where "is/are/has"
   works. Use the plain verb.
9. **Negative parallelisms** — "not just X, but Y"; tailing negations like "no
   guessing", "no wasted motion". Write the real clause.
10. **Rule of three** — forced triples ("innovation, inspiration, and insight").
    Use the number of items that are actually true.
11. **Elegant variation** — cycling synonyms for the same noun across sentences.
    Reuse the plain word.
12. **False ranges** — "from X to Y" where X and Y aren't on one scale.
13. **Passive voice / subjectless fragments** — "No config needed", "results are
    preserved automatically". Name the actor where active is clearer.

### Style
14. **Em / en dashes — cut them all.** Hard constraint. Replace each `—`, `–`, `--`,
    or spaced em dash with a period, comma, colon, parentheses, or a restructure.
    Scan the final draft for `—` and `–`; any hit means it isn't done.
15. **Boldface overuse** — don't bold phrases mechanically.
16. **Inline-header vertical lists** — "**Performance:** Performance is improved…".
    Fold into prose or plain bullets.
17. **Title Case In Headings** — use sentence case.
18. **Decorative emojis** — fine as our intentional section markers (per markdown
    instructions and existing social posts); not as fake-structure bullet prefixes
    inside body copy.
19. **Curly quotes** — replace `“ ” ‘ ’` with straight `" '`.

### Communication & filler
20. **Chatbot artifacts** — "I hope this helps", "Certainly!", "Would you like…".
21. **Knowledge-cutoff / gap-filling** — "as of my last update", "while details are
    limited", "likely grew up…". Say what's known or cut it.
22. **Sycophancy** — "Great question!", "You're absolutely right!".
23. **Filler phrases** — "in order to" → "to"; "due to the fact that" → "because";
    "at this point in time" → "now"; "has the ability to" → "can".
24. **Excessive hedging** — "could potentially possibly". Say it once.
25. **Generic upbeat conclusions** — "the future looks bright". State the concrete
    next step.
26. **Hyphenated-pair overuse** — keep the hyphen attributively ("a high-quality
    print"), drop it in predicate position ("the print is high quality").
27. **Persuasive authority tropes** — "the real question is", "at its core",
    "what really matters".
28. **Signposting** — "let's dive in", "here's what you need to know". Just say it.
29. **Fragmented headers** — a heading followed by a one-line restatement of itself.
30. **Diff-anchored writing** — narrating a change ("this replaces the old…") in
    docs that should describe the thing as it is. Exception: changelogs / release
    notes / migration guides, which are version-scoped by design.
31. **Manufactured punchlines / staccato drama** — runs of short fragments to fake
    intensity. One short sentence for emphasis is fine.
32. **Aphorism formulas** — "X is the language of Y", "X becomes a trap". State the
    concrete claim.
33. **Conversational rhetorical openers** — "Honestly?", "Look,", "Here's the thing"
    as standalone hooks.

---

## 🔬 Detection — don't over-edit

A clean human writer can hit several patterns with zero AI involvement. **Look for
clusters, not isolated hits.** A single em dash means nothing; em dashes + rule of
three + "vibrant tapestry" + a "Conclusion" section is a confession.

**Do NOT flag on their own:** polished grammar, formal vocabulary, one `however`, a
lone curly quote (editors auto-curl), a single emphatic short sentence, "honestly"
mid-sentence, unsourced claims, our intentional emoji section headers.

**Preserve (signs of a real person):** specific hard-to-fabricate detail, mixed
feelings / unresolved tension, dated references and slang, defensible first-person
choices, genuine asides and self-corrections, varied sentence length.

---

## 🔁 Process

1. Read the input and mark every pattern instance.
2. Draft a rewrite: reads naturally aloud, varied sentence length, plain
   constructions (is/are/has), correct register, voice-matched.
3. Audit — ask "what still reads as AI here?" and list the remaining tells briefly.
4. Final rewrite addressing them, with **no em or en dashes**.

Deliver: the final humanized text (written back to the file when applicable), and a
short bullet list of what changed. Skip the bullets for tiny edits.

---

## 📚 References

- [blader/humanizer](https://github.com/blader/humanizer/blob/main/SKILL.md) — upstream skill this adapts
- [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) — source patterns
- [Markdown guidelines](../../instructions/markdown.instructions.md) — emoji headers, structure conventions
- Text-creating skills that should run this pass:
  [`makerworld-description`](../makerworld-description/SKILL.md),
  [`grill-my-model`](../grill-my-model/SKILL.md),
  [`grill-my-plan`](../grill-my-plan/SKILL.md)
