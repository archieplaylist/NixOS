#!/usr/bin/env bash
# gross-style app search, ported for NixOS: upstream iterated /usr/bin, which
# is nearly empty here. Scans the user profile + system env bins instead and
# echoes a yuck button list that the searchapps widget renders via defpoll.
# Values in gross's own format — write to search_items.txt, not stdout.
# Output lives in ~/.local/state/eww (gross used the config dir, but under
# home-manager that's a read-only store symlink).
q="$1"

files=""
for d in "$HOME/.nix-profile/bin" /run/current-system/sw/bin; do
    [ -d "$d" ] && files="$files $(ls "$d" 2>/dev/null)"
done

buf=""
count=0
for l in $files ; do
    if [ -n "$q" ]; then
        printf '%s' "$l" | grep -qi "$q" || continue
    fi
    buf="$buf (button :class \"item\" :onclick \"$l &\" \"$l\")"
    count=$((count + 1))
    [ "$count" -ge 10 ] && break
done

echo "(box :orientation \"v\" :spacing 5 :class \"apps\" :halign \"center\" :valign \"center\" $buf)" > "${XDG_STATE_HOME:-$HOME/.local/state}/eww/search_items.txt"
