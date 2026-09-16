#!/usr/bin/env bash
# lib/tui.sh — sourced by setup.sh. Prompt backend with TUI ladder.
# API: ask [-m prompt tag item ... default | -s prompt | prompt]
#      confirm "prompt" | note "text" | tui_backend (echoes backend name)
# Globals read: TUI_MODE (auto|plain|gum|whiptail), AN_YES_SET.
# auto mode installs whiptail when missing; plain read always works.

TUI_BACKEND="plain"

init_tui() {
  local mode="${TUI_MODE:-auto}"
  # ayu dark approximation (newt named colors only, no hex):
  # bg #0D1017 = black, fg #BFBDB6 = lightgray, accent #E6B450 = yellow.
  # button=black,yellow: whiptail compact buttons (<Yes>/<No>) draw the FOCUSED
  # one with BUTTON on ANSI terminals, so the highlight must live here.
  # compactbutton=lightgray,black: UNfocused buttons stay calm plain text.
  # (left at default black,white it glares like a selection — looks inverted.)
  export NEWT_COLORS='root=lightgray,black border=yellow,black window=lightgray,black shadow=black,black title=yellow,black button=black,yellow actbutton=black,yellow compactbutton=lightgray,black checkbox=lightgray,black actcheckbox=lightgray,blue entry=lightgray,black label=lightgray,black listbox=lightgray,black actlistbox=white,blue textbox=lightgray,black acttextbox=lightgray,black'
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
  for b in whiptail gum; do
    if have "$b"; then TUI_BACKEND="$b"; return 0; fi
  done
  # one install attempt so ISO gets styled menus free; plain fallback offline
  if [[ "${DRY_RUN:-0}" -eq 0 ]]; then ensure_tools whiptail || true; fi
  have whiptail && TUI_BACKEND="whiptail" || TUI_BACKEND="plain"
}

tui_backend() { printf '%s' "$TUI_BACKEND"; }

ask() {
  # Menu form: -m <prompt> <tag> <item> ... <default>
  if [[ $1 == "-m" ]]; then
    local prompt="$2"; shift 2
    local default="${!#}"; set -- "${@:1:$#-1}"
    case "$TUI_BACKEND" in
      gum)
        local -a items; while [[ $# -gt 0 ]]; do items+=("$1) $2"); shift 2; done
        line="$(printf '%s\n' "${items[@]}" | gum choose --header="$prompt")" || return 1
        printf '%s' "${line%%)*}"
        return 0
        ;;
      whiptail)
        local -a wt; while [[ $# -gt 0 ]]; do wt+=("$1" "$2"); shift 2; done
        whiptail --title "NixOS setup" --backtitle "nixos-setup" --default-item "$default" --menu "$prompt" 22 76 12 "${wt[@]}" 3>&1 1>&2 2>&3 || return 1
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
  # Password form: -s <prompt> (hidden input, backend-styled when possible)
  if [[ $1 == "-s" ]]; then
    local ans
    case "$TUI_BACKEND" in
      gum) ans="$(gum input --password --prompt "$2: ")" || return 1 ;;
      whiptail) ans="$(whiptail --title "NixOS setup" --backtitle "nixos-setup" --passwordbox "$2" 12 76 3>&1 1>&2 2>&3)" || return 1 ;;
      *) read -r -s -p "$2: " ans || return 1; echo >&2 ;;
    esac
    printf '%s' "$ans"
    return 0
  fi
  # Plain input: ask <prompt>
  local ans
  local prompt="${!#}"
  case "$TUI_BACKEND" in
    gum) ans="$(gum input --prompt "$prompt: ")" || return 1 ;;
    whiptail) ans="$(whiptail --title "NixOS setup" --backtitle "nixos-setup" --inputbox "$prompt" 12 76 3>&1 1>&2 2>&3)" || return 1 ;;
    *) read -r -p "$prompt: " ans || return 1 ;;
  esac
  printf '%s' "$ans"
}

confirm() {
  # confirm [-y] "prompt": -y makes Enter mean yes ([Y/n]). --yes always 0.
  local def_no=1
  [[ "${1:-}" == "-y" ]] && { def_no=0; shift; }
  [[ $AN_YES_SET -eq 1 ]] && { echo "[yes] $1" >&2; return 0; }
  case "$TUI_BACKEND" in
    whiptail) whiptail --title "NixOS setup" --backtitle "nixos-setup" --yesno "$1" 12 76 && return 0 || return 1 ;;
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

note() {
  # note "text": info the user cannot miss. whiptail owns the fullscreen and
  # wipes plain stdout/stderr on every dialog, so route through --msgbox there.
  # Plain/gum backends (and dry-run / no TTY) print inline — always visible.
  if [[ "$TUI_BACKEND" == "whiptail" && "${DRY_RUN:-0}" -eq 0 ]] && [[ -t 0 ]]; then
    whiptail --title "NixOS setup" --backtitle "nixos-setup" --msgbox "$1" 20 76 3>&1 1>&2 2>&3 || true
    return 0
  fi
  info "$1"
}
