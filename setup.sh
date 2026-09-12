#!/usr/bin/env bash
# setup.sh — bootstrap a new machine from this flake-based NixOS config.
#
# Usage:
#   sudo ./setup.sh [--luks] [--tpm2] [--secure-boot] [--yes]   interactive setup
#   sudo ./setup.sh --luks --tpm2      encrypt root + TPM2 auto-unlock
#   ./setup.sh --help | --list-hosts | --dry-run   work without root
#
# Flags: --yes (noninteractive; secrets still prompt, LUKS_PASSPHRASE skips),
#   --tui=auto|plain|fzf|gum|whiptail, --no-tui, --no-color ($NO_COLOR too),
#   --resume (restore choices after interrupt), --fresh (discard saved state),
#   --dry-run (print plan, change nothing), --list-hosts.
#
# Required tools are assumed present (run from the NixOS installer ISO, or under
# `nix shell nixpkgs#openssl nixpkgs#cryptsetup
# nixpkgs#systemd nixpkgs#gptfdisk nixpkgs#dosfstools
# nixpkgs#xfsprogs` on any other NixOS).
#
# Steps: collect (1-6, prompts only, nothing destructive) -> review + one
# confirm -> execute (7: zram, USB backup, wipe+format with typed WIPE,
# deploy). Each step idempotent, skips when already done.
#   1.  preflight + orientation summary
#   2.  pick host (first, so LUKS/disk defaults are known early)
#   3.  zram swap on the installer ISO (OOM guard, auto only)
#   4.  OPTIONAL destructive: guided partitioning + formatting of a disk
#       (only offered on the installer ISO; refuses mounted disks; pick
#       from a numbered menu, preview with lsblk -f, type WIPE to confirm).
#       --luks wraps root in LUKS2 (label nixos-root, container
#       nixos-root-luks -> mapper cryptroot); offered interactively if omitted.
#   5.  user password: SHA-512 hash via openssl, written to
#       /etc/hashed-password on the target during the deploy step (read at
#       activation via `users.users.mario.hashedPasswordFile`); the hash is
#       never stored in the repo
#   6.  deploy via nh (fallback nixos-rebuild) or nixos-install on the ISO
#
# See README.md for details.
set -euo pipefail

# Interactive defaults. require_root() runs after --help/--list-hosts/--dry-run
# so those work rootless; partitioning + deploy still need root.
SELECTED_HOST=""
DRY_RUN=0
USE_COLOR=1
TUI_MODE="auto"
RESUME=0
DO_FRESH=0
LIST_HOSTS=0
CLI_LUKS=-1
CLI_TPM2=-1
CLI_SB=-1
SKIP_WIPE=0
BACKUP_DEV=""
LUKS_PW_MEM=""

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_DIR="$REPO_ROOT/modules/hosts"

AN_YES_SET=0
# LUKS flags: --luks / --tpm2 / --secure-boot; LUKS_PASSPHRASE env to skip passphrase prompt.
ENABLE_LUKS=0
ENABLE_TPM2=0
ENABLE_SECURE_BOOT=0
LUKS_PASSPHRASE=""
# Password hash captured in step_password; written to /etc/hashed-password
# on the target by step_deploy (base.nix user section reads it via hashedPasswordFile).
PASSWORD_HASH=""
# Disk path captured in step_partition (only set when partitioning actually
# happens — empty on --yes re-runs against an already-formatted disk, in which
# case patch_host_flags leaves the disko device override alone).
INSTALL_DISK=""

