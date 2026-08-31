#!/usr/bin/env bash
# setup.sh — bootstrap a new machine from this flake-based NixOS config.
#
# Usage:
#   sudo ./setup.sh                  interactive setup
#   sudo ./setup.sh --yes            noninteractive (answers yes to all prompts except
#                                    destructive disk wipe — disk path + WIPE still required)
#   sudo ./setup.sh --luks           also LUKS2-encrypt the root partition (prompts for passphrase;
#                                    use --yes + LUKS_PASSPHRASE env for noninteractive)
#   sudo ./setup.sh --luks --tpm2    enroll TPM2 auto-unlock after luksFormat (requires --luks + TPM2 hw)
#   sudo ./setup.sh --secure-boot    hint that Secure Boot (lanzaboote) still needs manual
#                                    `sbctl` enrollment after first boot (works with or without --luks)
#   sudo ./setup.sh --help           show usage
#
# Required tools are assumed present (run from the NixOS installer ISO, or under
# `nix shell nixpkgs#age nixpkgs#sops nixpkgs#openssl nixpkgs#cryptsetup
# nixpkgs#systemd nixpkgs#newt nixpkgs#gptfdisk nixpkgs#dosfstools
# nixpkgs#xfsprogs` on any other NixOS).
#
# Steps (each is idempotent and non-destructive — skips when already done):
#   1.  preflight: repo layout + required tools
#   2.  OPTIONAL destructive: guided partitioning + formatting of a disk
#       (only offered on the installer ISO; refuses mounted disks; requires
#       typing the disk path and the word WIPE to confirm). Pass --luks to
#       wrap the root partition in LUKS2 (label nixos-root-luks → mapper cryptroot).
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
HOSTS_DIR="$REPO_ROOT/modules/hosts"
# Age key location: honour SOPS_AGE_DIR if set, otherwise use /root's home
# when running as root (sudo) so it matches modules/features/secrets.nix
# keyFile = "/root/.config/sops/age/keys.txt" regardless of $HOME preservation.
if [[ -n "${SOPS_AGE_DIR:-}" ]]; then
  AGE_DIR="$SOPS_AGE_DIR"
elif [[ $EUID -eq 0 ]]; then
  AGE_DIR="/root/.config/sops/age"
else
  AGE_DIR="$HOME/.config/sops/age"
fi
AGE_KEY_PATH="$AGE_DIR/keys.txt"
SOPS_YAML_EXAMPLE="$REPO_ROOT/secrets/.sops.yaml.example"
SOPS_YAML="$REPO_ROOT/secrets/.sops.yaml"
SECRETS_FILE="$REPO_ROOT/secrets/secrets.yaml"

