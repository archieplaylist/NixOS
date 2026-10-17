#!/bin/sh
# Toggle the gross powermenu dock window (bigpowermenu) from the bar's power
# button. Lock file mirrors upstream's gross dropdown toggle pattern.
LOCK_FILE="$HOME/.cache/eww-powermenu.lock"

if [ ! -f "$LOCK_FILE" ]; then
    touch "$LOCK_FILE"
    eww open bigpowermenu
else
    rm "$LOCK_FILE"
    eww close bigpowermenu
fi
