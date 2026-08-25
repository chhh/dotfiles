#!/usr/bin/env bash
set -euo pipefail

# AmneziaWG config generator.
#
#   ./make-awg-configs.sh init [endpoint] [port] [name]
#       Fresh server (new keys + junk params) plus a first client.
#
#   ./make-awg-configs.sh add-peer <name> [octet]
#       Add a client to the EXISTING server. Server key, junk params, and
#       port are read from awg-server.conf — never regenerated. <octet> is
#       the client IP's last octet; omit it for the next free one.
#
#   ./make-awg-configs.sh syncconf
#       Install awg-server.conf and hot-reload the running tunnel (no drop).
#
#   ./make-awg-configs.sh up | down | restart
#       Start / stop / restart the tunnel (awg0) from the installed config.

ENDPOINT="${ENDPOINT:-pdx.oops.wtf}"
PORT="${PORT:-45123}"
SUBNET="10.66.66"
SERVER_CONF="awg-server.conf"

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat >&2 <<'EOF'
usage: make-awg-configs.sh init [endpoint] [port] [name]
       make-awg-configs.sh add-peer <name> [octet]
       make-awg-configs.sh syncconf
       make-awg-configs.sh up | down | restart

  octet = client IP last octet (1..254); omitted = next free.
EOF
  exit 1
}

if command -v awg >/dev/null 2>&1; then KEY=awg
elif command -v wg >/dev/null 2>&1; then KEY=wg
else die "need awg or wg in PATH"; fi

priv() { "$KEY" genkey; }
pub()  { "$KEY" pubkey; }   # private key on stdin -> public key

rand32() { od -An -N4 -t u4 /dev/urandom | tr -d ' \n'; }
randint() { echo $(( $(rand32) % $1 )); }

gen_junk_params() {
  JC=$(( 4 + $(randint 7) ))                              # 4..10
  JMIN=$(( 64 + $(randint 448) ))                         # 64..511
  JMAX=$(( JMIN + 1 + $(randint $((1024 - JMIN)) ) ))     # >Jmin .. 1024
  S1=$(randint 65); S2=$(randint 65); S3=$(randint 65)    # 0..64
  S4=$(randint 33)                                        # 0..32

  # H1-H4: four non-overlapping consecutive bands, within uint32, min value 5
  MAXU32=4294967295
  BAND=16777216
  BASE=$(( 5 + $(rand32) % (MAXU32 - 4*BAND - 4) ))
  H1S=$BASE;                H1E=$((BASE + BAND - 1))
  H2S=$((BASE + BAND));     H2E=$((BASE + 2*BAND - 1))
  H3S=$((BASE + 2*BAND));   H3E=$((BASE + 3*BAND - 1))
  H4S=$((BASE + 3*BAND));   H4E=$((BASE + 4*BAND - 1))

  [ "$JMAX" -ge "$JMIN" ] || die "Jmax < Jmin"
  [ "$JC" -le 10 ] || die "Jc > 10"
  [ "$S1" -le 64 ] && [ "$S2" -le 64 ] && [ "$S3" -le 64 ] || die "S1-S3 > 64"
  [ "$S4" -le 32 ] || die "S4 > 32"
  [ "$H1S" -ge 5 ] || die "H range below minimum of 5"
  [ "$H4E" -le "$MAXU32" ] || die "H4 range overflows uint32"
}

junk_block() {
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

# --- read identity back from the server conf (single source of truth) ---
server_addr()   { awk '$1=="Address"{print $3; exit}' "$SERVER_CONF"; }
server_priv()   { awk '$1=="PrivateKey"{print $3; exit}' "$SERVER_CONF"; }
server_port()   { awk '$1=="ListenPort"{print $3; exit}' "$SERVER_CONF"; }
junk_from_conf(){ awk '$1 ~ /^(Jc|Jmin|Jmax|S1|S2|S3|S4|H1|H2|H3|H4)$/{print}' "$SERVER_CONF"; }

octet_used() { grep -qE "AllowedIPs = ${NET}\.${1}/32" "$SERVER_CONF"; }

broad_peers() {
  awk '/^\[Peer\]/{inp=1; next} /^\[/{inp=0} inp && $1=="AllowedIPs" && $3 !~ /\/32$/{print $3}' "$SERVER_CONF"
}

next_client_octet() {
  local oct=2
  while octet_used "$oct"; do
    oct=$((oct+1)); [ "$oct" -le 254 ] || die "subnet exhausted"
  done
  echo "$oct"
}

umask 077
cmd="${1:-}"; shift || true

case "$cmd" in
init)
  ENDPOINT="${1:-$ENDPOINT}"
  PORT="${2:-$PORT}"
  NAME="${3:-client}"

  gen_junk_params
  SRV_PRIV=$(priv)
  SRV_PUB=$(printf '%s\n' "$SRV_PRIV" | pub)

  CLIENT_IP="${SUBNET}.2"
  CLI_PRIV=$(priv)
  CLI_PUB=$(printf '%s\n' "$CLI_PRIV" | pub)

  cat > "$SERVER_CONF" <<EOF
