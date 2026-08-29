# GNOME Backups

Timestamped bundles from `gnome-backup` (installed as `~/.local/bin/gnome-backup` via `modules/home/scripts/gnome-backup`).

Each `gnome-backup-*.tar.gz` contains:
- `dconf-full.dconf` (`dconf dump /`)
- `dconf-gnome.dconf` (`dconf dump /org/gnome/`)
- `dconf-shell.dconf` + keybindings/mutter
- `extensions.txt` + `extensions.tar.gz` (user extensions)
- `manifest.txt`

Usage (from any checkout):
```bash
gnome-backup list
gnome-backup show ./backups/gnome/gnome-backup-*.tar.gz
gnome-backup diff ./backups/gnome/gnome-backup-*.tar.gz
gnome-backup restore ./backups/gnome/gnome-backup-*.tar.gz --dry-run
gnome-backup restore ./backups/gnome/gnome-backup-*.tar.gz
# GNOME-only:
gnome-backup restore ./backups/gnome/gnome-backup-*.tar.gz --gnome-only
# Convert to Nix:
gnome-backup to-nix ./backups/gnome/gnome-backup-*.tar.gz --out /tmp/gnome-dconf.nix
```

Default `BACKUP_DIR` is `<repo>/backups/gnome` (detected via `$REPO`/`$NIXOS_REPO`/`~/nixos`/`~/NixOS`/git root), fallback to `$XDG_DATA_HOME/gnome-backups`. Override with `BACKUP_DIR=/path gnome-backup backup`.

After restore, log out/in (Wayland) or `Alt+F2 → r` (X11). On NixOS, imperative `dconf load` may be overwritten by `home-manager` `dconf.settings` on next switch.
