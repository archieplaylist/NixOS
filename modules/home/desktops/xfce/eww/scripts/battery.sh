#!/usr/bin/env bash
# Battery state from /sys — ported from Saimoomedits/eww-widgets
# eww/bar/scripts/battery, same shell logic, only the flags renamed.
battery() {
    BAT=`ls /sys/class/power_supply | grep BAT | head -n 1`
    cat /sys/class/power_supply/${BAT}/capacity
}
battery_stat() {
    BAT=`ls /sys/class/power_supply | grep BAT | head -n 1`
    cat /sys/class/power_supply/${BAT}/status
}

if [ "$1" = "--bat" ]; then
    battery
elif [ "$1" = "--bat-st" ]; then
    battery_stat
fi
