#!/usr/bin/env bash
# setup.sh — bootstrap a new machine from this flake-based NixOS config.
#
# Usage:
#   ./setup.sh            interactive setup
#   ./setup.sh --yes      noninteractive (answers yes to all prompts)
#   ./setup.sh --help     show usage
#
# Steps (each is idempotent and non-destructive — skips when already done):
#   1.  preflight: repo layout + required tools
#   2.  age key + secrets/.sops.yaml (from the .example template)
#   3.  empty encrypted secrets/secrets.yaml
#   4.  auto-fill real disk UUIDs for / and /boot in hosts/*.nix
#   5.  select host and rebuild via nixos-rebuild
#
# Manual steps still required: partitioning/formatting disks, setting the
# user password. See README.md.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_DIR="$REPO_ROOT/hosts"
AGE_DIR="${SOPS_AGE_DIR:-$HOME/.config/sops/age}"
AGE_KEY_PATH="$AGE_DIR/keys.txt"
SOPS_YAML_EXAMPLE="$REPO_ROOT/secrets/.sops.yaml.example"
SOPS_YAML="$REPO_ROOT/secrets/.sops.yaml"
SECRETS_FILE="$REPO_ROOT/secrets/secrets.yaml"

AN_YES_SET=0

log()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m[error] %s\033[0m\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  sed -n '3,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

confirm() {
  # confirm "prompt" -> 0 on yes, 1 on no. --yes always returns 0.
  [[ $AN_YES_SET -eq 1 ]] && { echo "[yes] $1"; return 0; }
  local answer
  while :; do
    read -r -p "$1 [y/N] " answer
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO|"") return 1 ;;
      *) echo "please answer yes or no" ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Step 1 — preflight
