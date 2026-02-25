---
name: aa-book
description: 'Anna''s Archive acquisition helper. Search books, download through fast partner pages with browser auth, convert epub/mobi to PDF when needed, and transfer to NAS. Use when: (1) user asks to find/download a book, (2) user asks for Anna''s Archive search, (3) user needs a book file staged for downstream ingest. Triggers: "find book", "download book", "search anna", "aa-book".'
metadata: {"moltbot":{"requires":{"bins":["aa-book","agent-browser","secrets"]}}}
---

# aa-book: Anna's Archive → NAS Acquisition

Workflow: search → authenticated download → optional convert → NAS transfer.

## Quick Reference

```bash
# Search
aa-book search "designing data intensive applications"
aa-book search "clean architecture" pdf    # PDFs only

# Download
aa-book download <md5>
aa-book download <md5> /Users/joel/clawd/data/pdf-brain/incoming

# Check status & quota
aa-book status
aa-book login
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
aa-book download <md5> [output_dir]
```
Steps:
1. Ensure browser login/session
2. Resolve partner download URL
3. Download file (retry)
4. Convert epub/mobi to PDF if possible
5. Copy to NAS (`/volume1/home/joel/books/YYYY/`)

### status
```bash
aa-book status
```
Shows current progress + daily count.

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
