#!/usr/bin/env bash
# lib/state.sh — sourced by setup.sh. Crash-resume for non-secret choices.
# Saves flags + disk + host + step marker. Never passphrases or hashes.
# ponytail: flat KEY='value' file, sourced back; 600 perms; one trap.

STATE_FILE="${SETUP_STATE_FILE:-/var/tmp/nixos-setup.state}"
DONE=0
COMPLETED_STEP="none"

save_state() {
  [[ $DONE -eq 1 || "${DRY_RUN:-0}" -eq 1 ]] && return 0
  [[ -n "${SELECTED_HOST:-}" || -n "${INSTALL_DISK:-}" ]] || return 0
  {
    printf "SELECTED_HOST=%q\n" "${SELECTED_HOST:-}"
    printf "INSTALL_DISK=%q\n" "${INSTALL_DISK:-}"
    printf "ENABLE_LUKS=%q\n" "${ENABLE_LUKS:-0}"
    printf "ENABLE_TPM2=%q\n" "${ENABLE_TPM2:-0}"
    printf "ENABLE_SECURE_BOOT=%q\n" "${ENABLE_SECURE_BOOT:-0}"
    printf "COMPLETED_STEP=%q\n" "$COMPLETED_STEP"
  } > "$STATE_FILE" 2>/dev/null || return 0
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}

load_state() {
  [[ -f "$STATE_FILE" ]] || return 1
  # ponytail: root-only 600 file written by us; source is the parser.
  # shellcheck disable=SC1090
  source "$STATE_FILE"
}

clear_state() { rm -f "$STATE_FILE"; }

mark_done() { COMPLETED_STEP="$1"; save_state; }
