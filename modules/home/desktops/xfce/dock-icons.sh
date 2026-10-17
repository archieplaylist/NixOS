#!/usr/bin/env bash
# Dock launcher glyphs — single Nerd Font icon per click-to-launch module
# (polybar.ini [module/launch-*]). Codepoints verified against the installed
# JetBrainsMono Nerd Font (FontAwesome/Seti ranges).
case "$1" in
  term) printf '\ue795' ;;   # seti terminal
  web) printf '\uf269' ;;    # firefox
  files) printf '\uf07b' ;;  # folder
  grid) printf '\uf009' ;;   # app grid -> rofi
  *) printf '\uf009' ;;
esac
