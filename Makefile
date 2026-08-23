# Day-to-day commands for this flake (nh-only).
#   make help                list all targets
#   make check               build every host config (nix flake check)
#   make switch HOST=<host>  rebuild + activate (default: desktop)
HOST ?= desktop

.PHONY: help check fmt fmt-check hooks build boot switch clean update develop

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' Makefile | sed 's/:.*##/:/' | sort

check: ## Build every host config (`nix flake check`)
	nix flake check

fmt: ## Reformat all Nix files (`nix fmt`)
	nix fmt

fmt-check: ## Fail if `nix fmt` would change anything
	@nix fmt
	@git diff --quiet --exit-code \
		|| { echo "error: nix fmt would change files — run 'make fmt' first"; exit 1; }

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

update: ## Refresh flake inputs (nixpkgs, home-manager, sops-nix, nix-flatpak)
	nix flake update

develop: ## Enter a shell with the formatter and Nix linters
	nix develop