AN_YES_SET=0
# LUKS flags: --luks / --tpm2 / --secure-boot; LUKS_PASSPHRASE env for --yes noninteractive.
ENABLE_LUKS=0
ENABLE_TPM2=0
ENABLE_SECURE_BOOT=0
LUKS_PASSPHRASE=""
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
        cryptsetup)     pkgs+=(nixpkgs#cryptsetup) ;;
        systemd-cryptenroll) pkgs+=(nixpkgs#systemd) ;;
        whiptail|newt)  pkgs+=(nixpkgs#newt) ;;
        sgdisk|gdisk)   pkgs+=(nixpkgs#gptfdisk) ;;
        mkfs.vfat|dosfslabel) pkgs+=(nixpkgs#dosfstools) ;;
        mkfs.xfs|xfs_db) pkgs+=(nixpkgs#xfsprogs) ;;
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

# ponytail: TUI flag is computed lazily (after ensure_tools may have
# installed whiptail). --yes / NONINTERACTIVE / no-tty -> plain read.
USE_TUI() {
  [[ -t 1 && -z "${NONINTERACTIVE:-}" && $AN_YES_SET -eq 0 ]] \
    && command -v whiptail >/dev/null 2>&1
}
ask() {
  # Menu form: -m <prompt> <items...> <default>
  # Items are alternating tag/item pairs (whiptail convention). The fallback
  # branch iterates *only the items* (every other arg) — see bugfix note in
  # step_deploy: a plain `for tag; do` over the full list printed both halves.
  if [[ $1 == "-m" ]]; then
    local prompt="$2"; shift 2
    local default="${@: -1}"; set -- "${@:1:$#-1}"
    if USE_TUI; then
      whiptail --title "Pick" --menu "$prompt" 20 70 "$(( $# / 2 ))" \
        --default-item "$default" "$@" 3>&1 1>&2 2>&3
    else
      echo "$prompt" >&2
      local i=0
      # step by 2 over the pair list, print only the item half.
      while [[ $# -gt 0 ]]; do
        local tag="$1" item="$2"; shift 2
        printf '  %s) %s\n' "$tag" "$item" >&2
      done
      local ans; read -r -p "pick [$default]: " ans || return 1
      printf '%s' "${ans:-$default}"
    fi
    return $?
  fi
  # Password form: -s <prompt>
  if [[ $1 == "-s" ]]; then
    if USE_TUI; then
      whiptail --title "Password" --passwordbox "$2" 10 70 3>&1 1>&2 2>&3
    else
      local ans; read -r -s -p "$2: " ans || return 1; echo >&2
      printf '%s' "$ans"
    fi
    return $?
  fi
  # Plain input form: passthrough to whiptail if TUI, else read.
  if USE_TUI; then
    whiptail "$@" 3>&1 1>&2 2>&3
  else
    local ans
    read -r -p "${@: -1}: " ans || return 1
    printf '%s' "$ans"
  fi
}

confirm() {
  # confirm "prompt" -> 0 on yes, 1 on no. --yes always returns 0.
  [[ $AN_YES_SET -eq 1 ]] && { echo "[yes] $1" >&2; return 0; }
  if USE_TUI; then
    whiptail --title "Confirm" --yesno "$1" 10 70 3>&1 1>&2 2>&3
  else
    local answer
    while :; do
      read -r -p "$1 [y/N] " answer
      case "$answer" in
        y|Y|yes|YES) return 0 ;;
        n|N|no|NO|"") return 1 ;;
        *) echo "please answer yes or no" ;;
      esac
    done
  fi
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
  [[ ${#HOSTS[@]} -gt 0 ]] || die "no host configs (*.nix) found in modules/hosts/"

  info "repo: $REPO_ROOT"
  info "hosts: ${HOSTS[*]}"

  # Install whiptail up-front so USE_TUI() can detect it before the first prompt.
  ensure_tools whiptail

  have nixos-rebuild || warn "'nixos-rebuild' is not in PATH (available after nixos-install)"
}

# ---------------------------------------------------------------------------
# Step 2 — OPTIONAL: guided partitioning (destructive!)
# ---------------------------------------------------------------------------
# Allow multi-letter sd/vd/hd devices (sdaa+ on large arrays / virtual disks beyond sdz);
# nvme/mmcblk partition suffix 'p' is handled via pfx logic below (p1/p2 vs 1/2).
DISK_PATTERN='^(/dev/(sd|vd|hd)[a-z]+|/dev/nvme[0-9]+n[0-9]+|/dev/mmcblk[0-9]+)$'

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
    info "skipped — make sure modules/hosts/*.nix point at real disks before deploying"
    return 0
  fi

  ensure_tools sgdisk mkfs.vfat mkfs.xfs cryptsetup systemd-cryptenroll partprobe udevadm lsblk

  echo
  echo "Available disks:"
  lsblk -dno NAME,SIZE,MODEL | awk '{printf "  /dev/%s  %s  %s\n", $1, $2, ($3?$3:"")}'

  local disk
  while :; do
    disk="$(ask --title "Disk selection" --inputbox "Type the full device path to wipe (e.g. /dev/sda)" 10 70 "")" || {
      info "no input — aborting partition step"
      return 0
    }
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
  if [[ $ENABLE_LUKS -eq 1 ]]; then
    echo "  partition 2: root  rest  LUKS2 label 'nixos-root-luks' -> XFS inside (label 'nixos-root')"
  else
    echo "  partition 2: root  rest  xfs  label 'nixos-root'"
  fi
  ans="$(ask --title "Confirm destructive wipe" --inputbox "Type WIPE (exactly) to continue erasing $disk" 10 70 "")" || {
    info "no input — aborting partition step"
    return 0
  }
  [[ "$ans" == "WIPE" ]] || { info "aborted — nothing was changed"; return 0; }

  # Partition device naming: nvme/mmcblk get a trailing "p".
  local p1 p2 pfx=""
  [[ "$disk" =~ /dev/(nvme|mmcblk) ]] && pfx="p"
  p1="${disk}${pfx}1"
  p2="${disk}${pfx}2"

  sgdisk --zap-all "$disk"
  sgdisk -n 1:0:+1G -t 1:ef00 -c 1:nixos-boot "$disk"
  sgdisk -n 2:0:0  -t 2:8300 -c 2:nixos-root "$disk"
  partprobe "$disk" || true
  udevadm settle --timeout=10

  mkfs.vfat -F 32 -n nixos-boot "$p1"

  local luks_pw=""
  if [[ $ENABLE_LUKS -eq 1 ]]; then
    if [[ -n "${LUKS_PASSPHRASE:-}" ]]; then
      luks_pw="$LUKS_PASSPHRASE"
    elif [[ $AN_YES_SET -eq 1 ]]; then
      die "--yes mode requires LUKS_PASSPHRASE env for --luks"
    else
      while :; do
        local pw1 pw2
        pw1="$(ask -s "LUKS passphrase for $p2")" || {
          info "aborted"
          return 0
        }
        pw2="$(ask -s "Repeat LUKS passphrase")" || {
          info "aborted"
          return 0
        }
        [[ -n "$pw1" ]] || { warn "empty passphrase not allowed — try again"; continue; }
        [[ "$pw1" == "$pw2" ]] || { warn "passphrases do not match — try again"; continue; }
        luks_pw="$pw1"
        unset pw1 pw2
        break
      done
    fi

    info "luksFormat $p2 (argon2id)"
    printf '%s' "$luks_pw" | cryptsetup luksFormat --key-file=- --type luks2 --pbkdf argon2id --label nixos-root-luks "$p2"
    printf '%s' "$luks_pw" | cryptsetup open --key-file=- --type luks "$p2" cryptroot

    # XFS layout inside LUKS: / (label nixos-root). The nix store and all
    # system/user state live on it directly — no subvolumes, no /persist.
    mkfs.xfs -f -L nixos-root /dev/mapper/cryptroot

    # TPM2 auto-unlock (optional): flag + device presence + confirm.
    # - --tpm2 set: must have a TPM2 device; fail loudly under --yes so it
    #   doesn't silently no-op.
    # - flag unset: prompt only if a TPM2 device is present (so non-TPM2
    #   boxes never see the question).
    if have systemd-cryptenroll; then
      local tpm2_devs
      tpm2_devs="$(systemd-cryptenroll --tpm2-device=list 2>/dev/null || true)"
      if [[ -n "$tpm2_devs" ]]; then
        local do_tpm2=0
        if [[ $ENABLE_TPM2 -eq 1 ]]; then
          do_tpm2=1
        elif [[ $AN_YES_SET -eq 0 ]] && confirm "Also enroll TPM2 auto-unlock (PCR 7+8)?"; then
          do_tpm2=1
        fi
        if [[ $do_tpm2 -eq 1 ]]; then
          local keyfile
          keyfile="$(mktemp)"; chmod 600 "$keyfile"
          printf '%s' "$luks_pw" > "$keyfile"
          if systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+8 --unlock-key-file="$keyfile" "$p2"; then
            info "TPM2 enrolled — auto-unlock on PCR 7+8 match (passphrase remains as fallback)"
          else
            warn "TPM2 enrollment failed — passphrase-only for now"
          fi
          rm -f "$keyfile"
        fi
      elif [[ $ENABLE_TPM2 -eq 1 ]]; then
        die "--tpm2 was requested but no TPM2 device found (systemd-cryptenroll --tpm2-device=list empty)"
      fi
    elif [[ $ENABLE_TPM2 -eq 1 ]]; then
      die "--tpm2 requires systemd-cryptenroll (nix shell nixpkgs#systemd -c bash ./setup.sh ...)"
    fi
    unset luks_pw
  else
    # XFS layout: one filesystem for / (label nixos-root). The nix store and
    # all system/user state live on it directly — no subvolumes, no /persist.
    mkfs.xfs -f -L nixos-root "$p2"
  fi

  # Make udev create /dev/disk/by-label symlinks for the fresh filesystems.
  # udev can lag behind right after mkfs; without this the by-label mounts
  # in step_deploy fail with "... does not exist".
  udevadm settle || true
  udevadm trigger --subsystem-match=block || true
  udevadm settle || true

  if [[ $ENABLE_LUKS -eq 1 ]]; then
    info "done: $p1 (ESP, label nixos-boot) + $p2 (LUKS2 -> cryptroot, label nixos-root)"
    info "remember: the selected host must set mySystem.enableLuks = true to match"
  else
    info "done: $p1 (ESP, label nixos-boot) + $p2 (xfs, label nixos-root)"
  fi
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

  ensure_tools openssl

  local p1 p2 hash
  while :; do
    p1="$(ask -s "New password for user 'mario'")" || {
      info "no input — aborting password step"
      return 0
    }
    p2="$(ask -s "Repeat password for 'mario'")" || {
      info "no input — aborting password step"
      return 0
    }
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
# Step 5 — secrets file
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
    tmp="$(mktemp --suffix=.yaml)"
    trap 'rm -f "$tmp"' RETURN
    printf '# secrets.yaml\n# key: value\n' > "$tmp"
    if sops --config "$SOPS_YAML" -i -e "$tmp"; then
      cp "$tmp" "$SECRETS_FILE"
      info "created encrypted $SECRETS_FILE (edit with: sops $SECRETS_FILE)"
    else
      warn "sops encryption failed — secrets file not created"
    fi
  else
    warn "secrets file skipped"
  fi
}

# ---------------------------------------------------------------------------
# Step 5 — deploy
# ---------------------------------------------------------------------------
step_deploy() {
  log "Deploy"

  confirm "Rebuild the system now?" || {
    info "skipped — run later with: sudo nixos-rebuild switch --flake .#<host>"
    info "             or:           sudo nixos-install --flake .#<host>  (installer ISO)"
    return 0
  }

  # Build tag/item pairs for the menu.
  local -a menu_args
  local i h
  for i in "${!HOSTS[@]}"; do menu_args+=("$((i+1))" "${HOSTS[$i]%.nix}"); done
  local choice
  choice="$(ask -m "Pick a host to rebuild:" "${menu_args[@]}" "1")" || die "host selection aborted"
  [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#HOSTS[@]})) \
    || die "invalid host number: $choice"
  local name="${HOSTS[$((choice-1))]%.nix}"

  if is_installer_env; then
    # libgit2 refuses repos not owned by the current user (root on installer).
    git config --global --add safe.directory "$REPO_ROOT"

    local rootdev label
    if [[ $ENABLE_LUKS -eq 1 ]]; then
      rootdev="/dev/mapper/cryptroot"; label="nixos-root-luks"
    else
      rootdev="/dev/disk/by-label/nixos-root"; label="nixos-root"
    fi
    [[ -e "$rootdev" ]] \
      || die "no device at $rootdev (label '$label') — run the partition step first, e.g.:  sudo ./setup.sh --luks"

    findmnt -n /mnt        >/dev/null 2>&1 || mount "$rootdev" /mnt        || die "mount $rootdev at /mnt failed"
    mkdir -p /mnt/boot
    findmnt -n /mnt/boot  >/dev/null 2>&1 \
      || mount -o fmask=0077,dmask=0077 /dev/disk/by-label/nixos-boot /mnt/boot \
      || die "mount boot failed"

    # Copy the flake including dotfiles (.git, .gitignore, secrets/.sops.yaml*).
    # Without .git the target is a plain path flake whose NAR hash changes
    # whenever the lock file updates, breaking nixos-install with "NAR hash
    # mismatch in input path:...".
    mkdir -p /mnt/etc/nixos
    cp -r "$REPO_ROOT"/. /mnt/etc/nixos/

    # Provision the password hash and age key on the target.
    [[ -n "$PASSWORD_HASH" ]] && printf '%s\n' "$PASSWORD_HASH" > /mnt/etc/hashed-password \
      && chmod 600 /mnt/etc/hashed-password
    [[ -f "$AGE_KEY_PATH" ]] && install -d -m 700 /mnt/root/.config/sops/age \
      && install -m 600 "$AGE_KEY_PATH" /mnt/root/.config/sops/age/keys.txt

    info "-> nixos-install for '$name'"
    nixos-install --flake "/mnt/etc/nixos#$name" --no-root-passwd
  else
    [[ -n "$PASSWORD_HASH" ]] && printf '%s\n' "$PASSWORD_HASH" > /etc/hashed-password \
      && chmod 600 /etc/hashed-password
    info "-> nixos-rebuild for '$name'"
    nixos-rebuild switch --flake ".#$name"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -y|--yes) AN_YES_SET=1 ;;
    --luks) ENABLE_LUKS=1 ;;
    --tpm2) ENABLE_TPM2=1 ;;
    --secure-boot) ENABLE_SECURE_BOOT=1 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

