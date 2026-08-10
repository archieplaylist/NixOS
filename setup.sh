#!/usr/bin/env bash
# setup.sh — bootstrap a new machine from this flake-based NixOS config.
#
# Usage:
#   sudo ./setup.sh            interactive setup
#   sudo ./setup.sh --yes      noninteractive (answers yes to all prompts)
#   sudo ./setup.sh --help     show usage
#
# Steps (each is idempotent and non-destructive — skips when already done):
#   1.  preflight: repo layout + required tools
#   2.  OPTIONAL destructive: guided partitioning + formatting of a disk
#       (only offered on the installer ISO; refuses mounted disks; requires
#       typing the disk path and the word WIPE to confirm)
#   3.  user password: SHA-512 hash via openssl, written to
#       /etc/hashed-password on the target during the deploy step (read at
#       activation via `users.users.mario.hashedPasswordFile`); the hash is
#       never stored in the repo
#   4.  age key + secrets/.sops.yaml (from the .example template)
#   5.  empty encrypted secrets/secrets.yaml
#   6.  select host and rebuild via nixos-rebuild
#
# See README.md for details.
set -euo pipefail

# Require root — partitioning, nixos-rebuild, and age key creation all need it.
if [[ $EUID -ne 0 ]]; then
  echo "[error] setup.sh must be run as root (try: sudo ./setup.sh)" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_DIR="$REPO_ROOT/hosts"
AGE_DIR="${SOPS_AGE_DIR:-$HOME/.config/sops/age}"
AGE_KEY_PATH="$AGE_DIR/keys.txt"
SOPS_YAML_EXAMPLE="$REPO_ROOT/secrets/.sops.yaml.example"
SOPS_YAML="$REPO_ROOT/secrets/.sops.yaml"
SECRETS_FILE="$REPO_ROOT/secrets/secrets.yaml"

AN_YES_SET=0
# Password hash captured in step_password; written to /etc/hashed-password
# on the target by step_deploy (hosts/users.nix reads it via hashedPasswordFile).
PASSWORD_HASH=""

log()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m[error] %s\033[0m\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Ensure tools are on PATH — on NixOS systems, install via nix if missing.
# Maps tool names to their nixpkgs attribute for auto-install.
ensure_tools() {
  local missing=() pkgs=()
  for tool in "$@"; do
    if ! have "$tool"; then
      missing+=("$tool")
      case "$tool" in
        age|age-keygen) pkgs+=(nixpkgs#age) ;;
        sops)           pkgs+=(nixpkgs#sops) ;;
        openssl)        pkgs+=(nixpkgs#openssl) ;;
        *)              warn "don't know how to install '$tool' via nix"; continue ;;
      esac
    fi
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  have nix || { warn "nix not in PATH — install ${missing[*]} manually"; return 0; }

  # Deduplicate package list.
  local -a unique_pkgs
  mapfile -t unique_pkgs < <(printf '%s\n' "${pkgs[@]}" | sort -u)

  info "Installing ${missing[*]} via nix..."
  local out
  out="$(nix --extra-experimental-features "nix-command flakes" build --no-link --print-out-paths "${unique_pkgs[@]}" 2>/dev/null)" || true
  if [[ -n "$out" ]]; then
    local bins
    bins="$(echo "$out" | while IFS= read -r p; do [[ -d "$p/bin" ]] && echo "$p/bin" || true; done | tr '\n' ':')"
    export PATH="${bins}${PATH}"
    info "tools available"
  else
    warn "nix build failed — install ${missing[*]} manually"
  fi
}

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

  have nixos-rebuild || warn "'nixos-rebuild' is not in PATH (available after nixos-install)"
}

# ---------------------------------------------------------------------------
# Step 2 — OPTIONAL: guided partitioning (destructive!)
# ---------------------------------------------------------------------------
DISK_PATTERN='^(/dev/(sd|vd|hd)[a-z]|/dev/nvme[0-9]+n[0-9]+|/dev/mmcblk[0-9]+)$'

# Safe to partition only on the installer ISO: installed systems have a
# real root filesystem, the ISO boots from a squashfs-overlay/tmpfs.
is_installer_env() {
  local fs
  fs="$(findmnt -n -o FSTYPE / || true)"
  [[ "$fs" == "squashfs" || "$fs" == "overlay" || "$fs" == "tmpfs" ]]
}

disk_is_mounted() {
  local d="$1" p
  for p in "${d}p1" "${d}p2" "${d}1" "${d}2" "${d}"; do
    findmnt -n -S "$p" >/dev/null 2>&1 && return 0
  done
  return 1
}

