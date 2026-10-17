#!/usr/bin/env bash
# Memory totals — ported from Saimoomedits/eww-widgets eww/bar/scripts/mem-ad.
total="$(free -m | grep Mem: | awk '{ print $2 }')"
used="$(free -m | grep Mem: | awk '{ print $3 }')"
free="$(expr $total - $used)"

if [ "$1" = "total" ]; then
    echo $total
elif [ "$1" = "used" ]; then
    echo $used
elif [ "$1" = "free" ]; then
    echo $free
fi
