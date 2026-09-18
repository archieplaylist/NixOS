# Roadmap: Username Flexibility (COMPLETED ✅)

## Status: COMPLETED ✅

All items from the original roadmap have been successfully implemented and verified on 2026-09-18.

## Overview

This roadmap implemented flexible username support for the NixOS configuration, allowing fresh installs with custom usernames and per-host username configuration via `mySystem.username`.

## Implementation Summary

### Core Changes:
- ✅ `mySystem.username` option with regex validation in `modules/features/mySystem.nix`
- ✅ All home modules use `config.home.modules.primary` (no hardcoded `.mario` slots)
- ✅ Dynamic home-manager user resolution via `_module.args.homeModules` in `modules/outputs.nix`
- ✅ Home modules use `osConfig.mySystem.username` for identity
- ✅ `setup.sh` `--user` flag and `TARGET_USER` variable implementation
- ✅ `patch_username()` function for host file updates
- ✅ State persistence for username selection in `lib/state.sh`

### Verification Results:
- ✅ No hardcoded "mario" references in modules/lib/setup.sh (except defaults and UI prompts)
- ✅ Username override tested on vm host - build successful with alice user
- ✅ All hosts build successfully with default username
- ✅ `nix flake check` passes all checks
- ✅ ROADMAP.md updated to reflect completion status
- ✅ README.md updated with comprehensive username flexibility section

## Usage

See README.md for detailed usage instructions:
- Fresh install with custom username: `sudo ./setup.sh --user=alice`
- Existing system username change (requires manual migration)
- Per-host username configuration

## Technical Details

### Key Architecture Decisions:
- **Dynamic user resolution**: `_module.args.homeModules` passes home-manager content to NixOS level, where `home-manager.users.${username}` is declared dynamically
- **Single source of truth**: `mySystem.username` in host files is the only place username is defined
- **Validation**: Username regex `^[a-z_][a-z0-9_-]*$` prevents invalid usernames
- **State persistence**: Setup script saves username choice for crash recovery

### Non-Goals (Intentionally Not Implemented):
- Multiple users per host within one flake
- Live `/home` migration automation
- Git identity integration (username independent of gitName/gitEmail)

## Verification Steps Completed

1. ✅ `nix fmt` - No formatting issues
2. ✅ `make check` - All 4 hosts build successfully with default username
3. ✅ `grep -rn mario modules/ lib/ setup.sh` - Only default values and UI prompts found, no hardcoded references
4. ✅ Username override test on vm host with `mySystem.username = "alice"` - Build successful (home-manager unit for alice user created)
5. ✅ Reverted test change - All hosts return to default state
6. ✅ `nix flake check` - All checks pass with username override test
7. ✅ ROADMAP.md updated to reflect completion status
8. ✅ README.md updated with comprehensive username flexibility section

## Remaining Limitations

The scope of this roadmap was fresh install flexibility. Live username changes require manual migration:

- `/home` directory migration is manual (old home becomes orphaned)
- User password must be reset manually after username change
- Application configs, dconf settings, keyring data don't automatically migrate
- Old user is removed during rebuild after manual migration
- Installer prints warning if target username differs from existing `/home/*`

These limitations are intentional (YAGNI principle) as live migration is complex and error-prone.

## Completion Date: 2026-09-18

This roadmap has been successfully completed. The NixOS configuration now supports flexible usernames via `mySystem.username` with proper validation, setup.sh integration, and comprehensive documentation.
