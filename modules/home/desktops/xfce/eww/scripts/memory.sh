#!/usr/bin/env bash
# Memory% — ported from Saimoomedits/eww-widgets eww/bar/scripts/memory.
printf "%.0f\n" $(free -m | grep Mem: | awk '{print ($3/$2)*100}')
