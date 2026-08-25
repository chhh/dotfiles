# AmneziaWG — self-hosted playbook

Self-hosted AmneziaWG VPN behind a UniFi Dream Machine Pro, running on a
Raspberry Pi 5 (16 GB), to defeat Russian ISP DPI. This is the distilled
playbook from a full end-to-end build, including every gotcha we hit.

---

## 1. Why AmneziaWG

Plain WireGuard has a fixed, detectable wire signature. Russian ISPs (TSPU/SORM
DPI) fingerprint it and block it instantly. AmneziaWG (AWG) is WireGuard plus
**transport-layer obfuscation** — same crypto (Curve25519 + ChaCha20-Poly1305),
same key format — but it:

- randomizes packet headers (H1–H4 "magic header" ranges),
- pads packet sizes (S1–S4),
- injects a "junk train" of random packets before each handshake (Jc/Jmin/Jmax).

The obfuscation is a **disguise, not a secret**. The private keys are the real
security; the junk params just make traffic not look like stock WireGuard.

---

## 2. Architecture

```
mom (AmneziaVPN client, /32 addr)
        │  UDP 45123
        ▼
   pdx.oops.wtf  (afraid.org DDNS → WAN IP)
        ▼
   UDM Pro  — port-forward UDP 45123 → Pi:45123   (existing WG on 51820 untouched)
        ▼
   Raspberry Pi 5 (RPi OS Lite 64-bit)
        ├─ amneziawg-go        (userspace daemon)
        ├─ amneziawg-tools     (awg, awg-quick)
        ├─ ip_forward + MASQUERADE
        └─ awg0  (10.66.66.1/24)
```

Server is on the LAN, **behind** the UDM. The UDM is just a dumb forwarder.
Clients connect to the public hostname, not the Pi directly.

---

## 3. Raspberry Pi — OS + quirks

- **OS**: Raspberry Pi OS **Lite 64-bit** (Bookworm). Headless, no GUI.
- Flash with **Raspberry Pi Imager** → Device: Pi 5 → OS: Raspberry Pi OS Lite
  (64-bit) → gear icon → set hostname, **enable SSH**, username/password,
  optional wifi. Then `ssh user@hostname.local`.
- **RPi quirks:**
  - Ethernet interface is `end0` (Bookworm renamed it from `eth0`); wifi is `wlan0`.
    The MASQUERADE `-o` interface must match `ip route show default`.
  - No AmneziaWG **kernel module** in RPi OS → use **userspace** `amneziawg-go`.
    It survives kernel updates (which land often) with no DKMS rebuild dance.
  - `apt install golang-go` gives Go 1.19 — **too old** (AWG needs 1.25). Install
    Go from go.dev.
  - The "Running amneziawg-go is not required because this kernel has first
    class support" banner is **misleading** — ignore it; the userspace fallback
    is what actually runs.
  - SD cards wear out under 24/7 writes; boot from USB SSD / NVMe HAT if long-term.
  - 16 GB RAM is ~300× overkill; the tunnel uses tens of MB.

---

## 4. Server install (from scratch)

```bash
# 1. Go 1.25 (apt golang-go is 1.19, too old)
cd /tmp
wget https://go.dev/dl/go1.25.0.linux-arm64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.25.0.linux-arm64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/go.sh
source /etc/profile.d/go.sh
go version

# 2. build deps
sudo apt install -y git build-essential pkg-config libmnl-dev

# 3. amneziawg-go (userspace daemon)
git clone https://github.com/amnezia-vpn/amneziawg-go
cd amneziawg-go && make && sudo cp amneziawg-go /usr/local/bin/

# 4. amneziawg-tools (awg + awg-quick + systemd unit)
cd ~
git clone https://github.com/amnezia-vpn/amneziawg-tools
cd amneziawg-tools/src && make && sudo make install

which awg awg-quick amneziawg-go   # all must print a path
```

`awg-quick` falls back to `amneziawg-go` automatically when the kernel module is
absent — no separate daemon step needed.

---

## 5. Server config

File lives at **`/etc/amnezia/amneziawg/awg0.conf`** — NOT `/etc/wireguard/`.
(`awg-quick up awg0` resolves the interface name to that path.)