_emit() {
  local c="$1"; shift
  if [[ $USE_COLOR -eq 1 && -n "$c" ]]; then
    printf '\033[%sm%s\033[0m\n' "$c" "$*"
  else
    printf '%s\n' "$*"
  fi
}
log()  { _emit "1;34" "==> $*"; }
info() { _emit "" "    $*"; }
warn() { _emit "1;33" "[!] $*" >&2; }
die()  { _emit "1;31" "[error] $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
require_root() {
  [[ $EUID -eq 0 ]] || die "setup.sh needs root (try: sudo ./setup.sh). --help, --list-hosts, --dry-run work rootless."
}

# Ensure tools are on PATH — on NixOS systems, install via nix if missing.
# Maps tool names to their nixpkgs attribute for auto-install.
ensure_tools() {
  local missing=() pkgs=()
  for tool in "$@"; do
    if ! have "$tool"; then
      missing+=("$tool")
      case "$tool" in
        openssl)        pkgs+=(nixpkgs#openssl) ;;
        cryptsetup)     pkgs+=(nixpkgs#cryptsetup) ;;
        systemd-cryptenroll) pkgs+=(nixpkgs#systemd) ;;
        sgdisk|gdisk)   pkgs+=(nixpkgs#gptfdisk) ;;
        mkfs.vfat|dosfslabel) pkgs+=(nixpkgs#dosfstools) ;;
        mkfs.xfs|xfs_db) pkgs+=(nixpkgs#xfsprogs) ;;
        partprobe)      pkgs+=(nixpkgs#parted) ;;
        udevadm)        pkgs+=(nixpkgs#systemd) ;;
        fzf)            pkgs+=(nixpkgs#fzf) ;;
        gum)            pkgs+=(nixpkgs#gum) ;;
        whiptail)       pkgs+=(nixpkgs#newt) ;;
        *)              warn "don't know how to install '$tool' via nix"; continue ;;
      esac
    fi
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  have nix || die "missing tools (${missing[*]}) and nix is not in PATH — install them manually";

  # Deduplicate package list.
  local -a unique_pkgs
  mapfile -t unique_pkgs < <(printf '%s\n' "${pkgs[@]}" | sort -u)

  info "Installing ${missing[*]} via nix..."
  local out err
  err="$(mktemp)"
  out="$(nix --extra-experimental-features "nix-command flakes" build --no-link --print-out-paths "${unique_pkgs[@]}" 2>"$err")" || true
  if [[ -n "$out" ]]; then
    local bins
    bins="$(echo "$out" | while IFS= read -r p; do [[ -d "$p/bin" ]] && echo "$p/bin" || true; done | tr '\n' ':')"
    export PATH="${bins}${PATH}"
    info "ready: ${missing[*]}"
  else
    warn "nix build failed for ${missing[*]} (tail of log):"
    tail -5 "$err" >&2 || true
    warn "install ${missing[*]} manually and rerun"
  fi
  rm -f "$err"
}

usage() {
  cat <<'EOF'
setup.sh -- bootstrap a new machine from this flake-based NixOS config.

Usage:
  sudo ./setup.sh [--luks] [--tpm2] [--secure-boot] [--yes]
  sudo ./setup.sh --luks --tpm2        encrypt root + TPM2 auto-unlock
  ./setup.sh --help | --list-hosts | --dry-run     (no root needed)

Steps (collect all choices, then one confirm, then execute):
  1. preflight + orientation   2. pick host   3. options (luks/tpm2/secure-boot)
  4. target disk menu          5. user password (hashed now, memory only)
  6. USB backup (optional)     7. review plan, confirm once, execute
     execute: zram, USB backup, wipe+format (typed WIPE), deploy (nh or nixos-*)

Flags:
  --yes           answer yes to confirms (passphrases still prompt;
                  set LUKS_PASSPHRASE env to skip the LUKS prompt)
  --luks          LUKS2-encrypt root (offered interactively if omitted)
  --tpm2          TPM2 auto-unlock (needs --luks + TPM2 hardware)
  --secure-boot   patch mySystem.enableSecureBoot + print sbctl next steps
  --tui=BACKEND   auto (default) | plain | fzf | gum | whiptail
  --no-tui        force plain prompts. --no-color  plain output ($NO_COLOR too)
  --resume        restore choices saved before an interrupt
  --fresh         discard saved state. --dry-run  print plan, change nothing
  --list-hosts    print host names, exit. -h, --help  this text

State file: /var/tmp/nixos-setup.state (choices only, never secrets).
See README.md for details.
EOF
}

# Prompts (ask/confirm) + crash-resume (save_state/load_state) live in lib/.
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"
# shellcheck disable=SC1091
source "$LIB_DIR/tui.sh"
# shellcheck disable=SC1091
source "$LIB_DIR/state.sh"

