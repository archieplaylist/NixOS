#!/usr/bin/env bash
# Workspace grid for the eww bar — merger of Saimoomedits/eww-widgets
# eww/bar/scripts/workspace and gross's `works` grid. Both were bspwm-only
# (bspc query/subscribe); xfwm4 has no equivalent socket, so this polls
# wmctrl -d (desktops, `*` = current) and eww's deflisten just re-reads stdin
# on each 1s tick.
workspaces() {
  ws_total=$(wmctrl -d | wc -l)
  current=$(wmctrl -d | awk '$2=="*"{print $1}')
  buf=""
  i=0
  while [ "$i" -lt "$ws_total" ]; do
    if [ "$i" = "$current" ]; then
      cls="works-f"
      glyph=""
    elif [ -n "$(wmctrl -l | awk -v d="$i" '$2==d')" ]; then
      cls="works-o"
      glyph=""
    else
      cls="works-e"
      glyph=""
    fi
    buf="$buf (button :class \"$cls\" :onclick \"wmctrl -s $i\" \"$glyph\")"
    i=$((i + 1))
  done
  echo "(box :class \"works\" :orientation \"h\" :spacing 7 :space-evenly \"false\" $buf)"
}

workspaces
