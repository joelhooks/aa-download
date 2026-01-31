# aa-book

Full Anna's Archive → pdf-brain pipeline. Search, download, convert, ingest, and log books to your knowledge base.

## Features

- **Search with format info** - Shows format (PDF/epub/mobi), size, title. PDFs highlighted green (no conversion needed)
- **Format filtering** - Filter search results by format
- **Auto-conversion** - epub/mobi → PDF via Calibre
- **pdf-brain integration** - Auto-ingest after download
- **Hivemind logging** - Records what you added and why
- **Background mode** - Long downloads don't block
- **Daily quota tracking** - 25/day limit with status display
- **Smart retries** - Multiple server fallback on failures

## Installation

```bash
# Clone
git clone https://github.com/joelhooks/aa-download ~/Code/joelhooks/aa-download

# Symlink to PATH
ln -sf ~/Code/joelhooks/aa-download/bin/aa-book ~/.local/bin/aa-book

# Setup credentials
mkdir -p ~/.config/annas-archive
echo "your-secret-key" > ~/.config/annas-archive/secret.txt
chmod 600 ~/.config/annas-archive/secret.txt
```

### Dependencies

- `curl` - HTTP requests
- `python3` - Search result parsing
- `calibre` - epub/mobi → PDF conversion
- `pdf-brain` - Knowledge base ingestion
- `swarm` (optional) - Hivemind memory logging

## Usage

```bash
# Search (PDFs first, green = no conversion)
aa-book search "designing data intensive applications"
aa-book search "clean architecture" pdf    # PDFs only

# Full pipeline: download → convert → ingest → log → cleanup
aa-book add <md5> "Why this book is useful"
aa-book add <md5> "Reference for X" -b     # Background mode

# Download only
aa-book download <md5> ~/output/dir

# Check status & daily quota
aa-book status

# Force re-login
aa-book login
```

## Pipeline

The `add` command runs the full pipeline:

1. **Download** - From Anna's Archive with retry logic
2. **Convert** - epub/mobi → PDF via Calibre's ebook-convert
3. **Ingest** - Add to pdf-brain knowledge base
4. **Log** - Record in hivemind memory (what + why)
5. **Cleanup** - Remove temp files

## Configuration

Stored in `~/.config/annas-archive/`:
- `secret.txt` - Your AA secret key
- `cookies.txt` - Session cookies (auto-managed)
- `download_count_YYYY-MM-DD.txt` - Daily quota tracking

## Moltbot/Claude Skill

Skill file at `skills/SKILL.md`. Install:

```bash
# Moltbot
ln -sf ~/Code/joelhooks/aa-download/skills ~/.clawdbot/skills/aa-book

# Claude Code
ln -sf ~/Code/joelhooks/aa-download/skills ~/.claude/skills/aa-book
```

## Related

- [pdf-brain](https://github.com/joelhooks/pdf-brain) - Vector-powered knowledge base
- [swarm-tools](https://github.com/joelhooks/swarm-tools) - Hivemind memory system

## License

MIT