# --tpm2 enrolls a TPM2 key against the LUKS volume, so it requires --luks.
# --secure-boot only emits a post-install hint (lanzaboote works fine on plain
# unencrypted roots too), so it stands alone.
if [[ $ENABLE_TPM2 -eq 1 ]] && [[ $ENABLE_LUKS -eq 0 ]]; then
  die "--tpm2 requires --luks (e.g.: sudo ./setup.sh --luks --tpm2)"
fi

preflight
step_partition
step_password
ensure_tools age age-keygen sops
step_age
step_secrets
step_deploy

log "All done."
warn "Password hash lives in /etc/hashed-password on the system (never in the repo)."
if [[ $ENABLE_LUKS -eq 1 ]]; then
  warn "Root is LUKS2-encrypted — the host must set mySystem.enableLuks = true to match."
fi
if [[ $ENABLE_TPM2 -eq 1 ]]; then
  warn "TPM2 enrolled only if a TPM2 device was present; set mySystem.enableTpm2 = true on the host."
fi
if [[ $ENABLE_SECURE_BOOT -eq 1 ]]; then
  warn "Secure Boot needs manual key enrollment after first boot: sbctl create-keys && sbctl enroll-keys --microsoft, and mySystem.enableSecureBoot = true (uses lanzaboote)."
fi
