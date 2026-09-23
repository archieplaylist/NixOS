# Troubleshooting Guide

This guide helps diagnose and resolve common issues with the NixOS configuration.

## Quick Diagnosis Flowchart

Start here if you're unsure where your issue fits:

```
Is the system booting?
├─ No → Boot & System Issues
└─ Yes → Is it a build/deployment issue?
    ├─ Yes → Build & Deployment Issues
    └─ No → Is it related to desktop environment?
        ├─ Yes → Desktop Environment Issues
        └─ No → Is it networking/services?
            ├─ Yes → Networking & Services Issues
            └─ No → Is it performance-related?
                ├─ Yes → Performance Issues
                └─ No → Hardware-Specific Issues
```

## Build & Deployment Issues

### "error: attribute 'xyz' missing"

**Cause:** Package removed from nixpkgs or typo in package name  
**Symptoms:** Build fails with attribute error during `nix flake check` or `nh os build`  
**Solution:**
```bash
# Check if package exists in nixpkgs
nix search nixpkgs xyz

# Update flake inputs to get latest package definitions
nix flake update

# If package was removed, find alternative
nix search nixpkgs <alternative-name>
```

### "hash mismatch in flake.nix"

**Cause:** flake.lock out of sync with nixpkgs or other inputs  
**Symptoms:** Hash mismatch errors during build  
**Solution:**
```bash
# Update flake inputs to sync hashes
nix flake update

# Verify all hosts still build
make check
```

### "error: connection timeout"

**Cause:** Network issues or binary cache down  
**Symptoms:** Build fails with timeout during download  
**Solution:**
```bash
# Check network connectivity
ping cache.nixos.org

# Check if substituters are accessible
nix-store --verify --check-contents --repair

# Add additional substituters (in /etc/nixos/configuration.nix or flake)
nix.settings.substituters = "https://cache.nixos.org https://nix-community.cachix.org"

# Build without binary cache (slower but works offline)
nix build --no-substitutes
```

### "store operation failed"

**Cause:** Disk space issues or Nix store permissions  
**Symptoms:** Store operation errors during build  
**Solution:**
```bash
# Check disk space
df -h /nix

# Garbage collect old generations
nh clean all

# Manual garbage collection
nix-collect-garbage -d

# Check Nix store permissions
ls -la /nix/var/nix/db
sudo chown -R root:nix /nix/var/nix/db
```

### "error: experimental feature 'nix-command' is disabled"

**Cause:** Nix configuration missing experimental features  
**Symptoms:** Commands like `nix flake` fail  
**Solution:**
```bash
# Add to /etc/nixos/configuration.nix:
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
};

# Or for single-user (not recommended for this config):
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

## Boot & System Issues

### System won't boot after switch

**Cause:** Kernel panic, config error, or bootloader issue  
**Symptoms:** Black screen, kernel panic, boot loop  
**Solution:**
```bash
# Use bootloader menu to select previous generation
# (Reboot and select previous generation from systemd-boot menu)

# Once booted into previous generation, rollback
nh os rollback

# Check journal for errors from failed boot
journalctl -b -1 -p err

# If rollback fails, boot from USB and chroot:
sudo mount /dev/disk/by-label/nixos-root /mnt
sudo chroot /mnt
nh os switch
```

### LUKS passphrase not accepted

**Cause:** TPM2 enrolled but PCR changed, or wrong passphrase  
**Symptoms:** "Key slot unavailable" or passphrase rejected at boot  
**Solution:**
```bash
# Boot with passphrase (fallback always available)

# Re-enroll TPM2 if PCR changed (after boot)
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+8 \
  --wipe-slot=tpm2 /dev/disk/by-label/nixos-root

# Reset passphrase if forgotten (requires live USB)
# Boot from USB, open LUKS:
cryptsetup open /dev/disk/by-label/nixos-root cryptroot
# Mount and chroot, then reset password
```

### "error: GPT does not support boot"

**Cause:** BIOS boot mode mismatch (UEFI vs BIOS)  
**Symptoms:** Bootloader installation fails  
**Solution:**
```bash
# Check current boot mode
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "BIOS"

# This config assumes UEFI boot (boot.loader.systemd-boot.enable)
# Ensure system is booted in UEFI mode

