# Day-to-day commands for this flake.
#   make help                list all targets
#   make check               build every host config (nix flake check)
#   make rebuild HOST=<host> rebuild a specific host (default: nixos-desktop)
HOST ?= nixos-desktop

.PHONY: help check fmt fmt-check hooks build rebuild update develop

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

build: ## Build the host config without activating (HOST=...)
	sudo nixos-rebuild build --flake .#$(HOST)

rebuild: ## Build and activate the host config (HOST=...)
	sudo nixos-rebuild switch --flake .#$(HOST)

update: ## Refresh flake inputs (nixpkgs, home-manager, sops-nix, nix-flatpak)
	nix flake update

develop: ## Enter a shell with the formatter and Nix linters
	nix develop