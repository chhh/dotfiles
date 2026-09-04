---
name: obsidian-log
description: Log work progress, findings, and gotchas from a coding session into an Obsidian knowledge-base vault - a daily journal entry in the global cross-project vault, plus, for substantial investigations, a linked page in either that vault or the current repo's own docs/ vault. Also writes "dated docs" on request. Use when the user asks to log/journal/write up/record this session, note a finding for later, asks for a dated doc, or when a session produced a non-trivial investigation, success, or failure worth remembering across sessions.
---

# Obsidian work log

Records what an agent did, found, or got stuck on into an Obsidian vault so
future sessions (by this agent or any other) don't have to rediscover it.

There are **two vaults**, with different jobs:

- **The global vault** — on Google Drive, spans every project. Holds the daily
  journal and pages whose lesson *transfers* to other codebases.
- **The repo vault** — `<repo>/docs`, when that repo has one. Holds
  implementation knowledge about *that* codebase, ships in every clone, and is
  versioned alongside the code it describes. **No journals**: a daily log is
  inherently cross-project and cannot be split across repos.

So there are three kinds of write:

- **Journal entry** (`journals/YYYY-MM-DD.md`, global vault only) — one line,
  always.
- **Page** (`pages/<Title>.md`, in *one* of the two vaults) — only for a
  substantial investigation, success, or failure; linked from the journal entry.
- **Dated note** (`<repo>/docs/YYYY-MM-DD_HH-mm_slug.md`) — only when the user
  asks for a "dated doc". Immutable once written. See Step 5.

This skill works the same way whether you are Claude Code or a Pi agent. Nothing
here is tool-specific: it only needs the ability to read/list/write files.

## Step 0 — Is there a repo vault?

Check the current project for `docs/.obsidian/` **or** `docs/README.md`
describing a vault. If either exists, that repo has a vault at `<repo>/docs` and
it is a candidate target for pages (Step 3.5). Note that `docs/.obsidian/` is
usually git-ignored, so a fresh clone may have only the `README.md` — treat
either as sufficient evidence.

No repo vault is not an error and not something to fix: most repos don't have
one, and creating one is a decision for the user, not a side effect of logging.
Write the page to the global vault and move on.

A repo vault's layout differs from the global one:

- `docs/pages/<Title>.md` — living pages, same format as the global vault's.
- `docs/YYYY-MM-DD_HH-mm_slug.md` — immutable dated notes at the vault root.
- **No `journals/`.** Never create one.
- Other undated files (`RELEASING.md`, `how-it-works/`) are the repo's own
  reference docs. Leave them alone.

## Step 1 — Resolve the global vault path. Do this first, every time.

The global vault lives on Google Drive for account
`dmitriy.avtonomov@gmail.com`, at the
relative path `My Drive/my/chhh-kb/ai-obsidian` inside the Drive root. Known
absolute defaults:

- **macOS**: `/Users/dimaavtonomov/Library/CloudStorage/GoogleDrive-dmitriy.avtonomov@gmail.com/My Drive/my/chhh-kb/ai-obsidian`
- **Windows**: `G:\My Drive\my\chhh-kb\ai-obsidian`

Resolution order:

1. **Check your own persistent memory first** (CLAUDE.md / project or global
   memory files for Claude Code, the equivalent long-term notes for a Pi agent).
   If a vault path was recorded there in an earlier session, use it and skip to
   the validation check below.
2. **No memory found → detect the OS** and use the matching default above.
   - Any other OS (Linux, etc.) has no known default. **Stop and ask the user**
     for the vault path. Do not guess. Once they answer, suggest they let you
     record it in persistent memory so this step is skipped next time.
