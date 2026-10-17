#!/usr/bin/env bash
# Wireless status icon + essid — upstream (Saimoomedits/eww-widgets
# eww/bar/scripts/wifi) grepped a hardcoded wlpXs0 interface; NetworkManager's
# own status is the portable read here.
status=$(nmcli g | grep -oE "disconnected")
essid=$(nmcli -t -f active,ssid dev wifi | sed -n 's/^yes://p' | head -n 1)

if [ -n "$status" ]; then
    icon=""
    text="offline"
    col="#5a6378"
else
    icon=""
    text="${essid}"
    col="#bfbdb6"
fi

case "$1" in
    --COL)   echo $col ;;
    --ESSID) echo $text ;;
    --ICON)  echo $icon ;;
esac
