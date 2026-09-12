#!/usr/bin/env bash
# lib/tui.sh — sourced by setup.sh. Prompt backend with TUI ladder.
# API: ask [-m prompt tag item ... default | -s prompt | prompt]
#      confirm "prompt" | tui_backend (echoes backend name)
# Globals read: TUI_MODE (auto|plain|fzf|gum|whiptail), AN_YES_SET.
# ponytail: auto mode never installs anything; plain read always works.

TUI_BACKEND="plain"

init_tui() {
  local mode="${TUI_MODE:-auto}"
  # No TTY on stdin (piped/cron) -> plain reads fail closed, callers guard.
  if [[ "$mode" == "plain" || "$mode" == "no-tui" ]] || [[ ! -t 0 ]]; then
    TUI_BACKEND="plain"
    return 0
  fi
  if [[ "$mode" != "auto" ]]; then
    if have "$mode"; then
      TUI_BACKEND="$mode"
    else
      ensure_tools "$mode"
      have "$mode" && TUI_BACKEND="$mode" || TUI_BACKEND="plain"
    fi
    return 0
  fi
  for b in fzf gum whiptail; do
    if have "$b"; then TUI_BACKEND="$b"; return 0; fi
  done
  TUI_BACKEND="plain"
}

tui_backend() { printf '%s' "$TUI_BACKEND"; }

# ponytail: fzf unusable for secrets/yes-no (no hidden input) -> plain read there.
ask() {
  # Menu form: -m <prompt> <tag> <item> ... <default>
  if [[ $1 == "-m" ]]; then
    local prompt="$2"; shift 2
    local default="${!#}"; set -- "${@:1:$#-1}"
    case "$TUI_BACKEND" in
      fzf)
        local line ans taglist=""
        while [[ $# -gt 0 ]]; do taglist+="$1) $2"$'\n'; shift 2; done
        ans="$(printf '%s' "$taglist" | fzf --height=40% --prompt="$prompt " --select-1 --exit-0 | awk '{print $1}' | tr -d ')')" || return 1
        printf '%s' "${ans:-$default}"
        return 0
        ;;
      gum)
        local -a items; while [[ $# -gt 0 ]]; do items+=("$1) $2"); shift 2; done
        line="$(printf '%s\n' "${items[@]}" | gum choose --header="$prompt")" || return 1
        printf '%s' "${line%%)*}"
        return 0
        ;;
      whiptail)
        local -a wt; while [[ $# -gt 0 ]]; do wt+=("$1" "$2"); shift 2; done
        whiptail --nocancel --menu "$prompt" 20 70 10 "${wt[@]}" "$default" 3>&1 1>&2 2>&3 || return 1
        return 0
        ;;
    esac
    # plain fallback
    echo "$prompt" >&2
    while [[ $# -gt 0 ]]; do
      local tag="$1" item="$2"; shift 2
      printf '  %s) %s\n' "$tag" "$item" >&2
    done
    local ans; read -r -p "pick [$default]: " ans || return 1
    printf '%s' "${ans:-$default}"
    return 0
  fi
  # Password form: -s <prompt> (always plain read; TUI can't hide input)
  if [[ $1 == "-s" ]]; then
    local ans; read -r -s -p "$2: " ans || return 1; echo >&2
    printf '%s' "$ans"
    return 0
  fi
  # Plain input: ask <prompt>
  local ans
  local prompt="${!#}"
  read -r -p "$prompt: " ans || return 1
  printf '%s' "$ans"
}

confirm() {
  # confirm [-y] "prompt": -y makes Enter mean yes ([Y/n]). --yes always 0.
  local def_no=1
  [[ "${1:-}" == "-y" ]] && { def_no=0; shift; }
  [[ $AN_YES_SET -eq 1 ]] && { echo "[yes] $1" >&2; return 0; }
  case "$TUI_BACKEND" in
    whiptail) whiptail --yesno "$1" 10 70 && return 0 || return 1 ;;
    gum) gum confirm "$1" && return 0 || return 1 ;;
  esac
  local answer marker="[y/N]"
  [[ $def_no -eq 0 ]] && marker="[Y/n]"
  while :; do
    read -r -p "$1 $marker " answer || return 1
    case "$answer" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
      "") [[ $def_no -eq 0 ]] && return 0 || return 1 ;;
      *) echo "please answer yes or no" ;;
    esac
  done
}
