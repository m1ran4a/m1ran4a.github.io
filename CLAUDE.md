# Site Maintenance Guide

Hugo static site at **https://m1ran4a.github.io**  
Theme: PaperMod | Active branch: `claude/migrate-to-hugo-E7N49`

## Local Development

```sh
make serve      # dev server at http://localhost:1313 (drafts visible)
make build      # production build → public/
```

Hugo binary lives at `/tmp/hugo` (v0.147.0 extended). The system apt version is too old.

---

## Publishing a Blog Post

```sh
make new-post
# → Enter title when prompted
# → File created at content/blog/<slug>.md
```

Then edit the file:
1. Fill in `summary` (1–2 sentence description shown in the list)
2. Add `tags`, `categories`, and `mitre_techniques` (if applicable)
3. Write content in Markdown below the `---`
4. Change `draft: false` when ready to publish
5. `git add content/blog/<slug>.md && git commit -m "post: <title>" && git push`

GitHub Actions deploys automatically on push.

### Blog post front matter reference

```yaml
---
title: "Your Post Title"
date: 2026-04-17
draft: false
author: "Hugo Miranda"
summary: "One-sentence summary shown in the post list."
tags: [detection-engineering, sigma, mitre-attack]
categories: [Detection Research]
mitre_techniques: [T1136.001]
---
```

---

## Adding a Detection Rule

```sh
make new-rule
# → Enter rule title when prompted
# → File created at content/detection-lab/<slug>.md
```

Fill in the front matter fields:

| Field | Example |
|---|---|
| `mitre_technique` | `T1136.001` |
| `mitre_tactic` | `Persistence` |
| `technique_name` | `Local Account — Create` |
| `severity` | `critical` / `high` / `medium` / `low` / `info` |
| `status` | `stable` / `test` / `experimental` |
| `logsource` | `Windows Security Events` |
| `sigma` | multi-line YAML Sigma rule (use `\|` block scalar) |
| `converted_queries` | list of `{platform, language, query}` objects |

Set `draft: false` and push.

---

## Updating the CV

Edit **`content/cv.md`** — all data is YAML front matter, no HTML needed.

- **Add a job**: append to `experience[]` with `company`, `role`, `period`, `bullets[]`
- **Mark current role**: add `current: true` → renders a glowing blue dot
- **Add a cert**: append to `certifications[]` with `status: active` or `status: in-progress`
- **Update skills**: edit `skills[]` groups and `items[]` chips
- **Upload PDF**: place the file at `static/files/Hugo_Miranda_CV.pdf` (referenced by `pdf:` front matter key)

---

## Updating the Home Page

**Bio text**: edit `config.yml` → `params.homeInfoParams.Content`

**Stats bar numbers** (years, log sources, etc.): edit `layouts/partials/home_info.html` — the `.hs-n` spans

**Availability badge**: edit the text inside `hero-availability` div in `layouts/partials/home_info.html`

**Social links**: edit `config.yml` → `params.socialIcons`

---

## Updating the About Page

Edit `content/about.md` directly. The page uses inline HTML (goldmark unsafe mode is on) so you can mix Markdown and HTML freely.

---

## Site Structure

```
content/
  _index.md               home page description
  about.md                About page (inline HTML + Markdown)
  cv.md                   CV — all data in YAML front matter
  blog/
    _index.md             Blog section header
    <slug>.md             Blog posts
  detection-lab/
    _index.md             Detection Lab section header
    <slug>.md             Detection rules

layouts/
  partials/
    home_info.html        Hero section (availability badge, stats, CTAs)
    extend_head.html      Extra <head> tags, hero CSS, OG image fallback
    footer.html           Site footer
  blog/
    list.html             Blog post list with tag/category filters
  detection-lab/
    list.html             Rule catalog with tactic filter + stats
    single.html           Individual rule page (Sigma + queries)
  page/
    cv.html               CV layout (renders front matter data)
  mitre_techniques/
    term.html             Per-technique taxonomy page
  404.html                Custom 404 page

assets/css/extended/
  custom.css              Dark palette, hover effects, animations
  syntax.css              Monokai syntax highlighting (generated)

static/
  favicon.svg             HM monogram
  files/                  Place Hugo_Miranda_CV.pdf here
  images/                 Place og-default.png (1200×630) here

archetypes/
  blog.md                 Template for new blog posts
  detection-lab.md        Template for new detection rules

config.yml                All site settings, nav, social links
Makefile                  Maintenance commands
```

---

## Deployment

Push to `claude/migrate-to-hugo-E7N49` → GitHub Actions builds and deploys.  
Merge the PR to `main` to deploy to production.  
Pages source must be set to **GitHub Actions** in repo Settings → Pages.

## Outstanding TODOs

- [ ] Upload `Hugo_Miranda_CV.pdf` to `static/files/`
- [ ] Create `static/images/og-default.png` (1200×630 px) for social sharing previews
- [ ] Set `draft: false` on blog posts when ready to publish
