# Roadmap: username fleksibel (default `mario`, install bisa `alice`)

## Tujuan

Satu opsi username untuk seluruh flake, default `mario` (back-compat, `make check`
tetap hijau). Fresh install bisa set nama lain (misal `alice`) via `setup.sh`;
seluruh config turun dari opsi itu. Copy repo ke mesin lain dengan user beda =
ganti satu baris (atau jawab prompt installer), `nh os switch` jalan.

Non-goals: user beda per host dalam satu flake, migrasi `/home` live otomatis,
identitas git (`archieplaylist`, urusan terpisah).

## Cara kerja

Username jadi opsi `mySystem.username` di host file. Semua yang dulu hardcode
`mario` membaca opsi itu. `setup.sh` saat fresh install tanya nama, tulis ke
host file terpilih, lalu deploy seperti biasa.

Trik `_module.args`: `home-manager.users.<nama>` butuh nama saat evaluasi NixOS,
tapi `mySystem.username` baru ada di dalam evaluasi itu. Maka `outputs.nix`
berhenti menulis `users.mario` statis, dan mengoper isi home-manager
(`config.home.modules.primary`) lewat `_module.args.homeModules`. `base.nix`
(yang memang modul NixOS) mendeklarasikan `home-manager.users.${username}`
secara dinamis. Modul home sudah menerima `osConfig`, jadi identitas
(`home.username`, `homeDirectory`) turun otomatis per host.

## Perubahan file per file

### 1. `modules/features/mySystem.nix` — opsi baru, satu-satunya sumber nama

```nix
username = lib.mkOption {
  type = lib.types.strMatching "^[a-z_][a-z0-9_-]*$";
  default = "mario";
  description = "Primary user for this host.";
};
```

Regex menolak huruf besar / awalan angka; gagal cepat di `nix flake check`,
bukan di tengah aktivasi.

### 2. Rename slot home `mario` → `primary` (6 file, isi sama)

`home/{core,apps,ai,easyeffects}.nix`, `home/desktops/{gnome,niri,xfce}.nix`:
`config.home.modules.mario` → `config.home.modules.primary`. Wajib atomik satu
commit — setengah jalan flake eval jebol total.

### 3. `modules/home/core.nix` — identitas turun dari opsi

```nix
home.username = osConfig.mySystem.username;
home.homeDirectory = "/home/${osConfig.mySystem.username}";
```

### 4. `modules/home/desktops/niri.nix` — wallpaper

`path = "/home/${osConfig.mySystem.username}/Pictures/Wallpapers/wallpaper.jpg"`

### 5. `modules/features/base.nix` — sisi sistem

- `users.users.${config.mySystem.username} = { ... }` (description pakai
  username, tanpa opsi kedua)
- tailscale: `tailscale set --operator=${config.mySystem.username} || true`
- `programs.nh.flake = "/home/${config.mySystem.username}/nixos"`
- blok baru: `home-manager.users.${config.mySystem.username} = { imports =
[ homeModules ]; };` dengan `homeModules` dari `_module.args`

### 6. `modules/outputs.nix` — lepas pin statis

```nix
let primaryHome = config.home.modules.primary; in ...
{ _module.args.homeModules = primaryHome; }
{ home-manager = { useGlobalPkgs = true; useUserPackages = true;
    backupFileExtension = "hm-backup"; }; }
```

Blok `users.mario` dihapus.

### 7. `setup.sh` — kumpul + tulis nama

- Flag `--user=<nama>`, env `NIXOS_USER`, default `mario`. Validasi regex sama,
  lowercase otomatis, prompt ulang bila salah.
- Guided menu tambah baris `User [nama]`. Prompt password pakai `$TARGET_USER`.
- `print_plan` menampilkan `user: ...`.
- Fungsi `patch_username <host>`: flip `mySystem.username = "lama"` → `"baru"`
  via sed, atau sisip sekali setelah baris `mySystem.*` terakhir (pakai helper
  `append_once` yang sudah ada, pola sama dengan `patch_host_flags`).
  Idempoten, ikut confirm flow. Dipanggil di `step_deploy` sebelum copy/rebuild.
- Prioritas: CLI `--user` > state resume > isi host file > default.

### 8. `lib/state.sh` — simpan pilihan (bukan secret, aman)

Tambah `TARGET_USER` di blok `save_state`/`load_state`.

### 9. Kosmetik

`flake.nix` deskripsi generik, `README.md` (`home.modules.primary`,
`passwd $USER`), `tui.sh` backtitle `nixos-setup`, komentar
`work.nix`/`options.nix` dinetralkan.

## Alur fresh install sebagai `alice`

1. Boot ISO, `sudo ./setup.sh --user=alice` (atau jawab prompt `User`).
2. Pilih host, disk, password seperti biasa. Review menampilkan `user: alice`.
3. Confirm: `patch_username` menulis `mySystem.username = "alice";` ke host
   file, copy tree ke `/mnt/etc/nixos`, hash password ke
   `/mnt/etc/hashed-password`, `nixos-install`.
4. Reboot, login `alice`. Semua turun: user sistem, `/home/alice`,
   home-manager, operator tailscale, path `nh`.

## Alur pindah mesin

Repo sama, tiap host file memegang `username` sendiri. `desktop.nix` tetap
`mario`, host baru isi `bob`. Yang tetap manual di mesin baru:

- Password: `/etc/hashed-password` tidak di git. Isi manual
  (`openssl passwd -6 | sudo tee`) atau via `setup.sh`.
- Clone di `~/nixos`: `programs.nh.flake` menginterpolasi
  `/home/<user>/nixos`. Clone di path lain = `nh` mencari flake yang salah.
- Tailscale: `tailscale up` ulang, sesi tidak pindah mesin.
- TPM2/Secure Boot: kunci terikat PCR mesin lama. Enroll ulang di mesin baru.
- Disk: filesystem pakai label (`nixos-root`) jadi aman bila label sama. Disko
  device default `/dev/sda`, override bila disk beda.

## Kenapa config hardcode rusak untuk user baru hari ini

Fresh install sebagai `alice` dengan config sekarang: sistem membuat user
`mario` saja (`alice` tak ada, tak bisa login), home-manager hanya mengelola
`/home/mario`, `programs.nh.flake=/home/mario/nixos` jadi path mati,
`tailscale set --operator=mario` membuat `alice` tak bisa kelola tailscale
tanpa sudo, wallpaper niri menunjuk `/home/mario/...` yang tak ada.

## Verifikasi

1. `nix fmt`
2. `make check` — 4 host build dengan default
3. `grep -rn mario modules/ lib/ setup.sh` — sisa hanya default/komentar
4. `./setup.sh --dry-run --user=alice` — tampil plan, nol perubahan
5. Satu kali build uji override username di `vm`, lalu revert (jamin
   interpolasi tak typo — `make check` tak mengcover path `alice`)
6. `nh os build -H vm`

## Risiko sisa

Hampir nol untuk fresh install (scope roadmap ini). Live rename tidak
didukung: `/home` lama jadi yatim (file tetap di disk sebagai UID tanpa nama,
home baru kosong — config app, dconf, keyring, flatpak user-level tidak ikut),
user lama terhapus saat rebuild, password lama terbawa (wajib `passwd` ulang).
Installer mencetak warning bila nama target beda dari `/home/*` yang ada.
Tanpa migrasi otomatis (YAGNI).
