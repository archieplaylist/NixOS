# Stylix REMOVED 2026-08-21 — theming reverted to per-DE config (Nordic /
# Papirus-Dark / Bibata-Modern-Classic / Noto Sans / JetBrainsMono Nerd Font):
#   modules/home/themes.nix        GTK/icon/cursor/font
#   modules/home/gnome.nix         GNOME shell user-theme
#   modules/home/plasma.nix        Plasma look-and-feel
#   modules/home/xfce.nix          XFCE xfconf
#   modules/features/lightdm.nix   LightDM greeter
# The stylix input + module imports were removed from flake.nix / outputs.nix.
# This file is an inert no-op so the dendritic importTree stays happy; delete
# it whenever convenient.
{ ... }:
{
  config.nixos.modules.stylix = { ... }: { };
  config.home.modules.mario = { ... }: { };
}