step_partition() {
  log "Partition & format (optional, DESTRUCTIVE)"

  if ! is_installer_env; then
    info "not on the installer ISO (root is a real filesystem) — skipping"
    info "on a fresh install, boot the NixOS installer ISO and run setup.sh from there"
    return 0
  fi

  if ! confirm "Partition and format a disk? This ERASES all data on it"; then
    info "skipped — make sure hosts/*.nix point at real disks before deploying"
    return 0
  fi

  local missing=()
  for t in sgdisk mkfs.vfat mkfs.xfs; do
    have "$t" || missing+=("$t")
  done
  [[ ${#missing[@]} -eq 0 ]] || die "missing partition tools: ${missing[*]} — run setup.sh from the NixOS installer ISO (nix shell nixpkgs#gptfdisk nixpkgs#dosfstools nixpkgs#xfsprogs)"

  echo
  echo "Available disks:"
  lsblk -dno NAME,SIZE,MODEL | awk '{printf "  /dev/%s  %s  %s\n", $1, $2, ($3?$3:"")}'

  local disk
  while :; do
    if ! read -r -p "  type the full device path to wipe (e.g. /dev/sda): " disk; then
      info "no input — aborting partition step"
      return 0
    fi
    [[ -n "$disk" ]] || continue
    [[ "$disk" =~ $DISK_PATTERN ]] || { warn "invalid device path: $disk"; continue; }
    [[ -b "$disk" ]] || { warn "not a block device: $disk"; continue; }
    if disk_is_mounted "$disk"; then
      warn "disk $disk has mounted partitions — refusing to wipe it"
      continue
    fi
    break
  done

  echo
  warn "ABOUT TO ERASE ALL DATA ON: $disk"
  echo "  partition 1: ESP   1 GiB  vfat label 'nixos-boot'"
  echo "  partition 2: root  rest  xfs  label 'nixos-root'"
  if ! read -r -p "  type WIPE (exactly) to continue: " ans; then
    echo "no input — aborting partition step"
    return 0
  fi
  [[ "$ans" == "WIPE" ]] || { info "aborted — nothing was changed"; return 0; }

  # Partition device naming: nvme/mmcblk get a trailing "p".
  local p1 p2 pfx=""
  [[ "$disk" =~ /dev/(nvme|mmcblk) ]] && pfx="p"
  p1="${disk}${pfx}1"
  p2="${disk}${pfx}2"

  sgdisk --zap-all "$disk"
  sgdisk -n 1:0:+1G -t 1:ef00 -c 1:nixos-boot "$disk"
  sgdisk -n 2:0:0  -t 2:8300 -c 2:nixos-root "$disk"
  udevadm settle || true
  partprobe "$disk" || true
  sleep 1

  mkfs.vfat -F 32 -n nixos-boot "$p1"

  # XFS layout: one filesystem for / (label nixos-root). The nix store and
  # all system/user state live on it directly — no subvolumes, no /persist.
  mkfs.xfs -f -L nixos-root "$p2"

  # Make udev create /dev/disk/by-label symlinks for the fresh filesystems.
  # udev can lag behind right after mkfs; without this the by-label mounts
  # in step_deploy fail with "... does not exist".
  udevadm settle || true
  udevadm trigger --subsystem-match=block || true
  udevadm settle || true

  info "done: $p1 (ESP, label nixos-boot) + $p2 (xfs, label nixos-root)"
}

# ---------------------------------------------------------------------------
# Step 3 — user password (hash only, kept in PASSWORD_HASH)
# The hash is written on the system at /etc/hashed-password by step_deploy
# (read at activation by `users.users.mario.hashedPasswordFile`).
# ---------------------------------------------------------------------------
step_password() {
  log "User password (mario)"

  if ! confirm "Set/update the password for user 'mario'?"; then
    info "skipped — no password will be set (provision it manually later)"
    return 0
  fi

  have openssl || { warn "openssl not found — cannot hash a password"; return 1; }

  local p1 p2 hash
  while :; do
    if ! read -r -s -p "  new password for mario: " p1; then
      echo
      info "no input — aborting password step"
      return 0
    fi
    echo
    if ! read -r -s -p "  repeat password:        " p2; then
      echo
      info "no input — aborting password step"
      return 0
    fi
    echo
    [[ -n "$p1" ]] || { warn "empty password not allowed — try again"; continue; }
    [[ "$p1" == "$p2" ]] || { warn "passwords do not match — try again"; continue; }
    break
  done
  unset p2

  # SHA-512 crypt via openssl (present on the installer ISO). Prefer -stdin
  # so the password never shows up in the process list.
  if printf '%s' "$p1" | openssl passwd -6 -stdin >/dev/null 2>&1; then
    hash="$(printf '%s' "$p1" | openssl passwd -6 -stdin)"
  else
    warn "openssl -stdin unsupported, falling back to argument passing"
    hash="$(openssl passwd -6 "$p1")"
  fi
  unset p1
  [[ -n "$hash" ]] || { warn "openssl failed to hash the password"; return 1; }

  # Keep only the hash in memory; step_deploy writes it to the machine at
  # /etc/hashed-password (hosts/users.nix reads it via hashedPasswordFile).
  # It never touches git-tracked files.
  PASSWORD_HASH="$hash"
  info "password hash ready — it will be written to /etc/hashed-password during deploy"
}

# ---------------------------------------------------------------------------
# Step 4 — age key + sops.yaml
# ---------------------------------------------------------------------------
step_age() {
  log "Age key & sops"

  if [[ ! -f "$AGE_KEY_PATH" ]]; then
    if confirm "Generate a new age key at $AGE_KEY_PATH?"; then
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
# Step 4 — secrets file
# ---------------------------------------------------------------------------
step_secrets() {
  log "secrets/secrets.yaml"

  [[ -f "$SECRETS_FILE" ]] && { info "encrypted secrets file already exists"; return 0; }

  # sops needs a valid .sops.yaml with a real age key (not the placeholder).
  if [[ ! -f "$SOPS_YAML" ]]; then
    warn "secrets/.sops.yaml not found — run step_age first or create it manually"
    return 0
  fi
  if grep -q 'age1REPLACEME' "$SOPS_YAML"; then
    warn "secrets/.sops.yaml still has the placeholder key — edit it with your real age key first"
    return 0
  fi

  if confirm "Create an initial encrypted secrets/secrets.yaml?"; then
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

    # libgit2 refuses repos not owned by the current user (root on installer).
    git config --global --add safe.directory "$REPO_ROOT"

    if is_installer_env; then
      # Installer ISO: install to the target disk (not the running tmpfs).
      # Mount by filesystem label (created by step_partition); the target
      # isn't mounted yet, so by-label (not by-uuid) is used. XFS target:
      # plain mount of the root partition at /mnt.
      local rootdev="/dev/disk/by-label/nixos-root"
      [[ -e "$rootdev" ]] || rootdev="$(blkid -L nixos-root 2>/dev/null || true)"
      [[ -n "$rootdev" && -e "$rootdev" ]] || { warn "no device with label 'nixos-root' found — run the partition step or create the labels manually, then run: nixos-install --flake .#$name"; return 1; }

      info "mounting $rootdev at /mnt (XFS layout)"
      mount "$rootdev" /mnt
      mkdir -p /mnt/boot
      local bootdev="/dev/disk/by-label/nixos-boot"
      [[ -e "$bootdev" ]] || bootdev="$(blkid -L nixos-boot 2>/dev/null || true)"
      if [[ -n "$bootdev" && -e "$bootdev" ]]; then
        info "mounting $bootdev at /mnt/boot"
        # Mask so /boot (vfat) is root-only; avoids the systemd-boot
        # "world accessible ... security hole" warning during install.
        mount -o fmask=0077,dmask=0077 "$bootdev" /mnt/boot
      fi

      # Copy the flake into the target — including dotfiles (.git, .gitignore,
      # secrets/.sops.yaml*). Copying without .git makes the target a plain path
      # flake whose NAR hash changes whenever the lock file is updated, which
      # breaks nixos-install with "NAR hash mismatch in input path:...".
      mkdir -p /mnt/etc/nixos
      cp -r "$REPO_ROOT"/. /mnt/etc/nixos/

      # Provision the user's hashed password into the target. users.nix
      # reads it at activation via `hashedPasswordFile`, so the hash must
      # live on the installed filesystem, not in the flake.
      if [[ -n "$PASSWORD_HASH" ]]; then
        install -d /mnt/etc
        printf '%s\n' "$PASSWORD_HASH" > /mnt/etc/hashed-password
        chmod 600 /mnt/etc/hashed-password
        info "wrote /mnt/etc/hashed-password"
      else
        info "no password hash captured — set one later with \`sudo passwd mario\`"
      fi

      # Provision the sops age key into the target. modules/system/secrets.nix
      # expects it at /root/.config/sops/age on the installed system. Without
      # this the first boot would generate a fresh key that doesn't match
      # secrets/.sops.yaml and sops activation would fail.
      if [[ -f "$AGE_KEY_PATH" ]]; then
        install -d -m 700 /mnt/root/.config/sops/age
        install -m 600 "$AGE_KEY_PATH" /mnt/root/.config/sops/age/keys.txt
        info "copied age key to /mnt/root/.config/sops/age/keys.txt"
      else
        warn "no age key found — first boot will fail / skip sops decryption"
      fi

      info "-> nixos-install for '$name'"
      nixos-install --flake "/mnt/etc/nixos#$name" --no-root-passwd
      info "install done — reboot into '$name' (mario's password was set during setup)"
    else
      # Already on the installed system.
      if [[ -n "$PASSWORD_HASH" ]]; then
        install -d /etc
        printf '%s\n' "$PASSWORD_HASH" > /etc/hashed-password
        chmod 600 /etc/hashed-password
        info "wrote /etc/hashed-password"
      fi
      info "-> nixos-rebuild for '$name'"
      sudo nixos-rebuild switch --flake ".#$name"
    fi
  else
    if is_installer_env; then
      info "deploy skipped — to install later, run:"
      info "  sudo nixos-install --flake .#<host>"
    else
      info "deploy skipped — rebuild later with:"
      info "  sudo nixos-rebuild switch --flake .#<host>"
    fi
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
step_partition
ensure_tools openssl
step_password
ensure_tools age age-keygen sops
step_age
step_secrets
step_deploy

log "All done."
warn "Password hash lives in /etc/hashed-password on the system (never in the repo)."