# ---------------------------------------------------------------------------
# Step 1 — preflight
# ---------------------------------------------------------------------------
preflight() {
  log "Step 1/7 — Preflight"

  [[ -f "$REPO_ROOT/flake.nix" ]] \
    || die "flake.nix not found — run setup.sh from the repo root"

  have lsblk || die "lsblk not found in PATH"

  mapfile -t HOSTS < <(find "$HOSTS_DIR" -maxdepth 1 -name '*.nix' ! -name '.*' -printf '%f\n' 2>/dev/null | sort)
  [[ ${#HOSTS[@]} -gt 0 ]] || die "no host configs (*.nix) found in modules/hosts/"

  info "repo: $REPO_ROOT"
  info "hosts: ${HOSTS[*]}"
  if is_installer_env; then
    info "mode: installer ISO (fresh path: partition + nixos-install)"
  else
    info "mode: live system (in-place path: rebuild switch)"
  fi
  info "prompts: $(tui_backend) (override: --tui= / --no-tui)"
  [[ $DRY_RUN -eq 1 ]] && info "dry run — nothing will change"

  have nixos-rebuild || have nh || warn "neither 'nixos-rebuild' nor 'nh' in PATH (normal on the installer ISO)"
}

# ---------------------------------------------------------------------------
# Step 2 — pick host first (LUKS/disk defaults depend on it)
# ---------------------------------------------------------------------------
step_host() {
  log "Step 2/7 — Host"
  if [[ -n "$SELECTED_HOST" ]]; then
    local want="$SELECTED_HOST.nix"
    if [[ " ${HOSTS[*]} " == *" $want "* ]]; then
      if confirm -y "Keep host '$SELECTED_HOST'?"; then mark_done "host"; return 0; fi
      SELECTED_HOST=""
    else
      warn "saved host '$SELECTED_HOST' not in modules/hosts — repicking"
      SELECTED_HOST=""
    fi
  fi
  if [[ $AN_YES_SET -eq 1 ]]; then
    SELECTED_HOST="${HOSTS[0]%.nix}"
    info "host: $SELECTED_HOST (--yes default)"
  else
    [[ -t 0 ]] || die "no TTY and no host chosen — rerun with --yes, or --resume with saved state"
    local -a menu_args
    local i choice
    for i in "${!HOSTS[@]}"; do menu_args+=("$((i+1))" "${HOSTS[$i]%.nix}"); done
    while :; do
      choice="$(ask -m "Pick a host to install:" "${menu_args[@]}" "1")" || die "host selection aborted"
      if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#HOSTS[@]})); then
        SELECTED_HOST="${HOSTS[$((choice-1))]%.nix}"
        break
      fi
      warn "invalid host number: $choice — try again"
    done
  fi
  mark_done "host"
}

# ---------------------------------------------------------------------------
# Step 1.5 — temporary zram swap on the installer ISO
# ---------------------------------------------------------------------------
# nixos-install + the initial flake evaluation can spike past 4 GiB RSS,
# OOM-killing the shell mid-build. zram is already in the ISO kernel,
# no extra package needed. Activates only inside the installer env so it
# never touches an already-installed system.
step_zram() {
  if [[ $DRY_RUN -eq 1 ]]; then
    info "dry run — would enable zram swap on installer ISO"
    return 0
  fi
  if ! is_installer_env; then
    return 0
  fi

  if ! modprobe zram 2>/dev/null; then
    warn "zram module unavailable — skipping (OOM risk on low-RAM installs)"
    return 0
  fi

  local mem_kb total_kb
  mem_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
  total_kb="$mem_kb"
  if (( total_kb > 8 * 1024 * 1024 )); then
    total_kb=$((8 * 1024 * 1024))
  fi

  if have zramctl; then
    if ! zramctl --find --size "${total_kb}K" --algorithm zstd >/dev/null; then
      warn "zramctl failed to allocate zram device"
      return 0
    fi
    local dev
    dev="$(zramctl --noheadings --output NAME --raw | tail -1)"
    [[ -b "$dev" ]] || { warn "zram device not found after zramctl"; return 0; }
    mkswap "$dev" >/dev/null
    swapon -p 100 "$dev"
  else
    local i dev=""
    for i in 0 1 2 3; do
      if [[ -b "/dev/zram$i" ]]; then
        dev="/dev/zram$i"; break
      fi
    done
    if [[ -z "$dev" ]]; then
      echo 1 > /sys/class/zram-control/hot_add 2>/dev/null || true
      for i in 0 1 2 3; do
        if [[ -b "/dev/zram$i" ]]; then
          dev="/dev/zram$i"; break
        fi
      done
    fi
    [[ -n "$dev" ]] || { warn "no /dev/zram<N> available"; return 0; }
    local zname="${dev##*/}"
    if ! echo "${total_kb}K" > "/sys/class/block/$zname/disksize"; then
      warn "could not set zram disksize"
      return 0
    fi
    mkswap "$dev" >/dev/null
    swapon "$dev"
  fi

  swapon --show
  info "zram swap ready — protects against OOM during nixos-install"
}

# ---------------------------------------------------------------------------
# Collect phase — every choice up front, nothing destructive runs here.
# Secrets stay in memory only (LUKS_PW_MEM, PASSWORD_HASH); state file
# stores choices, never secrets.
# ---------------------------------------------------------------------------
collect_flags() {
  log "Step 3/7 — Options"
  [[ -t 0 ]] && [[ $AN_YES_SET -eq 0 ]] || return 0
  if [[ $ENABLE_LUKS -eq 0 ]] && is_installer_env; then
    if confirm "Encrypt the root partition with LUKS2?"; then ENABLE_LUKS=1; fi
  fi
  if [[ $ENABLE_LUKS -eq 1 && $ENABLE_TPM2 -eq 0 ]]; then
    if have systemd-cryptenroll && [[ -n "$(systemd-cryptenroll --tpm2-device=list 2>/dev/null || true)" ]]; then
      if confirm "Also enroll TPM2 auto-unlock (PCR 7+8)?"; then ENABLE_TPM2=1; fi
    fi
  fi
  if [[ $ENABLE_SECURE_BOOT -eq 0 ]]; then
    if confirm "Enable Secure Boot (lanzaboote, needs sbctl enrollment after first boot)?"; then ENABLE_SECURE_BOOT=1; fi
  fi
  mark_done "flags"
}

collect_disk() {
  log "Step 4/7 — Target disk"
  if ! is_installer_env; then
    info "not on the installer ISO — no wipe needed on a live system"
    SKIP_WIPE=1
    return 0
  fi
  if [[ -n "$INSTALL_DISK" && -b "$INSTALL_DISK" ]]; then
    SKIP_WIPE=0
    if confirm -y "Keep disk '$INSTALL_DISK' for wipe?"; then mark_done "disk"; return 0; fi
    INSTALL_DISK=""
  fi
  if [[ $AN_YES_SET -eq 0 ]]; then
    if ! confirm "Partition and format a disk? This ERASES all data on it"; then
      info "skipped — make sure modules/hosts/*.nix point at real disks before deploying"
      SKIP_WIPE=1
      return 0
    fi
  fi
  SKIP_WIPE=0

  ensure_tools sgdisk mkfs.vfat mkfs.xfs cryptsetup systemd-cryptenroll partprobe udevadm lsblk

  mapfile -t DISKS < <(lsblk -dno NAME,SIZE,MODEL | awk '{print "/dev/"$1"  "$2"  "$3}')
  [[ ${#DISKS[@]} -gt 0 ]] || die "no disks found via lsblk"
  local -a dmenu
  local i pick
  for i in "${!DISKS[@]}"; do dmenu+=("$((i+1))" "${DISKS[$i]}"); done
  dmenu+=("0" "type device path manually")

  local disk
  while :; do
    pick="$(ask -m "Pick a disk to WIPE (all data erased):" "${dmenu[@]}" "0")" || {
      info "no input — skipping wipe"
      SKIP_WIPE=1
      return 0
    }
    if [[ "$pick" == "0" ]]; then
      disk="$(ask "Type the full device path (e.g. /dev/sda)")" || {
        info "no input — skipping wipe"
        SKIP_WIPE=1
        return 0
      }
    elif [[ "$pick" =~ ^[0-9]+$ ]] && ((pick >= 1 && pick <= ${#DISKS[@]})); then
      disk="${DISKS[$((pick-1))]%% *}"
    else
      warn "invalid pick: $pick — try again"
      continue
    fi
    [[ -n "$disk" ]] || continue
    [[ "$disk" =~ $DISK_PATTERN ]] || { warn "invalid device path: $disk"; continue; }
    [[ -b "$disk" ]] || { warn "not a block device: $disk"; continue; }
    if disk_is_mounted "$disk"; then
      warn "disk $disk has mounted partitions — refusing to wipe it"
      continue
    fi
    local size_b
    size_b="$(lsblk -dnbo SIZE "$disk" 2>/dev/null || echo 0)"
    (( size_b < 8*1024*1024*1024 )) && warn "disk smaller than 8 GiB — install may fail"
    break
  done

  # Remember the disk for the execute phase + patch_host_flags (disko device).
  INSTALL_DISK="$disk"
  mark_done "disk"
}

collect_luks_pw() {
  [[ $ENABLE_LUKS -eq 0 ]] && return 0
  [[ -n "${LUKS_PASSPHRASE:-}" ]] && return 0
  [[ -t 0 ]] || die "LUKS needs a passphrase but stdin is not a TTY — set LUKS_PASSPHRASE env and rerun"
  while :; do
    local pw1 pw2
    pw1="$(ask -s "LUKS passphrase (used at execute time, never saved)")" || die "aborted"
    pw2="$(ask -s "Repeat LUKS passphrase")" || die "aborted"
    [[ -n "$pw1" ]] || { warn "empty passphrase not allowed — try again"; continue; }
    [[ "$pw1" == "$pw2" ]] || { warn "passphrases do not match — try again"; continue; }
    LUKS_PW_MEM="$pw1"
    unset pw1 pw2
    break
  done
  mark_done "lukspw"
}

collect_usb() {
  log "Step 6/7 — USB backup (optional)"
  local cands
  cands="$(lsblk -dnro NAME,RM,TRAN 2>/dev/null | awk -v skip="${INSTALL_DISK#/dev/}" '$2==1 || $3=="usb" { if ($1 != skip) print "/dev/"$1 }')"
  [[ -n "$cands" ]] || { info "no removable USB disk found — skipping backup"; return 0; }
  local -a umenu
  local i=0 u
  while IFS= read -r u; do
    i=$((i+1)); umenu+=("$i" "$u")
  done <<< "$cands"
  umenu+=("0" "no backup")
  local pick dev
  pick="$(ask -m "Back up repo + state to USB before wiping?" "${umenu[@]}" "0")" || return 0
  [[ "$pick" == "0" ]] && return 0
  if [[ "$pick" =~ ^[0-9]+$ ]] && ((pick >= 1 && pick <= i)); then
    dev="$(printf '%s\n' "$cands" | sed -n "${pick}p")"
    [[ -b "$dev" ]] && BACKUP_DEV="$dev" && info "backup target: $BACKUP_DEV (runs first at execute time)"
  fi
  mark_done "usb"
}

do_backup() {
  [[ -n "${BACKUP_DEV:-}" ]] || return 0
  local mnt=/mnt/usb-backup part
  mkdir -p "$mnt"
  for part in "${BACKUP_DEV}1" "${BACKUP_DEV}p1" "$BACKUP_DEV"; do
    if mount "$part" "$mnt" 2>/dev/null; then
      info "backup: repo + state -> $part"
      cp -r "$REPO_ROOT/." "$mnt/nixos-backup/" || warn "repo copy failed"
      [[ -f "$STATE_FILE" ]] && cp "$STATE_FILE" "$mnt/" || true
      sync
      umount "$mnt" || warn "umount $mnt failed — unplug USB after reboot"
      return 0
    fi
  done
  warn "could not mount $BACKUP_DEV — backup skipped"
}

print_plan() {
  log "Review — full plan"
  info "host: $SELECTED_HOST"
  info "encrypt: luks=$ENABLE_LUKS tpm2=$ENABLE_TPM2 secure-boot=$ENABLE_SECURE_BOOT"
  if [[ $SKIP_WIPE -eq 1 ]]; then
    info "disk: <keep, no wipe>"
  else
    info "disk to WIPE: ${INSTALL_DISK:-<unset>}"
  fi
  if [[ -n "$PASSWORD_HASH" ]]; then info "password: set"; else info "password: skipped"; fi
  info "usb backup: ${BACKUP_DEV:-none}"
}

# ---------------------------------------------------------------------------
# Step 4 — OPTIONAL: guided partitioning (destructive!)
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
  log "Partition & format (DESTRUCTIVE — execute phase)"

  [[ $SKIP_WIPE -eq 1 ]] && { info "skipped by choice — using existing disks"; return 0; }
  if ! is_installer_env; then
    info "not on the installer ISO — skipping"
    return 0
  fi
  local disk="$INSTALL_DISK"
  [[ -n "$disk" ]] || die "no disk collected — aborting before wipe"
  [[ "$disk" =~ $DISK_PATTERN ]] || die "collected disk invalid: $disk"
  [[ -b "$disk" ]] || die "not a block device: $disk"
  if disk_is_mounted "$disk"; then
    die "disk $disk has mounted partitions — refusing to wipe it"
  fi

  ensure_tools sgdisk mkfs.vfat mkfs.xfs cryptsetup systemd-cryptenroll partprobe udevadm lsblk

  echo
  warn "ABOUT TO ERASE ALL DATA ON: $disk"
  info "current content of $disk:"
  lsblk -f "$disk" || true
  echo "  partition 1: ESP   1 GiB  vfat label 'nixos-boot'"
  if [[ $ENABLE_LUKS -eq 1 ]]; then
    echo "  partition 2: root  rest  LUKS2 label 'nixos-root' (LUKS container label 'nixos-root-luks') -> XFS inside (label 'nixos-root')"
  else
    echo "  partition 2: root  rest  xfs  label 'nixos-root'"
  fi
  ans="$(ask "Type WIPE (exactly) to continue erasing $disk")" || {
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

  # Collected up front (collect_luks_pw); env/fallback cover --yes re-runs.
  local luks_pw="${LUKS_PW_MEM:-${LUKS_PASSPHRASE:-}}"
  unset LUKS_PW_MEM
  if [[ $ENABLE_LUKS -eq 1 && -z "$luks_pw" ]]; then
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

  if [[ $ENABLE_LUKS -eq 1 ]]; then
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
# Step 5 — user password (hash only, kept in PASSWORD_HASH)
# The hash is written on the system at /etc/hashed-password by step_deploy
# (read at activation by `users.users.mario.hashedPasswordFile`).
# ---------------------------------------------------------------------------
pw_strength() {
  # Echo weak reason, or nothing when ok. ponytail: length + classes, no dep.
  local pw="$1" n=0
  (( ${#pw} >= 12 )) || { echo "shorter than 12 chars"; return 0; }
  [[ "$pw" == *[a-z]* ]] && ((n+=1))
  [[ "$pw" == *[A-Z]* ]] && ((n+=1))
  [[ "$pw" == *[0-9]* ]] && ((n+=1))
  case "$pw" in *[^a-zA-Z0-9]*) ((n+=1)) ;; esac
  (( n >= 3 )) || echo "needs 3+ of: lower, upper, digit, symbol"
  return 0
}
step_password() {
  log "Step 5/7 — User password (mario)"

  if [[ $AN_YES_SET -eq 1 && ! -t 0 ]]; then
    info "skipped — password prompt needs a TTY (set later via passwd)"
    return 0
  fi

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
    local weak
    weak="$(pw_strength "$p1" || true)"
    if [[ -n "$weak" ]]; then
      warn "weak password ($weak)"
      confirm "Use it anyway?" || continue
    fi
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
  # /etc/hashed-password (base.nix user section reads it via hashedPasswordFile).
  # It never touches git-tracked files.
  PASSWORD_HASH="$hash"
  info "password hash ready — it will be written to /etc/hashed-password during deploy"
}

# ---------------------------------------------------------------------------
# Step 6 — deploy
# ---------------------------------------------------------------------------
# Patch the selected host's modules/hosts/<name>.nix to flip
# mySystem.enable{Luks,Tpm2,SecureBoot} from false to true when the
# matching --luks / --tpm2 / --secure-boot flag is set. Idempotent:
# already-true lines are left alone, and we only flip the specific
# flag(s) the user requested (never all three at once).
#
# Always operates on the source tree. In installer mode the source is
# copied to /mnt/etc/nixos afterward, so the installed system sees
# the new values. In non-installer mode we still patch in place — the
# user is running on a host they control and asked for the rebuild.
patch_host_flags() {
  local name="$1"
  local host_file="$HOSTS_DIR/$name.nix"
  local key
  [[ -f "$host_file" ]] || { warn "host file $host_file not found — cannot patch flags"; return 0; }

  local -a flips=()
  [[ $ENABLE_LUKS -eq 1 ]]        && flips+=(enableLuks)
  [[ $ENABLE_TPM2 -eq 1 ]]        && flips+=(enableTpm2)
  [[ $ENABLE_SECURE_BOOT -eq 1 ]] && flips+=(enableSecureBoot)
  [[ ${#flips[@]} -eq 0 ]] && return 0

  info "pending change(s) in $host_file:"
  local key
  for key in "${flips[@]}"; do
    if grep -q "mySystem.${key}[[:space:]]*=[[:space:]]*true" "$host_file"; then
      info "  mySystem.$key already true — no change needed"
    else
      info "  mySystem.$key -> true"
    fi
  done
  confirm "Patch $host_file as above?" || { info "skipped — set flags manually"; return 0; }

  for key in "${flips[@]}"; do
    # Match "mySystem.<key> = false;" with optional trailing whitespace;
    # leave a `= true;` line alone so re-runs are no-ops.
    if grep -Eq "^[[:space:]]*mySystem\\.${key}[[:space:]]*=[[:space:]]*false[[:space:]]*;" "$host_file"; then
      sed -i -E "s|^([[:space:]]*mySystem\\.${key}[[:space:]]*=[[:space:]]*)false([[:space:]]*;)|\\1true\\2|" "$host_file"
      info "patched $host_file: mySystem.$key = true"
    elif grep -Eq "^[[:space:]]*mySystem\\.${key}[[:space:]]*=[[:space:]]*true[[:space:]]*;" "$host_file"; then
      info "$host_file: mySystem.$key already true — no change"
    else
      # No assignment for this flag in the host file — append a fresh
      # one so the user doesn't have to. Append after the last
      # mySystem.* line if any, else at the end of the config block.
      if grep -q "^[[:space:]]*mySystem\\." "$host_file"; then
        sed -i "/^[[:space:]]*mySystem\\./a\\    mySystem.$key = true;" "$host_file"
        info "appended to $host_file: mySystem.$key = true"
      else
        warn "no mySystem.* assignment found in $host_file — set mySystem.$key = true manually"
      fi
    fi
  done

  # When LUKS partitioning just happened on a non-/dev/sda disk, override
  # the disko device path in the host file so the initrd can find the
  # LUKS partition at boot. filesystems.nix declares it as
  # `lib.mkDefault "/dev/sda"`, so any per-host assignment wins without
  # a force-override. Skip when the disk is /dev/sda (the default already
  # matches) or when no partitioning happened (INSTALL_DISK empty).
  if [[ $ENABLE_LUKS -eq 1 && -n "$INSTALL_DISK" && "$INSTALL_DISK" != "/dev/sda" ]]; then
    if grep -Eq "^[[:space:]]*disko\\.devices\\.disk\\.nixos\\.device[[:space:]]*=" "$host_file"; then
      sed -i -E "s|^([[:space:]]*disko\\.devices\\.disk\\.nixos\\.device[[:space:]]*=[[:space:]]*)\"[^\"]*\"|\\1\"$INSTALL_DISK\"|" "$host_file"
      info "patched $host_file: disko.devices.disk.nixos.device = \"$INSTALL_DISK\""
    else
      # Append after the last mySystem.* line so the config stays grouped.
      if grep -q "^[[:space:]]*mySystem\\." "$host_file"; then
        sed -i "/^[[:space:]]*mySystem\\./a\\    disko.devices.disk.nixos.device = \"$INSTALL_DISK\";" "$host_file"
        info "appended to $host_file: disko.devices.disk.nixos.device = \"$INSTALL_DISK\""
      else
        warn "no mySystem.* assignment in $host_file — set disko.devices.disk.nixos.device = \"$INSTALL_DISK\" manually"
      fi
    fi
  fi
}

step_deploy() {
  log "Deploy ($SELECTED_HOST) — execute phase"

  local name="$SELECTED_HOST"

  # ponytail: --luks without a fresh wipe leaves INSTALL_DISK empty (disko defaults
  # to /dev/sda) — offer a one-time override so the initrd finds the LUKS partition.
  if [[ $ENABLE_LUKS -eq 1 && -z "$INSTALL_DISK" ]]; then
    if [[ $AN_YES_SET -eq 0 ]]; then
      disk_ans="$(ask "Disk holding the LUKS partition for disko (empty = keep default)")" || true
      if [[ -n "${disk_ans:-}" ]]; then
        if [[ "$disk_ans" =~ $DISK_PATTERN ]] && [[ -b "$disk_ans" ]]; then
          INSTALL_DISK="$disk_ans"
        else
          warn "not a valid disk ($disk_ans) — disko device left as declared"
        fi
      else
        info "disko device left as declared (default /dev/sda)"
      fi
    fi
  fi

  # Sync the selected host's mySystem.enable* flags with the CLI flags
  # BEFORE copying the source or running nixos-rebuild. Both branches
  # below consume the (now-patched) flake.
  patch_host_flags "$name"

  if is_installer_env; then
    # libgit2 refuses repos not owned by the current user (root on installer).
    git config --global --add safe.directory "$REPO_ROOT"

    local rootdev label
    if [[ $ENABLE_LUKS -eq 1 ]]; then
      rootdev="/dev/mapper/cryptroot"; label="nixos-root"
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

    # Copy the flake including dotfiles (.git, .gitignore).
    # Without .git the target is a plain path flake whose NAR hash changes
    # whenever the lock file updates, breaking nixos-install with "NAR hash
    # mismatch in input path:...".
    mkdir -p /mnt/etc/nixos
    cp -r "$REPO_ROOT"/. /mnt/etc/nixos/

    # Provision the password hash on the target.
    [[ -n "$PASSWORD_HASH" ]] && printf '%s\n' "$PASSWORD_HASH" > /mnt/etc/hashed-password \
      && chmod 600 /mnt/etc/hashed-password

    info "-> nixos-install for '$name'"
    nixos-install --flake "/mnt/etc/nixos#$name" --no-root-passwd
  else
    [[ -n "$PASSWORD_HASH" ]] && printf '%s\n' "$PASSWORD_HASH" > /etc/hashed-password \
      && chmod 600 /etc/hashed-password
    if have nh; then
      info "-> nh os switch for '$name'"
      nh os switch ".#$name"
    else
      info "-> nixos-rebuild for '$name' (nh not in PATH)"
      nixos-rebuild switch --flake ".#$name"
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
    --luks) ENABLE_LUKS=1; CLI_LUKS=1 ;;
    --tpm2) ENABLE_TPM2=1; CLI_TPM2=1 ;;
    --secure-boot) ENABLE_SECURE_BOOT=1; CLI_SB=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --list-hosts) LIST_HOSTS=1 ;;
    --no-color) USE_COLOR=0 ;;
    --no-tui) TUI_MODE="plain" ;;
    --tui=*) TUI_MODE="${1#--tui=}" ;;
    --tui) if [[ $# -ge 2 ]]; then TUI_MODE="$2"; shift; else TUI_MODE="auto"; fi ;;
    --resume) RESUME=1 ;;
    --fresh) DO_FRESH=1 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

[[ -n "${NO_COLOR:-}" ]] && USE_COLOR=0
[[ -t 1 || -t 2 ]] || USE_COLOR=0

if [[ $LIST_HOSTS -eq 1 ]]; then
  find "$HOSTS_DIR" -maxdepth 1 -name '*.nix' ! -name '.*' -printf '%f\n' 2>/dev/null | sed 's/\.nix$//' | sort
  exit 0
fi

# --tpm2 enrolls a TPM2 key against the LUKS volume, so it requires --luks.
if [[ $ENABLE_TPM2 -eq 1 ]] && [[ $ENABLE_LUKS -eq 0 ]]; then
  die "--tpm2 requires --luks (e.g.: sudo ./setup.sh --luks --tpm2)"
fi

: "${TUI_MODE:=auto}"  # consumed by lib/tui.sh init_tui
init_tui
[[ $DO_FRESH -eq 1 ]] && clear_state
if [[ $RESUME -eq 1 ]]; then
  if load_state; then
    [[ $CLI_LUKS -ne -1 ]] && ENABLE_LUKS=$CLI_LUKS
    [[ $CLI_TPM2 -ne -1 ]] && ENABLE_TPM2=$CLI_TPM2
    [[ $CLI_SB -ne -1 ]] && ENABLE_SECURE_BOOT=$CLI_SB
    [[ $SKIP_WIPE =~ ^[01]$ ]] || SKIP_WIPE=0
    info "restored: host='${SELECTED_HOST:-?}' disk='${INSTALL_DISK:-?}' luks=$ENABLE_LUKS tpm2=$ENABLE_TPM2 secure-boot=$ENABLE_SECURE_BOOT (after: $COMPLETED_STEP)"
    if ! confirm -y "Continue with restored choices?"; then
      clear_state; SELECTED_HOST=""; INSTALL_DISK=""; info "starting fresh"
    fi
  else
    warn "no saved state at $STATE_FILE — starting fresh"
  fi
fi
trap save_state INT TERM EXIT

preflight
step_host
collect_flags
collect_disk
collect_luks_pw
step_password; mark_done "password"
collect_usb
print_plan
if [[ $DRY_RUN -eq 1 ]]; then
  info "dry run — nothing changed."
  exit 0
fi
confirm -y "Execute this plan?" || {
  info "aborted — nothing was changed (rerun with: sudo nixos-rebuild switch --flake .#<host>, or nixos-install on the ISO)"
  exit 0
}
log "Step 7/7 — Execute"
require_root
step_zram; mark_done "zram"
do_backup; mark_done "backup"
step_partition; mark_done "partition"
step_deploy; mark_done "deploy"

# shellcheck disable=SC2034  # read by lib/state.sh save_state guard
DONE=1
clear_state
trap - INT TERM EXIT

log "All done."
warn "Password hash lives in /etc/hashed-password on the system (never in the repo)."
if [[ $ENABLE_LUKS -eq 1 ]]; then
  info "mySystem.enableLuks = true was patched into the selected host file."
  if [[ -n "$INSTALL_DISK" && "$INSTALL_DISK" != "/dev/sda" ]]; then
    info "disko.devices.disk.nixos.device = \"$INSTALL_DISK\" was patched into the selected host file."
  fi
fi
if [[ $ENABLE_TPM2 -eq 1 ]]; then
  if [[ -n "$(systemd-cryptenroll --tpm2-device=list 2>/dev/null || true)" ]]; then
    info "mySystem.enableTpm2 = true was patched into the selected host file."
  else
    warn "TPM2 was requested but no TPM2 device was present at install time — passphrase-only for now."
  fi
fi
if [[ $ENABLE_SECURE_BOOT -eq 1 ]]; then
  info "mySystem.enableSecureBoot = true was patched into the selected host file."
  warn "Secure Boot still needs manual key enrollment after first boot: sbctl create-keys && sbctl enroll-keys --microsoft"
fi
if is_installer_env; then
  info "next: reboot into the installed system (remove the ISO), verify login + network."
else
  info "next: already live — verify with: nh os build . -H $SELECTED_HOST (or nixos-rebuild dry-build --flake .#$SELECTED_HOST)."
fi