# ---------------------------------------------------------------------------
preflight() {
  log "Preflight"

  [[ -f "$REPO_ROOT/flake.nix" ]] \
    || die "flake.nix not found — run setup.sh from the repo root"

  have lsblk || die "lsblk not found in PATH"

  mapfile -t HOSTS < <(find "$HOSTS_DIR" -maxdepth 1 -name '*.nix' ! -name '.*' -printf '%f\n' 2>/dev/null | sort)
  [[ ${#HOSTS[@]} -gt 0 ]] || die "no host configs (*.nix) found in hosts/"

  info "repo: $REPO_ROOT"
  info "hosts: ${HOSTS[*]}"

  for tool in age age-keygen sops nixos-rebuild; do
    have "$tool" || warn "'$tool' is not in PATH (needed for install tooling: nix shell nixpkgs#<tool>)"
  done
}

# ---------------------------------------------------------------------------
# Step 2 — age key + sops.yaml
# ---------------------------------------------------------------------------
step_age() {
  log "Age key & sops"

  if [[ ! -f "$AGE_KEY_PATH" ]]; then
    if confirm "Generate a new age key at $AGE_KEY_PATH?"; then
      have age-keygen || die "age-keygen is not installed (try: nix shell nixpkgs#age -c age-keygen)"
      mkdir -p "$(dirname "$AGE_KEY_PATH")"
      age-keygen -o "$AGE_KEY_PATH"
      chmod 600 "$AGE_KEY_PATH"
      info "wrote $AGE_KEY_PATH"
    else
      warn "age key not created — sops-encrypted secrets will be unavailable"
    fi
  else
    info "age key already exists at $AGE_KEY_PATH"
  fi

  # Public key lives in the "public key:" comment line of the keys file.
  PUBKEY=""
  [[ -f "$AGE_KEY_PATH" ]] && PUBKEY="$(grep -oE 'age1[A-Za-z0-9]+' "$AGE_KEY_PATH" | head -1 || true)"

  if [[ -f "$SOPS_YAML" ]]; then
    info "secrets/.sops.yaml already exists"
  elif [[ -f "$SOPS_YAML_EXAMPLE" ]]; then
    if confirm "Create secrets/.sops.yaml from the example?"; then
      if [[ -n "$PUBKEY" ]]; then
        sed "s/age1REPLACEME\.\.\./$PUBKEY/" \
          "$SOPS_YAML_EXAMPLE" > "$SOPS_YAML"
        info "sops.yaml written with public key $PUBKEY"
      else
        cp "$SOPS_YAML_EXAMPLE" "$SOPS_YAML"
        info "sops.yaml written (placeholder kept — no age key found; edit secrets/.sops.yaml)"
      fi
    else
      warn "sops.yaml skipped"
    fi
  else
    warn "missing template secrets/.sops.yaml.example — skipping"
  fi
}

# ---------------------------------------------------------------------------
# Step 3 — secrets file
# ---------------------------------------------------------------------------
step_secrets() {
  log "secrets/secrets.yaml"

  [[ -f "$SECRETS_FILE" ]] && { info "encrypted secrets file already exists"; return 0; }

  if confirm "Create an initial encrypted secrets/secrets.yaml?"; then
    have sops || { warn "sops is not installed — can't create the file now"; return 1; }
    # An empty sops file needs at least a comment to store something.
    local tmp
    tmp="$(mktemp)"
    printf '# secrets.yaml\n# key: value\n' > "$tmp"
    if sops -i -e "$tmp"; then
      cp "$tmp" "$SECRETS_FILE"
      info "created encrypted $SECRETS_FILE (edit with: sops $SECRETS_FILE)"
    else
      warn "sops encryption failed — secrets file not created"
    fi
    rm -f "$tmp"
  else
    warn "secrets file skipped"
  fi
}

# ---------------------------------------------------------------------------
# Step 4 — disk UUIDs
# ---------------------------------------------------------------------------
uuid_of() {
  # uuid_of /  ->  the UUID of the filesystem mounted at /
  lsblk -nro UUID,MOUNTPOINTS | awk -v m="$1" '$2==m { print $1; exit }'
}

step_uuids() {
  log "Auto-fill disk UUIDs in hosts/*.nix"

  local root_uuid boot_uuid
  root_uuid="$(uuid_of / || true)"
  boot_uuid="$(uuid_of /boot || true)"
  info "root  /     uuid: ${root_uuid:-<not found>}"
  info "boot  /boot uuid: ${boot_uuid:-<not found>}"

  local name f
  for name in "${HOSTS[@]}"; do
    f="$HOSTS_DIR/$name"
    # Root placeholder is a unique fake UUID; boot placeholder only occurs
    # right after "by-uuid/" (the root placeholder has no such prefix).
    [[ -n "$root_uuid" ]] \
      && sed -i "s|/00000000-0000-0000-0000-000000000000|/$root_uuid|g" "$f"
    [[ -n "$boot_uuid" ]] \
      && sed -i "s|/0000-0000|/$boot_uuid|g" "$f"
    if grep -qE '00000000-0000-0000-0000-000000000000|/0000-0000' "$f"; then
      warn "$name still contains placeholder UUIDs (is this machine booted into the target disks?)"
    else
      info "$name: UUIDs set"
    fi
  done
}

# ---------------------------------------------------------------------------
# Step 5 — deploy
# ---------------------------------------------------------------------------
step_deploy() {
  log "Deploy"

  echo "Available hosts:"
  local i
  for i in "${!HOSTS[@]}"; do
    printf '  %d) %s\n' "$((i + 1))" "${HOSTS[$i]%.nix}"
  done

  if confirm "Rebuild the system now?"; then
    local choice name
    if [[ $AN_YES_SET -eq 1 ]]; then
      choice=1
    else
      read -r -p "  pick a host [1]: " choice
    fi
    [[ -z "$choice" ]] && choice=1
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#HOSTS[@]})); then
      die "invalid host number: $choice"
    fi
    name="${HOSTS[$((choice - 1))]%.nix}"
    info "-> nixos-rebuild for '$name'"
    sudo nixos-rebuild switch --flake ".#$name"
  else
    info "deploy skipped — rebuild later with:"
    info "  sudo nixos-rebuild switch --flake .#<host>"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -y|--yes) AN_YES_SET=1 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

preflight
step_age
step_secrets
step_uuids
step_deploy

log "All done."
warn "Reminder: set a real password with 'passwd' (initial is 'changeme')."