# For BIOS systems, you would need GRUB (not currently in this config)
# Consider switching to UEFI if hardware supports it
```

### System freezes randomly

**Cause:** OOM killer, kernel bug, or hardware issue  
**Symptoms:** System becomes unresponsive, requires hard reset  
**Solution:**
```bash
# Check OOM killer activity
journalctl -k | grep -i oom

# Check earlyoom status (should be enabled)
systemctl status earlyoom

# Check kernel errors
journalctl -k | grep -i "hardware error"
dmesg | grep -i error

# Check memory usage
free -h
vmstat 1 5

# If hardware errors, check hardware:
# - Run memtest86+ for RAM issues
# - Check SMART status for disk issues
sudo smartctl -a /dev/sda
```

### Boot takes very long time

**Cause:** Slow filesystem, failed services, or network timeout  
**Symptoms:** System boots but takes several minutes  
**Solution:**
```bash
# Check boot time
systemd-analyze

# Check which services are slow
systemd-analyze blame

# Check for failed services
systemctl --failed

# Check journal for boot errors
journalctl -b -0 -p err

# Common fixes:
# - Check network timeout in NetworkManager
# - Disable slow services temporarily
# - Check filesystem health
sudo xfs_repair -n /dev/disk/by-label/nixos-root
```

## Desktop Environment Issues

### GNOME extensions not loading

**Cause:** Extension version mismatch or missing dependencies  
**Symptoms:** Extensions disabled or errors in GNOME Shell  
**Solution:**
```bash
# Check installed extensions
gnome-extensions list

# Check extension errors
journalctl --user -f | grep -i gnome-shell

# Rebuild with correct extensions
# Verify mySystem.gnomeExtensions in host file matches available packages
make check && nh os switch -H <host>

# Manually enable extensions if needed
gnome-extensions enable <extension-uuid>
```

### Switching DEs breaks applications

**Cause:** Missing dependencies or config conflicts  
**Symptoms:** Applications fail to start after DE switch  
**Solution:**
```bash
# Always backup before switching
~/.local/bin/switch-de backup gnome

# Check for config conflicts in home directory
ls -la ~/.config/

# Review DE-specific settings that might conflict
# Some apps store DE-specific configs

# Restore if needed
~/.local/bin/switch-de restore backups/gnome/gnome-*.dconf
```

### Niri: Wayland applications crash

**Cause:** Missing XWayland or portal issues  
**Symptoms:** X11 applications fail in Niri  
**Solution:**
```bash
# Check XWayland satellite is running
ps aux | grep xwayland-satellite

# Check portal configuration
# Verify xdg.portal settings in modules/features/desktop.nix

# Restart Niri (logout/login)
# Or restart user services
systemctl --user restart niri

# Check portal logs
journalctl --user -u xdg-desktop-portal
```

### Plasma: SDDM won't start

**Cause:** Graphics driver or configuration issue  
**Symptoms:** Stuck at SDDM login screen or black screen  
**Solution:**
```bash
# Switch to TTY (Ctrl+Alt+F3) and check logs
journalctl -u sddm

# Check graphics driver
# Verify hardware.graphics.enable32Bit for gaming in hardware.nix

# Rebuild system
nh os switch -H <host>

# If SDDM service fails, check dependencies
systemctl status sddm
journalctl -xe
```

### XFCE: settings reset to defaults after rebuild/switch

**Cause:** Xfce settings live in two layers, and only one of them is Nix-owned.
User values in `~/.config/xfce4/xfconf/xfce-perchannel-xml/` override the
declarative system defaults in `/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/`
(sources: `modules/home/assets/xfce/`) plus the copy-if-missing seed from
`home.activation.seedXfceDefaults`. A plain `nh os switch` never deletes the
user layer — if settings vanished, something else moved or replaced the files.
**Diagnostics (in order):**
```bash
# 1. switch-de archives the DE you leave into ~/.local/share/de-archive/<de>/
#    and only restores the target if the archive still exists
ls ~/.local/share/de-archive/

# 2. home-manager renames files it newly owns instead of overwriting them
find ~/.config -name '*.hm-backup'   # e.g. user-dirs.dirs, easyeffects presets

