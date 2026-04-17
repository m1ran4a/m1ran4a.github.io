# ═══════════════════════════════════════════════
# Hugo Miranda — Site Maintenance
# Usage: make <target>
# ═══════════════════════════════════════════════

HUGO := hugo
BRANCH := main

# ── Preview ──────────────────────────────────────
.PHONY: serve
serve: ## Start local preview server (with drafts)
	$(HUGO) server -D --navigateToChanged

.PHONY: serve-prod
serve-prod: ## Start local preview server (production mode, no drafts)
	$(HUGO) server --navigateToChanged

# ── Content Creation ─────────────────────────────
.PHONY: post
post: ## Create a new blog post. Usage: make post TITLE="my-post-title"
	@test -n "$(TITLE)" || (echo "Error: TITLE is required. Usage: make post TITLE=\"my-post-title\"" && exit 1)
	$(HUGO) new blog/$(TITLE).md
	@echo ""
	@echo "✓ Created: content/blog/$(TITLE).md"
	@echo "  → Edit the file, set draft: false when ready"
	@echo "  → Preview: make serve"
	@echo "  → Publish: make publish MSG=\"new post: $(TITLE)\""

.PHONY: rule
rule: ## Create a new detection rule. Usage: make rule TITLE="my-rule-name"
	@test -n "$(TITLE)" || (echo "Error: TITLE is required. Usage: make rule TITLE=\"my-rule-name\"" && exit 1)
	$(HUGO) new detection-lab/$(TITLE).md
	@echo ""
	@echo "✓ Created: content/detection-lab/$(TITLE).md"
	@echo "  → Fill in the Sigma YAML and testing notes"
	@echo "  → Preview: make serve"
	@echo "  → Publish: make publish MSG=\"new rule: $(TITLE)\""

# ── Publishing ───────────────────────────────────
.PHONY: publish
publish: ## Build, commit, and push. Usage: make publish MSG="commit message"
	@test -n "$(MSG)" || (echo "Error: MSG is required. Usage: make publish MSG=\"your message\"" && exit 1)
	$(HUGO) --minify
	git add -A
	git commit -m "$(MSG)"
	git push origin $(BRANCH)
	@echo ""
	@echo "✓ Pushed to $(BRANCH). GitHub Actions will deploy in ~60s."
	@echo "  → Watch: https://github.com/m1ran4a/m1ran4a.github.io/actions"

.PHONY: quick
quick: ## Quick publish with auto-generated message
	$(HUGO) --minify
	git add -A
	git commit -m "content: update $$(date +%Y-%m-%d)"
	git push origin $(BRANCH)
	@echo "✓ Quick publish done."

# ── CV Management ────────────────────────────────
.PHONY: update-cv
update-cv: ## Replace CV PDF. Usage: make update-cv PDF="/path/to/new-cv.pdf"
	@test -n "$(PDF)" || (echo "Error: PDF path required. Usage: make update-cv PDF=\"/path/to/cv.pdf\"" && exit 1)
	@mkdir -p static/files
	cp "$(PDF)" static/files/Hugo_Miranda_CV.pdf
	@echo "✓ CV PDF updated. Run 'make publish MSG=\"update cv\"' to deploy."

# ── Drafts ───────────────────────────────────────
.PHONY: drafts
drafts: ## List all draft posts
	@echo "=== Draft Posts ==="
	@grep -rl "draft: true" content/ 2>/dev/null || echo "(none)"

.PHONY: undraft
undraft: ## Set a draft to published. Usage: make undraft FILE="content/blog/my-post.md"
	@test -n "$(FILE)" || (echo "Error: FILE is required." && exit 1)
	@sed -i 's/draft: true/draft: false/' "$(FILE)"
	@echo "✓ $(FILE) is now published (draft: false)"

# ── Build & Clean ────────────────────────────────
.PHONY: build
build: ## Build site for production
	$(HUGO) --minify

.PHONY: clean
clean: ## Remove generated files
	rm -rf public/ resources/_gen/

# ── Help ─────────────────────────────────────────
.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
