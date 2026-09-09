# DE Backups — ponytail edition

One artifact per backup under `backups/<de>/`, newest 3 kept per pattern:

```bash
backup-de backup [gnome|plasma|xfce|all]     # gnome → .dconf + files tar; plasma/xfce → files tar
backup-de list [gnome|plasma|xfce]
backup-de restore backups/gnome/gnome-*.dconf
backup-de restore backups/<de>/<de>-*.tar.gz  # extracts into $HOME
backup-de restore backups/gnome/gnome-backup-*.tar.gz  # old bundle compat
```

Restore needs relogin. Nix manages extensions declaratively — no tar needed.
Override base dir: `BACKUP_DIR=/tmp backup-de backup`.