# 3. build-vm guests keep their disk (nixos.qcow2) in the launch directory —
#    a different CWD (or a reverted VirtualBox snapshot) boots a fresh home
ls *.qcow2; VBoxManage snapshot "NixOS" list

# 4. check what the system layer actually provides right now
ls /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ /etc/xdg/xfce4/panel/
```
**Notes:**
- Per-monitor wallpaper keys can't be predetermined (RandR names differ between
  qemu/VirtualBox), so the wallpaper is intentionally NOT in the system defaults:
  set it once in the GUI; it persists in the user file, which `backup-de backup xfce`
  covers going forward.
- To re-adopt a changed Nix default, delete the corresponding user channel file
  (user values always shadow system ones), then rebuild + relogin:
  `rm ~/.config/xfce4/xfconf/xfce-perchannel-xml/<channel>.xml`
- GTK theme packages (`orchis-theme`, `tela-circle-icon-theme`, `bibata-cursors`)
  are installed by `desktops/xfce.nix`; the theme *selection* is the `xsettings.xml`
  default, overridable in Appearance.

### Screen tearing in games

**Cause:** V-Sync or compositor settings  
**Symptoms:** Visual tearing during gaming  
**Solution:**
```bash
# For GNOME: disable automatic screen workarounds
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

# For Niri: check compositor settings in config.kdl

# For gaming: use gamescope (already configured)
# Launch games through gamescope for frame pacing
```

## Networking & Services Issues

### Tailscale not connecting

**Cause:** Firewall, authentication, or configuration  
**Symptoms:** Tailscale status shows offline or connection refused  
**Solution:**
```bash
# Check Tailscale status
sudo tailscale status

# Check Tailscale service
systemctl status tailscaled

# Check firewall rules
sudo iptables -L -n | grep tailscale

# Restart Tailscale
sudo systemctl restart tailscaled

# Reauthenticate if needed
sudo tailscale up --reset

# Check if operator rights are set (for primary user)
# Should be handled by systemd service in base.nix
```

### Sunshine streaming fails

**Cause:** Capabilities, network, or Wayland issues  
**Symptoms:** Connection timeout, black screen, or Sunshine won't start  
**Solution:**
```bash
# Check Sunshine logs
journalctl --user -u sunshine

# Check capabilities (capSysAdmin required)
getcap $(which sunshine)

# Verify Tailscale tunnel (if using)
sudo tailscale status

# Check firewall (Sunshine opens ports automatically)
sudo iptables -L -n | grep sunshine

# Restart Sunshine
systemctl --user restart sunshine

# Test without Tailscale temporarily
# Disable firewall for testing (not recommended for production)
```

### Docker containers can't access network

**Cause:** Docker networking or firewall rules  
**Symptoms:** Containers have no network access  
**Solution:**
```bash
# Check Docker service
systemctl status docker

# Check Docker network
docker network ls
docker network inspect bridge

# Restart Docker
systemctl restart docker

# Check firewall for Docker rules
sudo iptables -L -n | grep DOCKER

# Test container networking
docker run --rm alpine ping -c 3 8.8.8.8
```

### SSH connection refused

**Cause:** SSH service, firewall, or key authentication  
**Symptoms:** "Connection refused" or "Permission denied"  
**Solution:**
```bash
# Check SSH service
systemctl status sshd

# Check firewall
sudo iptables -L -n | grep 22

# Check SSH config
# Verify mySystem.enableSSH and sshAuthorizedKeys in host file

# Test with password auth (if enabled)
ssh user@host -o PreferredAuthentications=password

# Check SSH logs
journalctl -u sshd

# Regenerate host keys if needed
sudo ssh-keygen -A
```

### Wi-Fi not connecting

**Cause:** Driver issues, NetworkManager configuration, or firmware  
**Symptoms:** Wi-Fi won't connect or no networks found  
**Solution:**
```bash
# Check NetworkManager status
systemctl status NetworkManager

# Check available Wi-Fi networks
nmcli device wifi list

# Check Wi-Fi device
nmcli device

# Restart NetworkManager
systemctl restart NetworkManager

# Check for firmware issues
# Intel Wi-Fi firmware is usually included, but check:
lspci | grep -i wireless
```

### DNS resolution fails

**Cause:** DNS configuration or network issues  
**Symptoms:** Can't resolve hostnames, IP addresses work  
**Solution:**
```bash
# Check DNS configuration
systemd-resolve --status