3. **Validate the resolved path.** A real vault directory contains a `.obsidian`
   folder and `journals`/`pages` subfolders. Check the directory exists and
   looks like this vault.
   - **Exists and looks right → proceed to Step 2.**
   - **Does not exist** (most likely cause: the cloud drive isn't mounted or
     hasn't finished syncing on this machine) — **stop immediately and notify
     the user.** State the exact path you checked. Do not create the directory,
     do not fall back to writing somewhere else, and do not treat this as "no
     vault" and skip logging silently — a missing mount is a problem worth
     surfacing, not working around.
4. **Optional narrow fallback**, only if step 3 failed and you want to check for
   a nonstandard mount point before giving up: look for a Google Drive folder
   under a different mount and append the relative path
   `My Drive/my/chhh-kb/ai-obsidian`:
   - Windows: try other drive letters for a `My Drive` folder.
   - macOS: check other folders matching
     `~/Library/CloudStorage/GoogleDrive-*/My Drive/my/chhh-kb/ai-obsidian`.
   - If exactly one candidate validates (Step 3's check), use it and tell the
     user the path differs from the known default so they can update memory.
   - If zero or more than one candidate is found, that's still a stop-and-notify
     case — do not guess between ambiguous options.

Never invent a vault location and never write vault-shaped content somewhere
else "just in case." If you can't resolve and validate a real vault path, don't
log — surface the problem instead.

## Step 2 — Write the journal entry

Open (or create, if it doesn't exist) `journals/YYYY-MM-DD.md` for today's date.
**Append**, never overwrite existing content — if the file already has entries,
add a `---` rule then your entry below it.

Style (this is the bar — match it, don't pad it):

- One entry per distinct piece of work, as concise as possible: ideally one
  sentence.
- Lead with a bold project tag if there's an obvious project name, e.g.
  `**antimass** — ...`.
- State the gist directly — what was tried/found/fixed and the headline result,
  not a narrative of the session.
- If a page was written for this work, end the sentence with an arrow and a
  wikilink: `→ [[Page Title]]`. If nothing rose to page-worthy (a quick fix, a
  one-off answer), the journal line stands alone with no link.
- Multiple unrelated pieces of work in one day are multiple entries separated by
  `---`, not merged into one paragraph.

Example (from this vault):

```
**antimass** — built a matched-filter 1D peak finder that scores candidates
against the local carpet of look-alike chemical-noise bumps instead of an
intensity threshold, hitting all 11 reference peaks with zero calls in the
three known-garbage regions in 0.5 s → [[Matched-filter 1D peak finder (success)]]
```

## Step 3 — Decide whether a page is warranted

Write a page when the session involved: a non-trivial investigation, multiple
approaches tried (some rejected), a benchmark or measurement worth keeping, a
bug whose root cause took real digging, or a design decision with tradeoffs a
future session shouldn't have to re-derive.

Don't write a page for: a quick lookup, a one-line fix with an obvious cause, or
anything the journal sentence already fully captures.

Before creating a new page, check `pages/` **in both vaults** for an existing
page on the same topic from a recent session — prefer extending that page (e.g.
adding a "follow-up" dated subsection) over fragmenting the history across
duplicates. A topic already covered in one vault stays in that vault; do not
start a second copy in the other because the routing rule below now points
elsewhere.

## Step 3.5 — Which vault does the page go in?

Only when the repo has a vault (Step 0). The test is **not** which project the
work came from — nearly all work comes from some project. It is:

> Would this page help someone working on a *different* codebase?

- **Yes → global vault.** A release pattern, an algorithm idea, a toolchain
  gotcha, a way of structuring something. The lesson outlives the repo.
- **No → repo vault.** It only makes sense with that repo's source in front of
  you: how a particular module behaves, why a specific default is what it is,
  what a run measured on that codebase.

When a page has both — a transferable insight discovered while doing
repo-specific work — put it where its *bulk* belongs and mention the other in
prose. Don't split one investigation across two vaults.

**Wikilinks do not cross vaults.** A `[[link]]` to a page in the other vault
renders broken forever. Name that page in prose instead, and say which vault it
is in.

If you are unsure, prefer the global vault: a page that turns out to be
repo-specific is still findable there, whereas one buried in a repo nobody has
cloned is not.

## Step 4 — Write the page

File name: `pages/<Title reflecting the outcome>.md` — the title itself must say
whether this was an **investigation** (open question, findings, no code change),
a **success** (task completed, working result), or a **failed** attempt
(tried, didn't work, document why). Suffix pattern used in this vault:
`<Descriptive title> (success|investigation|failed).md`.

### Frontmatter (required, at the very top)

```yaml
---
project: <project name, or omit the key if there isn't one>
date: YYYY-MM-DD
status: success | investigation | failed
tags: [optional, short, lowercase, kebab-case]
---
```

Use the date the work concluded. If the work spanned multiple days, add
`date_started: YYYY-MM-DD` alongside `date`.

### Body sections, in this order

1. **`## The task`** — what was asked. Quote the input prompt. If the task was
   defined over several messages rather than one clean ask, reconstruct the
   *effective* prompt (a blockquote is fine) so a future reader gets the real
   brief without replaying the whole conversation. If a plan was agreed on
   instead of a single prompt, describe that plan here.

2. **`## Summary of the outcome`** (or `## Outcome`) — a short, quotable summary
   of what happened. If there's a success, say so plainly and give the headline
   number(s). A before/after or options-compared table is often the clearest way
   to do this — use one when there are 2+ things to compare.

3. **Detailed body**, split into clearly-titled `##`/`###` sections as the
   content calls for — e.g. "How it works", "The reframing that made it work",
   "Findings" (numbered `F1`, `F2`, ... for a multi-fact investigation). Explain
   the successful method in enough detail that someone could reimplement or
   re-derive it without re-reading code. Reference real file paths and
   `file:line` locations, function/constant names, and measured numbers rather
   than vague description.

4. **`## What did not work`** (name it to fit — "Rejected approaches", "Dead
   ends", etc., but always have this section if anything was tried and
   abandoned). For each: what was tried, why it seemed reasonable, and the
   specific measurement or observation that killed it. This is often the most
   valuable section for a future session — it prevents retrying the same dead
   end. Include bugs found only once a prototype became real, shipped code, and
   test-authoring traps, if any came up.

5. **`## Follow-up ideas`** — a numbered list of what's left to try, open
   questions, or natural next steps. Keep each item to 1-2 sentences.

6. **`## References`** — only if literature, prior art, or other documents were
   consulted. Cite them properly (author, year, venue, DOI/URL where available).

### Linking

- Link every page from at least one journal entry (Step 2) — including a page
  written to a repo vault. The journal is the timeline for *all* work, so a repo
  page that no journal entry mentions is invisible. Wikilinks don't reach across
  vaults, so for a repo page give the repo-relative path in backticks instead:
  `` antimass: `docs/pages/<Title>.md` ``.
- Cross-link related pages *within the same vault* with `[[Wikilinks]]` where it
  helps navigation — don't force it.

## Step 5 — Dated notes ("dated doc")

Only when the user asks for a "dated doc" / "put it in a dated doc". Write
`<repo>/docs/YYYY-MM-DD_HH-mm_slug.md`, timestamp from `date` rather than
guessed, content being the full write-up and not a summary. Create `docs/` if it
does not exist.

These are **records, not pages**: immutable once written, because their value is
that they say what was true and what was measured on that date. Never edit one
after the fact — write a new one. Never move or rename one either: in a mature
repo, source comments cite these paths (antimass has 44 such citation sites
across 23 files), and renaming silently breaks every one.

A dated note and a page are complements, not alternatives. Substantial work
often deserves both: the note for the run and its numbers, the page for what the
code now does.

## What not to do

- Don't ask the user for permission to log — logging is the point of invoking
  this skill. Do ask if the *global* vault path is genuinely unknown (Step 1.2)
  or its directory is missing (Step 1.3) — those are real blockers, not
  formalities. A *missing repo vault* is neither; it just means the page goes to
  the global vault.
- Don't create a repo vault, or a `journals/` inside one. Those are the user's
  decisions, not a side effect of logging.
- Don't write a page for everything; most sessions warrant only a journal line.
- Don't overwrite an existing daily note or page — append/extend.
- Don't write the same page into both vaults. One topic, one page, one vault.
- Don't pad the journal entry with process narrative ("First I explored X, then
  I tried Y, then..."). That belongs in the page, if there is one. The journal
  entry is the one-sentence gist.
