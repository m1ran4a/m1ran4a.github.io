# CLAUDE.md — Project Instructions for Claude Code

## Project Overview

This is Hugo Miranda's personal website and security portfolio, built with Hugo + PaperMod theme, hosted on GitHub Pages at https://m1ran4a.github.io.

## Tech Stack

- **Static site generator:** Hugo (Go-based)
- **Theme:** PaperMod (installed via git clone in CI, NOT submodule)
- **Hosting:** GitHub Pages via GitHub Actions
- **CSS:** Custom design system in `assets/css/extended/custom.css`
- **Fonts:** Manrope (display/body), JetBrains Mono (code), Source Serif 4 (accent)
- **Deployment:** Push to `main` → GitHub Actions builds and deploys automatically

## Directory Structure

```
.
├── config.yml              # Hugo configuration
├── Makefile                # Maintenance commands (make help)
├── content/
│   ├── _index.md           # Home page
│   ├── about.md            # Professional profile
│   ├── cv.md               # CV with timeline, skills, certs
│   ├── search.md           # Search page (PaperMod Fuse.js)
│   ├── 404.md              # Custom 404
│   ├── archives.md         # Archive by date
│   ├── blog/               # Blog posts (writeups, research, CTFs)
│   │   ├── _index.md       # Blog section landing
│   │   └── *.md            # Individual posts
│   └── detection-lab/      # Sigma rules portfolio
│       ├── _index.md       # Detection Lab landing
│       └── *.md            # Individual detection rules
├── archetypes/
│   ├── blog.md             # Template for new blog posts
│   └── detection-lab.md    # Template for new Sigma rules
├── assets/css/extended/
│   └── custom.css          # Full design system (colors, components, layout)
├── layouts/partials/
│   └── extend_head.html    # Font imports and meta tags
├── static/
│   └── files/              # Downloadable files (CV PDF, etc.)
└── .github/workflows/
    └── hugo.yml            # CI/CD pipeline
```

## Common Tasks

### Create a new blog post
```bash
make post TITLE="my-post-slug"
# Then edit content/blog/my-post-slug.md
# Set draft: false when ready
# Run: make publish MSG="new post: my topic"
```

### Create a new detection rule
```bash
make rule TITLE="lsass-memory-access"
# Then edit content/detection-lab/lsass-memory-access.md
# Follow the archetype template
# Run: make publish MSG="new rule: LSASS memory access"
```

### Update the CV
- Edit `content/cv.md` for text changes (experience, certs, skills)
- To update the PDF: `make update-cv PDF="/path/to/new.pdf"`
- Then: `make publish MSG="update cv"`

### Preview locally
```bash
make serve      # With drafts visible
make serve-prod # Production mode (no drafts)
```

### Publish changes
```bash
make publish MSG="description of changes"
make quick  # Auto-generated commit message
```

## Design System

The visual design is defined in `assets/css/extended/custom.css`. Key decisions:

- **Dark theme** (#0a0e14 background) with teal accent (#00e5b0)
- **Manrope** for all headings and body text — geometric, confident
- **JetBrains Mono** for all code and technical elements
- **Custom CSS classes** available in markdown via raw HTML:
  - `.btn-primary`, `.btn-outline` — CTA buttons
  - `.badge-critical/high/medium/low/info` — severity badges
  - `.badge-stable/test` — status badges
  - `.cv-timeline`, `.cv-entry` — career timeline
  - `.skills-grid`, `.skill-card` — skills display
  - `.cert-grid`, `.cert-card` — certification badges
  - `.stats-row`, `.stat` — counter stats

## Content Guidelines

### Blog posts
- Always include: title, date, tags, categories, summary, author
- Use `categories` for broad grouping: "Detection Engineering", "Incident Response", "Research", "CTF"
- Use `tags` for specific tech: "sigma", "qradar", "elastic", "sysmon", "kql"
- Use `mitre_techniques` taxonomy for ATT&CK IDs: ["T1136.001"]

### Detection rules
- Follow the archetype template exactly
- Include: Sigma YAML, converted queries (SPL, KQL, AQL), testing notes, false positives, evasion considerations
- Always link to MITRE ATT&CK technique page
- Tag by tactic and data source

## Rules for Claude Code

1. **Never delete existing content** without explicit confirmation
2. **Always preview changes** with `hugo server` before committing
3. **Use the Makefile** for content creation — it ensures correct file paths and front matter
4. **Commit messages** should be descriptive: "new post: LSASS detection walkthrough" not "update"
5. **Custom CSS** goes in `assets/css/extended/custom.css` — never modify theme files
6. **Images** go in `static/images/` and reference as `/images/filename.png`
7. **When editing the config**, always run `hugo --minify` to verify the build passes
8. **PaperMod theme** is cloned in CI, not committed to the repo — don't add themes/ to git