# Test DNS resolution
nslookup google.com
dig google.com

# Check /etc/resolv.conf
cat /etc/resolv.conf

# Try alternative DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Restart NetworkManager
systemctl restart NetworkManager
```

## Performance Issues

### System feels sluggish

**Cause:** Swap thrashing, CPU governor, or missing optimizations  
**Symptoms:** High load average, slow response times  
**Solution:**
```bash
# Check system load
uptime
top

# Check swap usage
free -h
swapon --show

# Check zram (should be enabled)
zramctl

# Check ananicy-cpp (should be running on non-VM)
systemctl status ananicy-cpp

# Check CPU governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Verify kernel tuning (from base.nix)
sysctl vm.swappiness vm.page-cluster vm.vfs_cache_pressure

# Check if earlyoom is active (should prevent freezes)
systemctl status earlyoom
```

### Gaming performance poor

**Cause:** GPU drivers, PipeWire latency, or missing 32-bit libs  
**Symptoms:** Low FPS, stuttering in games  
**Solution:**
```bash
# Check GPU drivers
# Verify hardware.graphics.enable32Bit for gaming in hardware.nix

# Check PipeWire low-latency config
# Verify 48kHz/128 quantum settings in gaming.nix

# Check GameMode status
gamemoded -r

# Check MangoHud configuration
# Verify MangoHud.conf in apps.nix

# Test without gamescope
# Launch game directly through Steam for comparison

# Check CPU governor (should be performance when gaming)
powerprofilesctl set performance
```

### Audio latency or crackling

**Cause:** PipeWire configuration or buffer size  
**Symptoms:** Audio pops, clicks, or delay  
**Solution:**
```bash
# Check PipeWire status
systemctl --user status pipewire pipewire-pulse wireplumber

# Check low-latency config (from gaming.nix)
# Verify 48kHz/128 quantum settings

# Restart PipeWire
systemctl --user restart pipewire wireplumber

# Test with different buffer sizes
# Adjust quantum in gaming.nix if needed

# Check EasyEffects if enabled
# Verify configuration in modules/home/easyeffects.nix
```

### High CPU usage

**Cause:** Background process, runaway process, or misconfiguration  
**Symptoms:** System slow, fans loud  
**Solution:**
```bash
# Check CPU usage
top
htop

# Find CPU-intensive processes
ps aux --sort=-%cpu | head

# Check systemd services
systemctl --type=service --state=running

# Check for specific services
systemctl status ananicy-cpp
systemctl status earlyoom

# If specific process is problematic, restart it
# or investigate its configuration
```

### Disk I/O slow

**Cause:** Fragmentation, failing disk, or misconfiguration  
**Symptoms:** Slow file operations, system lag  
**Solution:**
```bash
# Check disk health
sudo smartctl -a /dev/sda

# Check disk I/O
iostat -x 1

# Check filesystem
sudo xfs_repair -n /dev/disk/by-label/nixos-root

# Check mount options
mount | grep nixos-root

# Verify noatime option is set (should be from filesystems.nix)
```

## Hardware-Specific Issues

### VirtualBox guest fails on kernel 6.12+

**Cause:** drm_fb_helper_alloc_info removed from kernel  
**Symptoms:** VirtualBox guest additions fail to build  
**Solution:**
```bash
# Temporary patch is in hardware.nix (lines 46-60)
# This patches the VirtualBox kernel module for compatibility

# Monitor for upstream fix in VirtualBox >7.2.16 / kernel >6.18
# Once fixed, remove the patch from hardware.nix

# Check current kernel version
uname -r

# If patch fails, use stable kernel instead
# Change linuxPackages_latest to linuxPackages in host file
```

### Intel GPU not working

**Cause:** Missing drivers or microcode  
**Symptoms:** Poor graphics performance or no acceleration  
**Solution:**
```bash
# Check Intel GPU
lspci | grep -i vga

# Check Intel microcode (should be enabled in hardware.nix)
# Verify hardware.cpu.intel.updateMicrocode

# Check Intel drivers (should be in hardware.nix)
# Verify intel-media-driver and intel-vaapi-driver

