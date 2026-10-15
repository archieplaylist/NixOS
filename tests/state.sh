#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
# shellcheck disable=SC1091
source "$repo/lib/state.sh"
STATE_FILE="$tmpdir/state"

SELECTED_HOST=desktop
INSTALL_DISK=/dev/nvme0n1
ENABLE_LUKS=1
ENABLE_TPM2=0
ENABLE_SECURE_BOOT=1
SKIP_WIPE=0
BACKUP_DEV=""
TARGET_USER=mario
COMPLETED_STEP=host
save_state

SELECTED_HOST=""
INSTALL_DISK=""
ENABLE_LUKS=0
ENABLE_SECURE_BOOT=0
TARGET_USER=""
load_state
[[ "$SELECTED_HOST" == desktop && "$INSTALL_DISK" == /dev/nvme0n1 ]]
[[ "$ENABLE_LUKS" == 1 && "$ENABLE_SECURE_BOOT" == 1 && "$TARGET_USER" == mario ]]
[[ "$ENABLE_TPM2" == 0 && "$SKIP_WIPE" == 0 && -z "$BACKUP_DEV" && "$COMPLETED_STEP" == host ]]

printf 'untouched\n' > "$tmpdir/victim"
rm -f -- "$STATE_FILE"
ln -s "$tmpdir/victim" "$STATE_FILE"
save_state
[[ ! -L "$STATE_FILE" && "$(cat "$tmpdir/victim")" == untouched ]]

sentinel="$tmpdir/executed"
cat > "$STATE_FILE" <<EOF
SELECTED_HOST=\$(touch $sentinel)
INSTALL_DISK=
ENABLE_LUKS=0
ENABLE_TPM2=0
ENABLE_SECURE_BOOT=0
SKIP_WIPE=0
BACKUP_DEV=
TARGET_USER=mario
COMPLETED_STEP=host
EOF
chmod 600 "$STATE_FILE"
if load_state; then
  echo "accepted invalid state" >&2
  exit 1
fi
[[ ! -e "$sentinel" ]]

echo "state tests passed"
