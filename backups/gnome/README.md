# GNOME Backups — ponytail edition

Single file per backup: `dconf dump /org/gnome/ > gnome-*.dconf` (7KB, not 1MB).

```bash
gnome-backup backup                         # → backups/gnome/gnome-YYYYMMDD-HHMMSS.dconf
gnome-backup list                           # ls + line count
gnome-backup restore backups/gnome/gnome-*.dconf
gnome-backup restore backups/gnome/gnome-backup-*.tar.gz  # old bundle compat
```

Restore needs relogin. Nix manages extensions declaratively — no tar needed.
Override dir: `BACKUP_DIR=/tmp gnome-backup backup`.
