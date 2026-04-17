# Site Upgrade Package

## How to Apply

From the root of your `m1ran4a.github.io` repo:

```bash
# 1. Back up first
git checkout main && git pull

# 2. Copy these files into your repo (overwrite existing ones)
#    The key files to copy:
#
#    assets/css/extended/custom.css  → NEW: full design system (replaces old extend_head.html CSS)
#    layouts/partials/extend_head.html → REPLACE: now only loads fonts (CSS moved to assets/)
#    content/cv.md                   → REPLACE: fully populated CV page
#    Makefile                        → NEW: maintenance commands
#    CLAUDE.md                       → NEW: Claude Code governance file

# 3. Create the assets directory (Hugo auto-picks up CSS from here)
mkdir -p assets/css/extended

# 4. Copy files
cp -r assets/   /path/to/m1ran4a.github.io/assets/
cp -r layouts/  /path/to/m1ran4a.github.io/layouts/
cp content/cv.md /path/to/m1ran4a.github.io/content/cv.md
cp Makefile     /path/to/m1ran4a.github.io/Makefile
cp CLAUDE.md    /path/to/m1ran4a.github.io/CLAUDE.md

# 5. Test locally
cd /path/to/m1ran4a.github.io
hugo server -D

# 6. If it looks good, deploy
make publish MSG="visual overhaul: new design system, populated CV, maintenance tooling"
```

## What Changed

| File | Action | Description |
|------|--------|-------------|
| `assets/css/extended/custom.css` | **NEW** | Complete design system — dark industrial editorial aesthetic, custom components, animations |
| `layouts/partials/extend_head.html` | **REPLACE** | Cleaned up — fonts only, CSS now lives in proper Hugo assets pipeline |
| `content/cv.md` | **REPLACE** | Fully populated CV with timeline, skills grid, cert badges, download button |
| `Makefile` | **NEW** | Quick commands: make post, make rule, make publish, make serve, etc. |
| `CLAUDE.md` | **NEW** | Claude Code governance — teaches Claude Code how to work with your repo |

## After Applying

Run `make help` to see all available commands:

```
drafts          List all draft posts
help            Show this help
post            Create a new blog post. Usage: make post TITLE="my-post-title"
publish         Build, commit, and push. Usage: make publish MSG="commit message"
quick           Quick publish with auto-generated message
rule            Create a new detection rule. Usage: make rule TITLE="my-rule-name"
serve           Start local preview server (with drafts)
serve-prod      Start local preview server (production mode, no drafts)
undraft         Set a draft to published. Usage: make undraft FILE="content/blog/my-post.md"
update-cv       Replace CV PDF. Usage: make update-cv PDF="/path/to/new-cv.pdf"
```