```ini
[Interface]
Address = 10.66.66.1/24
PrivateKey = <server-priv>
ListenPort = 45123
Jc = 8
Jmin = 354
Jmax = 796
S1 = 49
S2 = 22
S3 = 23
S4 = 15
H1 = 2181475284-2198252499
H2 = 2198252500-2215029715
H3 = 2215029716-2231806931
H4 = 2231806932-2248584147

[Peer]
PublicKey = <client-pub>
AllowedIPs = 10.66.66.2/32
```

Parameter ranges (documented):

| Param | Meaning | Range |
|-------|---------|-------|
| `Jc`  | junk packets before handshake | 0–10 |
| `Jmin`/`Jmax` | junk packet size | 64–1024 |
| `S1`–`S3` | padding: init/resp/cookie | 0–64 |
| `S4`  | padding: data | 0–32 |
| `H1`–`H4` | dynamic headers: init/resp/cookie/data | uint32, `LO-HI` ranges, **must not overlap** |

**Critical: junk params must be byte-identical between the server and every
client.** The server config is the single source of truth — never regenerate it.

Generate keys with `awg genkey` / `awg pubkey` (same as `wg`).

---

## 6. The generator script (`make-awg-configs.sh`)

```bash
./make-awg-configs.sh init [endpoint] [port] [name]   # fresh server + 1 client
./make-awg-configs.sh add-peer <name> [octet]          # add client (octet optional)
./make-awg-configs.sh syncconf                          # install conf + hot reload
./make-awg-configs.sh up | down | restart               # control the tunnel
```

- Server key, junk params, and port are **read from `awg-server.conf`** on every
  run — never regenerated. `add-peer` only creates a new client keypair.
- `<octet>` is the client IP's last octet (`3` → `10.66.66.3/32`); omit for
  next-free.
- Client configs are written as `awg-<name>.conf` with **`/32` addresses**.
- Warns on duplicate octets and subnet-wide `AllowedIPs` overlaps.

Install the generated server conf and start:

```bash
sudo install -m 600 awg-server.conf /etc/amnezia/amneziawg/awg0.conf
./make-awg-configs.sh restart     # == down/up
```

---

## 7. Routing + NAT (the #1 recurring failure)

Two pieces, both must be set **and persisted**:

```bash
# ip_forward
sudo sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-ip-forward.conf

# MASQUERADE (use the Pi's actual uplink: wlan0 on wifi, end0 on ethernet)
IFACE=$(ip route show default | awk '{print $5; exit}')
sudo iptables -t nat -A POSTROUTING -s 10.66.66.0/24 -o "$IFACE" -j MASQUERADE

# persist the iptables rule
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
sudo systemctl enable netfilter-persistent
```

**Gotcha:** `sysctl -w` is runtime-only and resets on reboot. `netfilter-persistent
save` without `systemctl enable netfilter-persistent` does nothing at boot. This
pair silently broke on every reboot until both were persisted. Symptom of it
being broken: tunnel connects (handshake works) but no internet, and `awg show`
shows `received` climbing while `sent` stays near zero.

Autostart the tunnel itself:

```bash
sudo systemctl enable awg-quick@awg0
```

---

## 8. UDM Pro forwarding

1. Give the Pi a **static IP** (UniFi → Clients → Pi → Fixed IP).
2. UniFi → Settings → Security (or Routing & Firewall) → **Port Forwarding**:
   - Protocol: **UDP**, External `45123`, Destination = Pi IP, Internal `45123`.
3. **Port choice:** avoid `51820` (UDM's own WireGuard owns it) and `443` (UDM web
   UI). Use a non-standard high port.

UniFi auto-creates the matching WAN firewall rule. Verify DDNS resolves to the
WAN IP: `dig +short pdx.oops.wtf`.

---

## 9. Client setup

**Download the app from GitHub, not amnezia.org** — amnezia.org is blocked in
Russia.

- Release page: `https://github.com/amnezia-vpn/amnezia-client/releases`
- Ubuntu: `AmneziaVPN_<ver>_linux_x64.run`
- macOS: `AmneziaVPN_<ver>_macos_arm64.pkg` (Apple Silicon) / `_macos_x64.pkg` (Intel)

**Ubuntu install** (crash-on-launch fixes in order):

```bash
sudo apt install -y libxcb-cursor0 libxcb-xinerama0 libxcb-icccm4 \
    libxcb-keysyms1 libopengl0 libxkbcommon-x11-0
chmod +x AmneziaVPN_*_linux_x64.run && ./AmneziaVPN_*_linux_x64.run
# if it dies on launch with "libOpenGL.so.0 cannot open shared object":
sudo apt install -y libopengl0
```

