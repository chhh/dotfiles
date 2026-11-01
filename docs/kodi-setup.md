# Kodi on Raspberry Pi 5 — Setup as Main UI

Target: RPi 5, RPi OS Bookworm (64-bit), used as Amnezia WG server + Kodi media center on TV.
Kodi becomes main UI, auto-boots fullscreen. VPN server keeps running headless.

---

## 1. Install Kodi

```bash
sudo apt update && sudo apt install kodi
```

WG server (systemd service) unaffected. Kodi is user-space.

Verify:
```bash
kodi --version
```

## 2. Hardware acceleration (V4L2)

Kodi → **Settings → Player → Videos → Processing**:
- **Allow hardware acceleration: V4L2** (or "V4L2 / DRM Prime")

Not VAAPI. RPi has no VAAPI — the `libva error: vaGetDriverNames() failed` message at startup is noise, ignore it.

Verify after: play video, check CPU stays low.

```bash
top
```

H.264/H.265 under ~20% CPU = decode working. ~100% = software decode.

## 3. Set Kodi as main UI (auto-boot, no desktop)

Kodi is the only UI. Drop the desktop — it's dead weight on a TV.
Pi's other job (WG VPN server) is headless via SSH, so nothing is lost.

### 3a. Boot to console

```bash
sudo raspi-config
# System Options → Boot → Console Autologin
```

### 3b. systemd service for Kodi standalone

```bash
sudo systemctl edit --force --full kodi.service
```

Paste:

```ini
[Unit]
Description=Kodi
After=network.target

[Service]
User=chhh
ExecStart=/usr/bin/kodi --standalone
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

(Replace `User=chhh` with the actual user if different.)

Enable + reboot:

```bash
sudo systemctl enable kodi.service
sudo reboot
```

Result: boot → Kodi fullscreen raw (KMS/DRM direct, no desktop, no panel, no Wayland). VPN server still runs.

### Why standalone (not `kodi` in desktop)

RPi OS Bookworm desktop = Wayland. Panel is a layer-shell surface, always on top.
Kodi runs through XWayland, so its "fullscreen" can't cover the panel.
`kodi --standalone` drives the screen directly via KMS/DRM — true fullscreen, no panel.

## 4. HDMI-CEC (TV remote)

Kodi → **Settings → System → Input → Peripherals → CEC**:
- Enable CEC adapter

TV remote arrow keys / OK / back work over HDMI-CEC.

Note: LG Magic Remote pointer (air mouse) does NOT work. Pointer coords are RF remote→TV only; CEC carries button presses only. Use the phone app **Kore** or a USB wireless mouse/keyboard for pointer control.

Kore setup: **Settings → Services → Control → Allow remote control via HTTP** (default on), then Kore app auto-discovers.

## 5. Mount Synology DS418 via NFS

### 5a. DSM side

1. **Control Panel → File Services → NFS** → Enable
2. **Control Panel → Shared Folder** → pick video share → **Edit → NFS Permissions → Create**:
   - Hostname/IP: RPi IP (`hostname -I`)
   - Squash: **No mapping** (switch to "Map all users to admin" if permission denied)
   - Security: `sys`
   - Tick **"Allow connections from non-privileged ports"**
3. Note export path: `/volume1/videos` (DSM shows it)

### 5b. RPi side

```bash
showmount -e 192.168.1.50    # Synology IP, lists shares
```

Mount test:

```bash
sudo mkdir -p /mnt/videos
sudo mount -t nfs 192.168.1.50:/volume1/videos /mnt/videos
df -h /mnt/videos
```

Permanent (fstab, mount on demand — no boot hang if NAS offline):

```bash
echo '192.168.1.50:/volume1/videos  /mnt/videos  nfs  defaults,_netdev,noauto,x-systemd.automount  0  0' | sudo tee -a /etc/fstab
```

Replace IP and `/volume1/videos` with actual values.

## 6. Add media source in Kodi

**Settings → Media → Videos → Add source → Browse → Root filesystem → /mnt/videos**

Set content type (Movies/TV) for metadata scraping, or "None" for plain folder browsing.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `libva error: vaGetDriverNames() failed` | Ignore. VAAPI not on RPi. Use V4L2. |
| Taskbar visible in "fullscreen" | Wayland panel layer. Use `--standalone` (section 3), or auto-hide panel. |
| Kodi hangs on launch from SSH, no UI | No DISPLAY over SSH → Kodi grabbed KMS directly, works but no input from SSH. Run `--standalone` via service (section 3). |
| Permission denied on mount | DSM NFS rule: change Squash to "Map all users to admin". |
| NAS offline hangs boot | Already handled: `x-systemd.automount` mounts on demand. |

## Order of operations

1. Install Kodi (1)
2. Set V4L2 accel (2)
3. Set standalone service + reboot (3)
4. Verify CEC remote (4)
5. Enable NFS on DSM + mount (5)
6. Add source in Kodi (6)