[Interface]
Address = ${SUBNET}.1/24
PrivateKey = $SRV_PRIV
ListenPort = $PORT
$(junk_block)

[Peer]
PublicKey = $CLI_PUB
AllowedIPs = ${CLIENT_IP}/32
EOF

  cat > "awg-${NAME}.conf" <<EOF
[Interface]
PrivateKey = $CLI_PRIV
Address = ${CLIENT_IP}/32
DNS = 1.1.1.1
$(junk_block)

[Peer]
PublicKey = $SRV_PUB
Endpoint = ${ENDPOINT}:${PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

  echo "wrote: $SERVER_CONF     (install to /etc/amnezia/amneziawg/awg0.conf)"
  echo "wrote: awg-${NAME}.conf (import into AmneziaVPN)"
  ;;

add-peer)
  NAME="${1:?usage: $0 add-peer <name> [octet]}"
  [ -f "$SERVER_CONF" ] || die "$SERVER_CONF not found — run init first"

  NET="$(server_addr)"; NET="${NET%.*}"
  [ -n "$NET" ] || die "no Address in $SERVER_CONF"
  SRV_PRIV=$(server_priv); [ -n "$SRV_PRIV" ] || die "no PrivateKey in $SERVER_CONF"
  PORT=$(server_port);     [ -n "$PORT" ]     || die "no ListenPort in $SERVER_CONF"
  JUNK=$(junk_from_conf);  [ -n "$JUNK" ]     || die "no junk params in $SERVER_CONF"
  SRV_PUB=$(printf '%s\n' "$SRV_PRIV" | pub)

  OCTET="${2:-$(next_client_octet)}"
  [[ "$OCTET" =~ ^[0-9]+$ ]] && (( OCTET >= 1 && OCTET <= 254 )) || die "octet must be 1..254"
  CLIENT_IP="${NET}.${OCTET}"

  octet_used "$OCTET" && die "${CLIENT_IP}/32 is already assigned to a peer"
  BROAD=$(broad_peers)
  if [ -n "$BROAD" ]; then
    echo "WARNING: subnet-wide AllowedIPs overlap ${CLIENT_IP}/32:" >&2
    echo "$BROAD" | sed 's/^/         /' >&2
    echo "         amneziawg rejects overlapping peers — tighten it to a /32 first." >&2
  fi

  CLI_PRIV=$(priv)
  CLI_PUB=$(printf '%s\n' "$CLI_PRIV" | pub)

  cat >> "$SERVER_CONF" <<EOF

[Peer]
PublicKey = $CLI_PUB
AllowedIPs = ${CLIENT_IP}/32
EOF

  cat > "awg-${NAME}.conf" <<EOF
[Interface]
PrivateKey = $CLI_PRIV
Address = ${CLIENT_IP}/32
DNS = 1.1.1.1
$JUNK

[Peer]
PublicKey = $SRV_PUB
Endpoint = ${ENDPOINT}:${PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

  echo "added peer '$NAME' at ${CLIENT_IP}/32"
  echo "wrote: awg-${NAME}.conf (import into AmneziaVPN)"
  echo "apply on server without dropping the tunnel:"
  echo "  ./make-awg-configs.sh syncconf"
  ;;

down)
  sudo awg-quick down awg0
  ;;

up)
  sudo awg-quick up awg0
  ;;

restart)
  sudo awg-quick down awg0 || true
  sudo awg-quick up awg0
  ;;

syncconf)
  [ -f "$SERVER_CONF" ] || die "$SERVER_CONF not found"
  sudo install -m 600 "$SERVER_CONF" /etc/amnezia/amneziawg/awg0.conf
  sudo awg syncconf awg0 /etc/amnezia/amneziawg/awg0.conf
  ;;

*)
  usage
  ;;
esac