Then AmneziaVPN → **Import configuration** → pick the `awg-<name>.conf`.

**Critical client-config rule:** the `Address` field MUST be a `/32`:

```ini
[Interface]
PrivateKey = <client-priv>
Address = 10.66.66.3/32        # ← /32, never /24
DNS = 1.1.1.1
Jc = 8
# ... same junk params as server ...

[Peer]
PublicKey = <server-pub>
Endpoint = pdx.oops.wtf:45123
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

---

## 10. Quirks & gotchas (hard-won)

1. **The app ignores `Address` with a `/24` mask.** It parses the subnet and
   assigns the *network* address (e.g. `10.66.66.0/32`) as the client IP. With
   `/32` it keeps the exact host. This single bug caused the original "connected
   but no traffic" — the server's `AllowedIPs = 10.66.66.2/32` dropped every
   packet from the `.0`-sourced client.
2. **Server `AllowedIPs` must match the client's actual tunnel IP.** Use `/32`
   per peer. Two peers can't have overlapping `AllowedIPs` (`awg` rejects it).
   A broad `/24` is how you got here — tighten to `/32` once clients are migrated.
3. **Junk params must match exactly** server↔every client. The script guarantees
   this by reading the server conf, not by regenerating.
4. **`awg-quick` reads the conf only at `up`.** Edits require `down`/`up`
   (or `awg syncconf` for peer-only changes).
5. **`awg syncconf` syncs peers only** — it cannot change the interface private
   key, junk params, or port. A fresh `init` (new server key) needs `down`/`up`.
6. **Testing from your own LAN is unreliable** (hairpin NAT). The UDM may loop
   it back — or not. Test from a genuinely external network.
7. **Phone hotspots with carrier-grade NAT mangle UDP** — you'll see
   `udp port NNNNN unreachable` as the carrier drops return traffic. Not a valid
   test rig for the data plane; use a normal wired/fibre connection.
8. **`amneziawg-go` userspace** is chosen because RPi OS lacks the kernel module;
   the build needs Go 1.25 from go.dev, not apt.

---

## 11. Debugging cheat sheet

```bash
sudo awg show                                  # pubkey, peers, handshake, transfer
sudo awg-quick down awg0 && sudo awg-quick up awg0   # reload (interface-level changes)

# is the data plane healthy? watch DECRYPTED traffic on the tunnel interface:
sudo tcpdump -ni awg0                          # shows inner 10.66.66.x packets
# vs ENCRYPTED traffic arriving on the uplink:
sudo tcpdump -ni "$(ip route show default | awk '{print $5; exit}')" udp port 45123

# the telltale counters:
#   received >> sent  → egress broken (ip_forward/NAT) or AllowedIPs mismatch
#   no handshake      → key mismatch / server not reloaded / client not re-imported
#   handshake, no data → S4/H4 or AllowedIPs

sysctl net.ipv4.ip_forward                          # must be 1
sudo iptables -t nat -L POSTROUTING -n | grep 10.66.66   # must show MASQUERADE
```

**Decision tree when a client can't browse:**

- App shows "Connected", `curl -4 ifconfig.me` hangs, `ping 1.1.1.1` times out,
  `awg show` shows `received` climbing / `sent` flat → `ip_forward=0` or missing
  MASQUERADE. Fix §7.
- `tcpdump -ni awg0` empty while the client is active, but `awg show` `received`
  climbs → client source IP doesn't match its peer's `AllowedIPs`. Tighten to the
  client's real `/32` (and confirm the client uses a `/32` `Address`).
- `tcpdump -ni awg0` shows the client's traffic but nothing returns → NAT/forward
  missing (§7).
- No handshake at all → server pubkey ≠ what the client config bakes. Reload the
  server conf and **re-import** the client config.

---

## 12. Delivery to a client in Russia

- amnezia.org is blocked; **GitHub releases** are the source (intermittently
  throttled — don't rely on it from inside RU).
- Self-host the files from the Pi and serve over a forwarded TCP port, then kill
  it: `python3 -m http.server 8484` + UDM TCP forward, tokenized filenames.
- Encrypt the `.conf` (it holds the private key) with 7z AES-256:
  `7z a -p -mhe=on bundle.7z awg-*.conf` — deliver the password out-of-band.
- Alternative: Telegram (works in RU, 2 GB file limit).
