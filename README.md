# aa-book

Anna's Archive acquisition helper: search, download from fast partner pages, convert (optional), and copy to NAS.

## Features

- Search with format and size (`pdf`, `epub`, `mobi`)
- Browser-authenticated fast download links via `agent-browser`
- Optional `epub`/`mobi` to PDF conversion via Calibre
- NAS transfer through machine-local placement config
- Daily quota, run status, and NAS destination health output

## Installation

```bash
git clone https://github.com/joelhooks/aa-download ~/Code/aa-download
ln -sf ~/Code/aa-download/bin/aa-book ~/.local/bin/aa-book
```

## Dependencies

- `agent-browser`
- `secrets` (must contain `annas_archive_key`)
- `curl`, `python3`
- `ssh`, `scp`
- `ebook-convert` (optional for epub/mobi conversion)

## Usage

```bash
# Search
aa-book search "designing data intensive applications"
aa-book search "designing data intensive applications" pdf

# Download to staging or custom dir
aa-book download <md5>
aa-book download <md5> /Users/joel/clawd/data/pdf-brain/incoming
aa-book download <md5> /Users/joel/clawd/data/pdf-brain/incoming --keep-local

# Status / login
aa-book status  # exits non-zero when configured NAS storage is unavailable
aa-book login
```

## Notes

- NAS placement uses `JOELCLAW_NAS_HOST` and `JOELCLAW_NAS_BOOKS_DIR` from the environment or `~/.config/system-bus.env`. The repository does not own machine topology.
- Auth uses leased secrets and browser session state at:
  - `~/.config/annas-archive/aa-session.json`
- Daily counter:
  - `~/.config/annas-archive/download_count_YYYY-MM-DD.txt`
- Local progress log:
  - `/tmp/aa-book-progress.log`

## License

MIT
