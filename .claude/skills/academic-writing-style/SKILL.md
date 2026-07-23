---
name: academic-writing-style
description: Style and revision toolkit for academic prose — active voice, punctuation variety, concision/wordiness, formal register, paragraph structure (claim/evidence/analysis), organization via outlining, and reverse-outlining checks. Use when writing, editing, or revising sentences and paragraphs of academic text, or when reviewing a full draft for style and organization; complements research-paper-writing, which covers ML-paper section structure and reviewer-facing presentation.
---
# Academic Writing Style

## Overview

A style and revision toolkit for academic prose, built from writing-center
guidance. The nine core rules below govern how individual sentences read;
the `references/` files add deeper checklists for wordiness, organization,
revision, paragraph structure, and reverse outlining. For ML/CV/NLP
section structure (abstracts, intros, method sections), use the
`research-paper-writing` skill; this skill governs prose quality within
any section.

Editing and revision are different jobs — editing fixes sentences,
revision re-examines the argument (see `references/revision.md`). Decide
which one the user is asking for before choosing checks.

## The Nine Rules

### 1. Use ACTIVE voice

Don't say: "The stepmother's house was cleaned by Cinderella." (Passive.)

Say instead: "Cinderella cleaned the stepmother's house." (Active voice.)

Passive voice construction ("was cleaned") is reserved for those occasions
where the "do-er" of the action is unknown.

Example: "Prince Charming saw the glass slipper that was left behind."

### 2. Mix it up in terms of PUNCTUATION

Commonly misused punctuation marks:

**The semi-colon (;)** separates two complete sentences that are
complementary.

Example: "She was always covered in cinders from cleaning the fireplace;
they called her Cinderella."

**The colon (:)** is used...

a. preceding a list.

Example: "Before her stepmother awoke, Cinderella had three chores to
complete: feeding the chickens, cooking breakfast, and doing the wash."

b. as a sort of "drum roll," preceding some big revelation.

Example: "One thing fueled the wicked stepmother's hatred for Cinderella:
jealousy."

**The dash (--)** is made by typing two hyphens. No spaces go in between
the dash and the text. It is used...

a. to bracket off some explanatory information.

Example: "Even Cinderella's stepsisters--who were not nearly as lovely or
virtuous as Cinderella--were allowed to go to the ball."

b. in the "drum roll" sense of the colon.

Example: "Prince Charming would find this mystery lady--even if he had to
put the slipper on every other girl in the kingdom."

### 3. Vary your SENTENCE STRUCTURE

Don't say: "Cinderella saw her fairy godmother appear. She was dressed in
blue. She held a wand. The wand had a star on it. She was covered in
sparkles. Cinderella was amazed. She asked who the woman was. The woman
said, 'I am your fairy godmother.' She said she would get Cinderella a
dress and a coach. She said she would help Cinderella go to the ball."

Instead say (there are multiple correct ways to rewrite this, but here's
one): "Amazed, Cinderella watched as her fairy godmother appeared. The
woman dressed in blue was covered in sparkles and carried a star-shaped
wand. Cinderella asked the woman who she was, to which the woman replied,
'I am your fairy godmother.' The fairy godmother would get Cinderella a
dress and a coach; she would help Cinderella get to the ball."

### 4. Avoid CHOPPINESS (closely related to 3)

Don't say: "She scrubbed the floors. They were dirty. She used a mop. She
sighed sadly. It was as if she were a servant."

Instead say (again, there are multiple ways to do this): "She scrubbed the
dirty floors using a mop, as if she were a servant. She sighed sadly."

### 5. Avoid REPETITION

Don't say: "The stepsisters were jealous and envious."

Instead say: "The stepsisters were jealous." (...or envious. Pick one.)

### 6. Be CONCISE

Don't say: "The mystery lady was one who every eligible man at the ball
admired."

Instead say: "Every eligible man at the ball admired the mystery lady."

### 7. Use the VOCABULARY that you know

Don't always feel you have to use big words. It is always better to be
clear and use simple language rather than showing off flashy words you
aren't sure about and potentially misusing them. This is not to say,
however, that you should settle for very weak vocabulary choices (like
"bad" or "big" or "mad").

### 8. But also work on expanding your VOCABULARY

When reading, look up words you don't know. See how they're used. Start a
list. Incorporate them into your writing as you feel comfortable and as
they are appropriate.

### 9. Keep language FORMAL and avoid language of everyday speech

Don't say: "Cinderella was mellow and good. She never let her stepmother
get to her."

Say instead: "Cinderella was mild-mannered and kind. She never let her
stepmother affect her high spirits."

## Reference Guides

Load only the file(s) the task needs:

- **Wordiness / bloated language** — `references/wordiness.md`:
  repeated ideas, choppy sentences to merge, passive-voice detection,
  wordy-phrase substitution table ("due to the fact that" → "because").
  Load when tightening prose or the user says a draft feels long-winded.
- **Organization** — `references/organization.md`: brainstorm → outline
  → write → after-writing checks (outline symmetry, topic-sentence scan,
  transition audit, read-aloud test). Load when planning a paper or
  diagnosing "flow" problems above the sentence level.
- **Editing vs. revision + revision guidelines** —
  `references/revision.md`: the distinction between the two activities,
  plus a seven-step revision pass (prompt fit, thesis quality, paragraph
  scan, connections, term definitions, mechanics). Load at the start of
  any full-draft revision.
- **Paragraph-level revision questions** —
  `references/paragraph-revision.md`: per-paragraph interrogation of
  topic sentence, evidence, analysis, conclusion, and link to thesis.
  Load when revising individual paragraphs in depth.
- **Reverse outlining** — `references/reverse-outlining.md`: three
  variants — a prompt-driven worksheet, a first-draft element checklist
  with fixes for missing parts, and the "toolbox" backwards outline with
  the "so what?" test. Load after a draft exists, to check that what's
  on the page matches the intended argument.

## Draft-Review Workflow (agent fan-out)

For a quick sentence or paragraph edit, apply the Nine Rules directly —
no agents needed. For a **full-draft style review**, fan out one agent
per check group so each pass stays focused, running them concurrently:

1. **Style agent** — applies the Nine Rules above (voice, punctuation,
   sentence variety, register) sentence by sentence.
2. **Wordiness agent** — loads `references/wordiness.md`; flags
   redundant ideas, choppiness, passive constructions, and wordy phrases
   with suggested rewrites.
3. **Organization agent** — loads `references/organization.md` and
   `references/reverse-outlining.md`; builds a backwards outline of the
   draft, runs the "so what?" test per paragraph, and checks topic
   sentences, transitions, and thesis linkage.
4. **Paragraph-structure agent** — loads
   `references/paragraph-revision.md`; audits each paragraph for topic
   sentence, evidence, analysis, and conclusion.

Give each agent the same draft (file path and line range) and ask for
findings as a list of `location — issue — suggested fix`. Merge the
findings, drop duplicates (wordiness and style passes overlap on
passive voice — keep one), order them by document position, and present
them as suggestions, not silent rewrites. For a paper in this repo, the
final edit must still respect CLAUDE.md: surgical diffs, no reflowing
untouched lines, never touching technical claims or numbers.

## Summary

When it comes to working on style, there are three things to remember:

1. **Empower yourself with knowledge.** Learn to punctuate correctly,
   enhance your vocabulary, etc. Give yourself all the tools there are so
   that you are free to...
2. **...Mix it up!** Avoid repetition of words and sentence structure.
   Variance promotes good "flow" and is more interesting for your reader.
3. **"Write to EXPRESS, not to IMPRESS."** Above all, write actively,
   clearly, and concisely.