# Test video acceleration
vainfo

# Check if GPU is being used
glxinfo | grep "OpenGL renderer"
```

### Laptop battery drains quickly

**Cause:** Power management not optimized  
**Symptoms:** Poor battery life  
**Solution:**
```bash
# Check power-profiles-daemon (should be enabled)
systemctl status power-profiles-daemon
powerprofilesctl list

# Set power profile
powerprofilesctl set power-saver

# Check battery usage
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# Check laptop-specific settings
# Verify mySystem.enableLaptop in host file

# Check TLP (if using instead of ppd)
systemctl status tlp

# Check screen brightness
# Reduce brightness for battery life
```

### Bluetooth not working

**Cause:** Service not enabled or driver issues  
**Symptoms:** Bluetooth adapter not found or won't connect  
**Solution:**
```bash
# Check Bluetooth service
systemctl status bluetooth

# Check Bluetooth adapter
bluetoothctl list

# Check hardware
lsusb | grep -i bluetooth

# Restart Bluetooth
systemctl restart bluetooth

# Check Bluetooth settings in desktop.nix
# Verify hardware.bluetooth and services.blueman for non-Plasma

# Test Bluetooth
bluetoothctl power on
bluetoothctl scan on
```

### Audio not working

**Cause:** PipeWire, driver, or configuration issue  
**Symptoms:** No sound output or input  
**Solution:**
```bash
# Check PipeWire status
systemctl --user status pipewire pipewire-pulse wireplumber

# Check audio devices
pactl list sinks
pactl list sources

# Check audio logs
journalctl --user -u pipewire

# Restart audio
systemctl --user restart pipewire wireplumber

# Check if audio device is recognized
aplay -l
arecord -l

# Test audio
speaker-test
```

### External monitors not detected

**Cause:** GPU driver, monitor configuration, or cable issue  
**Symptoms:** External monitor not detected or wrong resolution  
**Solution:**
```bash
# Check connected monitors
xrandr

# Check GPU driver status
# Verify hardware.graphics in hardware.nix

# Check EDID data
# Monitor detection issues can be driver-related

# For Wayland (GNOME/Niri): check display settings
# For X11: use xrandr to configure

# Check monitor logs
journalctl -k | grep -i drm
```

## Migration & Upgrade Issues

### NixOS version upgrade fails

**Cause:** State version mismatch or deprecated options  
**Symptoms:** Build fails after NixOS version upgrade  
**Solution:**
```bash
# Increment system.stateVersion gradually
# In modules/features/base.nix, change:
system.stateVersion = "26.05"; # to newer version

# Check for deprecated options
nixos-rebuild build --show-trace

# Review NixOS release notes for breaking changes
# https://nixos.org/manual/nixos/stable/release-notes.html

# Test with dry-run first
nh os build -H <host>
```

### Home-manager activation fails

**Cause:** Conflicting file declarations or options  
**Symptoms:** Home-manager switch fails with file conflicts  
**Solution:**
```bash
# Check home-manager activation logs
journalctl --user -u home-manager

# Test home-manager configuration
home-manager switch --flake .#<username>

# Check for conflicting file declarations
# Look for duplicate home.file.* in home modules

# Temporarily remove conflicting modules
# Add them back one by one to identify the issue
```

### Package conflicts after update

**Cause:** Conflicting dependencies or version mismatches  
**Symptoms:** Build fails with dependency conflicts  
**Solution:**
```bash
# Update flake inputs
nix flake update

# Check for conflicting packages
nix-store --query --requisites /run/current-system

# Clean old generations
nh clean all

# If specific package conflict, try:
# - Removing conflicting package temporarily
# - Using different version
# - Checking if package was renamed in nixpkgs
```

### Configuration syntax errors

**Cause:** Nix syntax errors or typos  
**Symptoms:** Build fails with syntax errors  
**Solution:**
```bash
# Format Nix files
nix fmt

# Check syntax
nix-instantiate --parse modules/hosts/<host>.nix

# Use deadnix to find dead code
nix develop --command deadnix .

# Use statix for additional checks
nix develop --command statix check .

# Build with trace for detailed errors
nh os build -H <host> --show-trace
```

## Debugging Tools

### NixOS Debugging

```bash
# Build with debug output
nh os build -H <host> --show-trace

