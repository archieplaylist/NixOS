# Day-to-day commands for this flake (nh-only).
#   make help                list all targets
#   make check               build every host config (nix flake check)
#   make switch HOST=<host>  rebuild + activate (default: auto-detected from hostname)
# Flake attrs (desktop/laptop/vm/work) differ from system hostnames, so the
# default HOST is resolved by matching `hostname` against mySystem.hostname in
# modules/hosts/*.nix — same lookup as the switch-de script. Override with HOST=...
DETECTED_HOST := $(shell grep -lE 'mySystem\.hostname *= *"$(shell hostname)"' modules/hosts/*.nix 2>/dev/null | head -1 | xargs -r basename 2>/dev/null | sed 's/\.nix$$//')
HOST ?= $(if $(DETECTED_HOST),$(DETECTED_HOST),work)

.PHONY: help check test fmt fmt-check hooks build boot switch clean update develop update-opencode update-all

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' Makefile | sed 's/:.*##/:/' | sort

check: ## Build every host config (`nix flake check`)
	bash tests/state.sh
	nix flake check

test: ## Run lightweight shell regression tests
	bash tests/state.sh

fmt: ## Reformat all Nix files (`nix fmt`)
	nix fmt

fmt-check: ## Fail if fmt/lint drifts or dead code is found (no mutation)
	nix develop --command bash -c "nixpkgs-fmt --check . && deadnix --fail . && statix check ."

hooks: ## Install the repo's git hooks (core.hooksPath -> .githooks, once per clone)
	git config core.hooksPath .githooks

build: ## Build without activating (HOST=...) — nh
	nh os build . -H $(HOST)

boot: ## Build + set as next boot (HOST=...)
	nh os boot . -H $(HOST)

switch: ## Build + activate now (HOST=...)
	nh os switch . -H $(HOST)

clean: ## Garbage collect (nh clean all)
	nh clean all

update: ## Refresh flake inputs
	nix flake update

update-opencode: ## Bump opencode to the latest 2.x npm release (version + hash)
	nix develop --command nix-update --flake opencode

update-all: ## Bump all overlay packages (opencode, mactahoe-icons, simple-taskbar)
	nix develop --command bash -c "nix-update --flake opencode && nix-update --flake mactahoe-icons && nix-update --flake simple-taskbar"

develop: ## Enter a shell with the formatter and Nix linters
	nix develop
