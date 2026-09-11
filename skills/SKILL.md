---
name: aa-book
description: 'Anna''s Archive acquisition helper. Search books, download through fast partner pages with browser auth, convert epub/mobi to PDF when needed, transfer to NAS, and ingest into the docs brain. Use when: (1) user asks to find/download a book, (2) user asks for Anna''s Archive search, (3) user needs a book file staged for downstream ingest. Triggers: "find book", "download book", "search anna", "aa-book", "grab the books".'
metadata: {"moltbot":{"requires":{"bins":["aa-book","agent-browser","secrets"]}}}
---

# aa-book: Anna's Archive → NAS Acquisition

Workflow: search → authenticated download → optional convert → NAS transfer → (optionally) docs-brain ingest.

The binary lives at `~/Code/joelhooks/aa-download/bin/aa-book`, symlinked into `~/.local/bin/aa-book`. If `aa-book` isn't on PATH, use the repo path — don't hunt.

## Quick Reference

```bash
# Search
aa-book search "designing data intensive applications"
aa-book search "clean architecture" pdf    # PDFs only

# Download
aa-book download <md5>
aa-book download <md5> /Users/joel/clawd/data/pdf-brain/incoming
aa-book download <md5> /Users/joel/clawd/data/pdf-brain/incoming --keep-local

# Check status & quota
aa-book status
aa-book login
aa-book mirrors      # probe/refresh mirror list when things act dead
```

## Commands

### search
```bash
aa-book search "query terms" [format]
```
- Shows MD5 + format + size + title
- Optional format filter: `pdf`, `epub`, `mobi`

### download
```bash
aa-book download <md5> [output_dir] [--keep-local]
```
Steps:
1. Ensure browser login/session
2. Resolve partner download URL
3. Download file (retry)
4. Convert epub/mobi to PDF if possible
5. Copy to the configured NAS book root unless `--keep-local` is set

**`--keep-local` semantics matter**: WITHOUT it, the local file is DELETED after a successful NAS transfer. If the book is headed for docs-brain ingest, you need the local file — see the standard flow below.

### status
```bash
aa-book status
```
Shows current progress, daily count, and a bounded SSH writeability check for the configured NAS book root. A missing or stale storage target makes the command exit non-zero.

## Standard flow: grab a book for the docs brain

Verified end-to-end 2026-07-13 (A Pattern Language, Metaphors We Live By):

```bash
# 1. Download, keeping the local copy
aa-book download <md5> /Users/joel/clawd/data/pdf-brain/incoming --keep-local

# 2. Archive to NAS yourself (aa-book skipped it because of --keep-local).
# Read the same machine-local placement config that aa-book uses; do not hardcode a retired NAS.
NAS_HOST=$(awk -F= '$1 == "JOELCLAW_NAS_HOST" {sub(/^[^=]*=/, ""); print; exit}' ~/.config/system-bus.env)
NAS_BOOKS_DIR=$(awk -F= '$1 == "JOELCLAW_NAS_BOOKS_DIR" {sub(/^[^=]*=/, ""); print; exit}' ~/.config/system-bus.env)
year=$(date +%Y)
ssh -o BatchMode=yes "$NAS_HOST" "mkdir -p '$NAS_BOOKS_DIR/$year'"
scp /Users/joel/clawd/data/pdf-brain/incoming/<file>.pdf "$NAS_HOST:$NAS_BOOKS_DIR/$year/"

# 3. Queue docs-brain ingest (async Inngest pipeline; verify later with docs search)
joelclaw docs add /Users/joel/clawd/data/pdf-brain/incoming/<file>.pdf --title "<Proper Title (Author)>"
```

## Daily Limits

- 25 fast downloads per day (tracked automatically)
- Check quota with `aa-book status`
- Resets at midnight

## Progress Monitoring

Monitor:
```bash
tail -f /tmp/aa-book-progress.log
aa-book status
```

## When search returns nothing

`aa-book search` is curl-based. As of 2026-09-10 every Anna's Archive mirror
302s `/search` into a DDoS-Guard bot check that curl cannot pass, so the AA
half of search is blank. `aa-book search` now handles this itself:

1. AA search returns no md5 links → it warns and **falls back to Libgen**
   (`libgen.li`, then `libgen.vg`). Libgen shares md5s with Anna's Archive, so
   any md5 it prints goes straight into `aa-book download`, which is
   browser-driven and still works through a shielded mirror. Verified
   end-to-end 2026-09-10 (Rebuilding Milo: Libgen md5 → fast partner → NAS).
2. Libgen also empty → `aa-book mirrors` re-probes. Statuses mean:
   - `ok` — curl search works on this mirror
   - `shielded` — bot check; search blank, download fine (this is normal now)
   - `parked` — squatter page (`annas-archive.li` since ~2026-09); never used
   - `dead` / `http-NNN` — unreachable
3. Still nothing → the book probably isn't on either index under that title.
   Try author name or ISBN as the query before giving up.

The old agent-browser search fallback (open `/search` in the logged-in
browser) is **dead**: DDoS-Guard serves a manual "I'm not a robot" checkbox to
agent-browser and clicking it by coordinates does not clear it. Don't burn
time on it. The md5 page check below still works if you already have an md5:

```bash
agent-browser open "https://annas-archive.gd/md5/<md5>"
agent-browser wait --load networkidle --timeout 15000
agent-browser eval "Array.from(document.querySelectorAll('a')).filter(a=>/fast partner/i.test(a.textContent||'')).length"
```

## Gotchas

- **Anna's Archive format labels can lie** — A "pdf"-labeled md5 may be a zip/epub. Verify the `/md5/<hash>` page has a Fast Partner Server link before downloading; prefer passing an explicit verified md5.
- **Libgen-slow-only md5s** — Some md5s fail with bare exit 1 on `aa-book download`. No retry; pick a different copy.
- **azw3 conversion** — azw3 needs conversion to PDF before docs-ingest. aa-book's auto-convert historically only covered epub/mobi; a March-2026 azw3 of A Pattern Language sat on the NAS unconverted and never reached the docs brain — the gotcha is real. Verify before relying on it.
- **Status codes lie about mirror health** — a parked domain answers 200 and a DDoS-Guard mirror answers 200 on `/` then 302s `/search` into a check page. The resolver now classifies mirrors by fetching `/search?q=test` and looking for md5 links (`ok`), a bot-check page (`shielded`), or squatter text (`parked`). It prefers `ok`, accepts `shielded` (download still works), never picks `parked`/`dead`, and caches the pick for an hour in `~/.config/annas-archive/active-mirror.txt`. `aa-book mirrors` forces a re-probe.
- **NAS placement comes from machine config.** `JOELCLAW_NAS_HOST` and `JOELCLAW_NAS_BOOKS_DIR` may be exported directly or stored in `~/.config/system-bus.env`. `aa-book status` proves the configured directory exists and is writable before claiming storage health.
- **This skill's source of truth** is `~/Code/joelhooks/aa-download/skills/SKILL.md`; `~/.claude/skills/aa-book` is a symlink. Edit in the repo, commit, push — same-session, like any durable surface.
