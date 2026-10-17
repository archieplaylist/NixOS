#!/bin/sh
# gross eww/scripts/airplane_mode.sh — `nmcli n` toggles all radios.
status=$(nmcli n | grep -oE 'enabled|disabled')
if [ "$status" = "enabled" ]; then
    nmcli n off
else
    nmcli n on
fi
