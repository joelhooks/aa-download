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
5. Copy to NAS (`/volume1/home/joel/books/YYYY/`) unless `--keep-local` is set

**`--keep-local` semantics matter**: WITHOUT it, the local file is DELETED after a successful NAS transfer. If the book is headed for docs-brain ingest, you need the local file — see the standard flow below.

### status
```bash
aa-book status
```
Shows current progress + daily count.

## Standard flow: grab a book for the docs brain

Verified end-to-end 2026-07-13 (A Pattern Language, Metaphors We Live By):

```bash
# 1. Download, keeping the local copy
aa-book download <md5> /Users/joel/clawd/data/pdf-brain/incoming --keep-local

# 2. Archive to NAS yourself (aa-book skipped it because of --keep-local)
ssh -o BatchMode=yes joel@three-body "mkdir -p /volume1/home/joel/books/$(date +%Y)"
scp /Users/joel/clawd/data/pdf-brain/incoming/<file>.pdf joel@three-body:/volume1/home/joel/books/$(date +%Y)/

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

## When search returns nothing: the browser fallback

`aa-book search` is curl-based and dies silently when mirrors are bot-shielded or flapping — an empty result list with just the Usage line does NOT mean the book isn't there. Verified failure modes (2026-07-13): mirrors returning transient 502s to curl while rendering fine in a real browser; `annas-archive.li` serving a literal `"OK"` stub; `welib.org` sitting behind a Cloudflare challenge that curl can't clear.

Recovery ladder:

1. `aa-book mirrors` — re-probe; transient 502s often clear in minutes. Retry the search.
2. Still empty → search through `agent-browser` (which holds the login session):

```bash
agent-browser open "https://annas-archive.gd/search?q=<query+terms>"
agent-browser wait --load networkidle --timeout 15000
# Filter by title match — the page has decoy md5 links (carousels, random books):
agent-browser eval "Array.from(document.querySelectorAll('a[href*=\"/md5/\"]')).filter(a=>/<title regex>/i.test(a.textContent||'')).slice(0,8).map(a => { const row=(a.closest('div')?.parentElement?.innerText||'').replace(/\s+/g,' '); const meta=(row.match(/(English|Spanish|German)[^·]*·[^·]*·[^·]*·[^·]*/)||[''])[0]; return a.getAttribute('href').split('/md5/')[1].slice(0,32)+'  '+meta.slice(0,90)+'  '+(a.textContent||'').trim().slice(0,60); }).join('\n')"
```

3. Verify the chosen md5 page has Fast Partner links before downloading:

```bash
agent-browser open "https://annas-archive.gd/md5/<md5>"
agent-browser wait --load networkidle --timeout 15000
agent-browser eval "Array.from(document.querySelectorAll('a')).filter(a=>/fast partner/i.test(a.textContent||'')).length"
```

4. `aa-book download <md5> ...` as normal — the download path is browser-driven and works even when curl search doesn't.

## Gotchas

- **Anna's Archive format labels can lie** — A "pdf"-labeled md5 may be a zip/epub. Verify the `/md5/<hash>` page has a Fast Partner Server link before downloading; prefer passing an explicit verified md5.
- **Libgen-slow-only md5s** — Some md5s fail with bare exit 1 on `aa-book download`. No retry; pick a different copy.
- **azw3 conversion** — azw3 needs conversion to PDF before docs-ingest. aa-book's auto-convert historically only covered epub/mobi; a March-2026 azw3 of A Pattern Language sat on the NAS unconverted and never reached the docs brain — the gotcha is real. Verify before relying on it.
- **Cloudflare-403 mirror trap** — the mirror resolver treats an HTTP 403 as "reachable", but a 403 from Cloudflare means every subsequent curl call (search especially) silently fails. The resolver now prefers 200/302 mirrors and only falls back to 403 ones; if search goes quiet, check which mirror is Active in `aa-book mirrors` output.
- **This skill's source of truth** is `~/Code/joelhooks/aa-download/skills/SKILL.md`; `~/.claude/skills/aa-book` is a symlink. Edit in the repo, commit, push — same-session, like any durable surface.
