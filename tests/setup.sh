#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
setup="$repo/setup.sh"

# --list-hosts returns all host modules
hosts="$(bash "$setup" --list-hosts)"
for h in desktop laptop vm work; do
  grep -qx "$h" <<< "$hosts" || { echo "missing host in --list-hosts: $h" >&2; exit 1; }
done

# --tpm2 and --secure-boot both fail without --luks
if bash "$setup" --tpm2 --dry-run >/dev/null 2>&1; then
  echo "expected --tpm2 without --luks to fail" >&2
  exit 1
fi
if bash "$setup" --secure-boot --dry-run >/dev/null 2>&1; then
  echo "expected --secure-boot without --luks to fail" >&2
  exit 1
fi

# --force-wipe must set ans="WIPE" before the confirmation guard
# shellcheck disable=SC2016
grep -A3 'if \[\[ \$FORCE_WIPE -eq 1 \]\]' "$setup" | grep -q 'ans="WIPE"' || {
  echo "--force-wipe branch does not set ans=\"WIPE\"" >&2
  exit 1
}

# nh os switch must use `-H`, not `.#host`
# shellcheck disable=SC2016
grep -q 'nh os switch \. -H "\$name"' "$setup" || {
  echo "nh os switch does not use '-H \"\$name\"'" >&2
  exit 1
}

echo "setup tests passed"
