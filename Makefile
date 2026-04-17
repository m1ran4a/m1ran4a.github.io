HUGO := /tmp/hugo

.PHONY: serve build new-post new-rule help

help:
	@echo "Available commands:"
	@echo "  make serve       Start local dev server (drafts visible)"
	@echo "  make build       Production build to public/"
	@echo "  make new-post    Create a new blog post"
	@echo "  make new-rule    Create a new detection rule"

serve:
	$(HUGO) server -D --disableFastRender

build:
	$(HUGO) --minify

new-post:
	@printf "Post title: "; read title; \
	slug=$$(printf '%s' "$$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'); \
	$(HUGO) new blog/$$slug.md && \
	echo "→ Edit content/blog/$$slug.md — set draft: false when ready"

new-rule:
	@printf "Rule title: "; read title; \
	slug=$$(printf '%s' "$$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-'); \
	$(HUGO) new detection-lab/$$slug.md && \
	echo "→ Edit content/detection-lab/$$slug.md — set draft: false when ready"
