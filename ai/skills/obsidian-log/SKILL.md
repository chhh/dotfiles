---
name: obsidian-log
description: Log work progress, findings, and gotchas from a coding session into the shared Obsidian knowledge-base vault (a daily journal entry plus, for substantial investigations, a linked page). Use when the user asks to log/journal/write up/record this session, note a finding for later, or when a session produced a non-trivial investigation, success, or failure worth remembering across sessions.
---

# Obsidian work log

Records what an agent did, found, or got stuck on into a shared Obsidian vault so
future sessions (by this agent or any other) don't have to rediscover it. Two
kinds of writes:

- **Journal entry** (`journals/YYYY-MM-DD.md`) — one line, always.
- **Page** (`pages/<Title>.md`) — only for a substantial investigation, success,
  or failure; linked from the journal entry.

This skill works the same way whether you are Claude Code or a Pi agent. Nothing
here is tool-specific: it only needs the ability to read/list/write files.

## Step 1 — Resolve the vault path. Do this first, every time.

The vault lives on Google Drive for account `dmitriy.avtonomov@gmail.com`, at the
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

Before creating a new page, check `pages/` for an existing page on the same
topic from a recent session — prefer extending that page (e.g. adding a
"follow-up" dated subsection) over fragmenting the history across duplicates.

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

- Link every page from at least one journal entry (Step 2).
- Cross-link related pages with `[[Wikilinks]]` where it helps navigation —
  don't force it.

## What not to do

- Don't ask the user for permission to log — logging is the point of invoking
  this skill. Do ask if the vault path is genuinely unknown (Step 1.2) or the
  vault directory is missing (Step 1.3) — those are real blockers, not
  formalities.
- Don't write a page for everything; most sessions warrant only a journal line.
- Don't overwrite an existing daily note or page — append/extend.
- Don't pad the journal entry with process narrative ("First I explored X, then
  I tried Y, then..."). That belongs in the page, if there is one. The journal
  entry is the one-sentence gist.
