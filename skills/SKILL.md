---
name: aa-book
description: 'Full Anna''s Archive → pdf-brain pipeline. Search, download, convert, ingest, and log books to knowledge base. Use when: (1) User wants to add a book to pdf-brain, (2) User asks "find [book]" or "get me [title]", (3) User wants to search for technical books/papers. Triggers on: "find book", "download book", "add to pdf-brain", "search anna", "aa-book".'
metadata: {"moltbot":{"requires":{"bins":["aa-book","pdf-brain"]}}}
---

# aa-book: Anna's Archive → pdf-brain Pipeline

Full automation: search → download → convert → ingest → log → cleanup.

## Quick Reference

```bash
# Search (PDFs shown first, green = no conversion needed)
aa-book search "designing data intensive applications"
aa-book search "clean architecture" pdf    # PDFs only

# Full pipeline (background mode recommended)
aa-book add <md5> "Why this book matters" -b

# Check status & quota
aa-book status
```

## Commands

### search
```bash
aa-book search "query terms" [format]
```
- Shows: MD5, format (color-coded), size, title
- Green = PDF (no conversion), Yellow = needs conversion
- Optional format filter: `pdf`, `epub`, `mobi`
- Results sorted with PDFs first

### add (Full Pipeline)
```bash
aa-book add <md5> "reason for adding" [-b]
```
Pipeline steps:
1. Download from Anna's Archive
2. Convert epub/mobi → PDF (via Calibre)
3. Ingest into pdf-brain
4. Log to hivemind memory
5. Cleanup temporary files

Use `-b` for background mode (non-blocking).

### download
```bash
aa-book download <md5> [output_dir]
```
Download only, with auto epub→PDF conversion.

### status
```bash
aa-book status
```
Shows: active job progress, daily quota (25/day limit).

## Example Session

```bash
$ aa-book search "domain driven design" pdf
abc123...  pdf   15.2 MB  Domain-Driven Design - Eric Evans
def456...  pdf    8.1 MB  Implementing Domain-Driven Design

$ aa-book add abc123... "Core DDD reference for architecture decisions" -b
🚀 Running in background (PID: 12345)
   Monitor: tail -f /tmp/aa-book-progress.log

$ aa-book status
✅ Job completed
[STATUS] ✅ Complete: Domain-Driven Design - Eric Evans
📊 Downloads today: 3/25
```

## Daily Limits

- 25 fast downloads per day (tracked automatically)
- Check quota with `aa-book status`
- Resets at midnight

## Progress Monitoring

Long downloads run in background. Monitor:
```bash
tail -f /tmp/aa-book-progress.log
aa-book status
```
