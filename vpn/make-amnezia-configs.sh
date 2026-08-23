#!/usr/bin/env bash
set -euo pipefail

# Generate a matching AmneziaWG server + client config with fresh keys and
# randomized obfuscation params. Run on a box with `awg` (falls back to `wg`).

ENDPOINT="${1:-pdx.oops.wtf}"
PORT="${2:-45123}"
SERVER_VPN_IP="10.66.66.1"
CLIENT_VPN_IP="10.66.66.2"
SERVER_CONF="awg-server.conf"
CLIENT_CONF="awg-client.conf"

die() { echo "ERROR: $*" >&2; exit 1; }

if command -v awg >/dev/null 2>&1; then
  KEY=awg
elif command -v wg >/dev/null 2>&1; then
  KEY=wg
else
  die "need awg or wg in PATH"
fi

priv() { "$KEY" genkey; }
pub()  { "$KEY" pubkey; }   # private key on stdin -> public key

rand32() { od -An -N4 -t u4 /dev/urandom | tr -d ' \n'; }
randint() { echo $(( $(rand32) % $1 )); }

# --- keys ---
SRV_PRIV=$(priv)
SRV_PUB=$(printf '%s\n' "$SRV_PRIV" | pub)
CLI_PRIV=$(priv)
CLI_PUB=$(printf '%s\n' "$CLI_PRIV" | pub)

# --- obfuscation params (documented AmneziaWG ranges) ---
JC=$(( 4 + $(randint 7) ))                              # 4..10
JMIN=$(( 64 + $(randint 448) ))                         # 64..511
JMAX=$(( JMIN + 1 + $(randint $((1024 - JMIN)) ) ))     # >Jmin .. 1024
S1=$(randint 65); S2=$(randint 65); S3=$(randint 65)    # 0..64
S4=$(randint 33)                                        # 0..32

# H1-H4: four non-overlapping consecutive bands, random base, within uint32
MAXU32=4294967295
BAND=16777216
BASE=$(( $(rand32) % (MAXU32 - 4*BAND + 1) ))
H1S=$BASE;                H1E=$((BASE + BAND - 1))
H2S=$((BASE + BAND));     H2E=$((BASE + 2*BAND - 1))
H3S=$((BASE + 2*BAND));   H3E=$((BASE + 3*BAND - 1))
H4S=$((BASE + 3*BAND));   H4E=$((BASE + 4*BAND - 1))

# invariants — fail loudly if generation is broken
[ "$JMAX" -ge "$JMIN" ] || die "Jmax < Jmin"
[ "$JC" -le 10 ] || die "Jc > 10"
[ "$S1" -le 64 ] && [ "$S2" -le 64 ] && [ "$S3" -le 64 ] || die "S1-S3 > 64"
[ "$S4" -le 32 ] || die "S4 > 32"
[ "$H4E" -le "$MAXU32" ] || die "H4 range overflows uint32"

JUNK() {
  cat <<EOF
Jc = $JC
Jmin = $JMIN
Jmax = $JMAX
S1 = $S1
S2 = $S2
S3 = $S3
S4 = $S4
H1 = $H1S-$H1E
H2 = $H2S-$H2E
H3 = $H3S-$H3E
H4 = $H4S-$H4E
EOF
}

umask 077

cat > "$SERVER_CONF" <<EOF
[Interface]
Address = $SERVER_VPN_IP/24
PrivateKey = $SRV_PRIV
ListenPort = $PORT
$(JUNK)

[Peer]
PublicKey = $CLI_PUB
AllowedIPs = $CLIENT_VPN_IP/32
EOF

cat > "$CLIENT_CONF" <<EOF
[Interface]
PrivateKey = $CLI_PRIV
Address = $CLIENT_VPN_IP/24
DNS = 1.1.1.1
$(JUNK)

[Peer]
PublicKey = $SRV_PUB
Endpoint = $ENDPOINT:$PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "wrote: $SERVER_CONF   (install to /etc/amnezia/amneziawg/awg0.conf)"
echo "wrote: $CLIENT_CONF   (import into AmneziaVPN)"
echo "fresh keys + params generated"