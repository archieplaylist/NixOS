#!/usr/bin/env bash
# lib/state.sh — sourced by setup.sh. Crash-resume for non-secret choices.
# Saves flags + disk + host + step marker. Never passphrases or hashes.
# Flat validated KEY=value data (never sourced); mode 600; atomic replacement.

STATE_FILE="/var/tmp/nixos-setup.state"
DONE=0
COMPLETED_STEP="none"

save_state() {
  [[ $DONE -eq 1 || "${DRY_RUN:-0}" -eq 1 ]] && return 0
  [[ -n "${SELECTED_HOST:-}" || -n "${INSTALL_DISK:-}" ]] || return 0
  local dir="${STATE_FILE%/*}" tmp
  tmp="$(mktemp "$dir/.nixos-setup.state.XXXXXX")" || return 0
  {
    printf 'SELECTED_HOST=%s\n' "${SELECTED_HOST:-}"
    printf 'INSTALL_DISK=%s\n' "${INSTALL_DISK:-}"
    printf 'ENABLE_LUKS=%s\n' "${ENABLE_LUKS:-0}"
    printf 'ENABLE_TPM2=%s\n' "${ENABLE_TPM2:-0}"
    printf 'ENABLE_SECURE_BOOT=%s\n' "${ENABLE_SECURE_BOOT:-0}"
    printf 'SKIP_WIPE=%s\n' "${SKIP_WIPE:-0}"
    printf 'BACKUP_DEV=%s\n' "${BACKUP_DEV:-}"
    printf 'TARGET_USER=%s\n' "${TARGET_USER:-}"
    printf 'COMPLETED_STEP=%s\n' "$COMPLETED_STEP"
  } > "$tmp" 2>/dev/null || { rm -f -- "$tmp"; return 0; }
  chmod 600 "$tmp" 2>/dev/null || { rm -f -- "$tmp"; return 0; }
  mv -fT -- "$tmp" "$STATE_FILE" 2>/dev/null || { rm -f -- "$tmp"; return 0; }
}

load_state() {
  [[ -f "$STATE_FILE" && ! -L "$STATE_FILE" && -O "$STATE_FILE" ]] || return 1
  [[ "$(stat -c '%u:%a' -- "$STATE_FILE" 2>/dev/null)" == "$EUID:600" ]] || return 1

  local line key value
  local selected_host="" install_disk="" enable_luks=0 enable_tpm2=0
  local enable_secure_boot=0 skip_wipe=0 backup_dev="" target_user="" completed_step=""
  local -A seen=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == *=* ]] || return 1
    key="${line%%=*}"
    value="${line#*=}"
    [[ "$value" != *'='* ]] || return 1
    # Older state files used printf %q; these fields only needed quoting when empty.
    [[ "$value" == "''" ]] && value=""
    case "$key" in
      SELECTED_HOST)
        [[ -z ${seen[SELECTED_HOST]+x} && "$value" =~ ^[a-zA-Z0-9_-]*$ ]] || return 1
        seen[SELECTED_HOST]=1; selected_host="$value" ;;
      INSTALL_DISK)
        [[ -z ${seen[INSTALL_DISK]+x} && ( -z "$value" || "$value" =~ ^(/dev/(sd|vd|hd)[a-z]+|/dev/nvme[0-9]+n[0-9]+|/dev/mmcblk[0-9]+)$ ) ]] || return 1
        seen[INSTALL_DISK]=1; install_disk="$value" ;;
      ENABLE_LUKS)
        [[ -z ${seen[ENABLE_LUKS]+x} && "$value" =~ ^[01]$ ]] || return 1
        seen[ENABLE_LUKS]=1; enable_luks="$value" ;;
      ENABLE_TPM2)
        [[ -z ${seen[ENABLE_TPM2]+x} && "$value" =~ ^[01]$ ]] || return 1
        seen[ENABLE_TPM2]=1; enable_tpm2="$value" ;;
      ENABLE_SECURE_BOOT)
        [[ -z ${seen[ENABLE_SECURE_BOOT]+x} && "$value" =~ ^[01]$ ]] || return 1
        seen[ENABLE_SECURE_BOOT]=1; enable_secure_boot="$value" ;;
      SKIP_WIPE)
        [[ -z ${seen[SKIP_WIPE]+x} && "$value" =~ ^[01]$ ]] || return 1
        seen[SKIP_WIPE]=1; skip_wipe="$value" ;;
      BACKUP_DEV)
        [[ -z ${seen[BACKUP_DEV]+x} && ( -z "$value" || "$value" =~ ^(/dev/(sd|vd|hd)[a-z]+|/dev/nvme[0-9]+n[0-9]+|/dev/mmcblk[0-9]+)$ ) ]] || return 1
        seen[BACKUP_DEV]=1; backup_dev="$value" ;;
      TARGET_USER)
        [[ -z ${seen[TARGET_USER]+x} && ( -z "$value" || "$value" =~ ^[a-z_][a-z0-9_-]*$ ) ]] || return 1
        seen[TARGET_USER]=1; target_user="$value" ;;
      COMPLETED_STEP)
        [[ -z ${seen[COMPLETED_STEP]+x} && "$value" =~ ^(none|host|user|flags|disk|lukspw|usb|password|zram|backup|partition|deploy)$ ]] || return 1
        seen[COMPLETED_STEP]=1; completed_step="$value" ;;
      *) return 1 ;;
    esac
  done < "$STATE_FILE"

  [[ ${#seen[@]} -eq 9 && ( "$enable_tpm2" == 0 || "$enable_luks" == 1 ) && ( "$enable_secure_boot" == 0 || "$enable_luks" == 1 ) ]] || return 1
  SELECTED_HOST="$selected_host"
  INSTALL_DISK="$install_disk"
  ENABLE_LUKS="$enable_luks"
  ENABLE_TPM2="$enable_tpm2"
  ENABLE_SECURE_BOOT="$enable_secure_boot"
  SKIP_WIPE="$skip_wipe"
  BACKUP_DEV="$backup_dev"
  TARGET_USER="$target_user"
  COMPLETED_STEP="$completed_step"
}

clear_state() { rm -f "$STATE_FILE"; }

mark_done() { COMPLETED_STEP="$1"; save_state; }
