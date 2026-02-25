# aa-book

Anna's Archive acquisition helper: search, download from fast partner pages, convert (optional), and copy to NAS.

## Features

- Search with format and size (`pdf`, `epub`, `mobi`)
- Browser-authenticated fast download links via `agent-browser`
- Optional `epub`/`mobi` to PDF conversion via Calibre
- NAS transfer (`joel@three-body:/volume1/home/joel/books/YYYY/`)
- Daily quota tracking and run status output

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

# Status / login
aa-book status
aa-book login
```

## Notes

- Auth uses leased secrets and browser session state at:
  - `~/.config/annas-archive/aa-session.json`
- Daily counter:
  - `~/.config/annas-archive/download_count_YYYY-MM-DD.txt`
- Local progress log:
  - `/tmp/aa-book-progress.log`

## License

MIT