# Check Nix logs
nix log /nix/store/<path>

# Enter nix develop shell
nix develop

# Check store path details
nix path-info /nix/store/<path>

# Search for packages
nix search nixpkgs <package-name>

# Check package dependencies
nix-store --query --requisites /nix/store/<path>
```

### System Logs

```bash
# Check current boot logs
journalctl -b

# Check previous boot logs
journalctl -b -1

# Check specific service
journalctl -u <service-name>

# Check errors only
journalctl -p err

# Real-time log monitoring
journalctl -f

# Check kernel logs
journalctl -k

# Check user service logs
journalctl --user -u <service-name>
```

### Home Manager Debugging

```bash
# Check home-manager activation
journalctl --user -u home-manager

# Test home-manager config
home-manager switch --flake .#<username>

# Check home-manager generations
home-manager generations

# Check home-manager news
home-manager news
```

### Desktop Environment Debugging

```bash
# GNOME Shell logs
journalctl --user -u gnome-shell

# Check GNOME extensions
gnome-extensions list --detailed

# Niri logs
journalctl --user -u niri

# Check X11 logs (if using X11)
~/.local/share/xorg/Xorg.0.log

# Check Wayland logs
journalctl --user -u weston  # or other compositor
```

### Network Debugging

```bash
# Check network interfaces
ip addr

# Check network connections
ss -tulpn

# Check routing table
ip route

# Check DNS resolution
nslookup google.com
dig google.com

# Test connectivity
ping -c 3 8.8.8.8

# Check firewall
sudo iptables -L -n
sudo iptables -L -n -t nat
```

### Performance Monitoring

```bash
# System overview
htop

# Disk I/O
iostat -x 1

# CPU usage
mpstat 1

# Memory usage
free -h

# Process tree
pstree

# GPU usage (if available)
nvidia-smi  # for NVIDIA GPUs
```

## Getting Help

### Information to Collect

When reporting issues, gather this information:

```bash
# System information
fastfetch > system-info.txt
# or
neofetch > system-info.txt

# NixOS version
nixos-version > nixos-version.txt

# Kernel version
uname -r > kernel-version.txt

# Recent errors
journalctl -b -1 -p err > errors.log

# Nix store info
nix-store --query --requisites /run/current-system > packages.txt

# Host configuration
cat /etc/nixos/configuration.nix > config.txt

# Home-manager version
home-manager --version > hm-version.txt

# Flake info
nix flake metadata > flake-info.txt
```

### Where to Get Help

- **NixOS Discourse**: https://discourse.nixos.org/
- **NixOS Matrix**: #nixos on matrix.org
- **NixOS GitHub**: https://github.com/NixOS/nixpkgs/issues
- **Home Manager**: https://github.com/nix-community/home-manager/issues
- **This Project**: Check existing issues or create new one in your repo

### Bug Reporting Template

```markdown
## Description
[Brief description of the issue]

## Steps to Reproduce
1. 
2. 
3. 

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## System Information
- NixOS version: 
- Host: 
- Desktop environment: 
- Kernel version: 
- Username: 

## Configuration
[Paste relevant configuration sections, remove sensitive data]

## Logs
[Paste relevant logs, remove sensitive data]

## Commands Tried
[List commands you've tried to resolve the issue]
```

### Common Commands for Information Gathering

```bash
# Quick system info
fastfetch

# Check NixOS channel
nix-channel --list

# Check flake inputs
nix flake metadata

# Check disk usage
df -h

# Check memory
free -h

# Check CPU
lscpu

# Check GPU
lspci | grep -i vga

# Check audio
aplay -l

# Check network
ip addr
```

### Safety Precautions

When debugging or reporting issues:

1. **Never include secrets**: Remove passwords, API keys, SSH keys from logs
2. **Sanitize configuration**: Remove personal data, hostnames, IPs
3. **Use pastebin services**: For large logs, use gist.github.com or similar
4. **Be specific**: Include exact error messages, steps to reproduce
5. **Search first**: Check if issue already reported before creating new one

---

**Last Updated:** 2026-09-18  
**Configuration Version:** NixOS 26.05  
**Maintained:** As part of the NixOS flake configuration