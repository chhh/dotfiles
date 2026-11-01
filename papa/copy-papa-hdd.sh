#!/bin/bash
# Resilient copy of a slow external HDD (NTFS) to ~/papa-hdd.
# Auto-retries when the drive disconnects. Idempotent: re-run any time to resume.
# NEVER deletes anything at the destination (no --delete).
set -u

SRC_VOL="/Volumes/Transcend"          # trailing slash added on the rsync call
DST="$HOME/papa-hdd"
LOG="$HOME/papa-artifacts/papa-hdd-copy.log"
mkdir -p "$(dirname "$LOG")"
MAX_FAILS=30                          # give up after this many consecutive failed passes

# Hold sleep assertions for exactly as long as the copy runs (no -t guessing).
#   -d no disk sleep (HDD spin-down = fake disconnect), works on battery
#   -i no idle sleep  (the only one that helps on battery; -s does not)
#   -s no system sleep (valid on AC power only)
if [ -z "${_PAPA_CAF:-}" ]; then _PAPA_CAF=1 exec caffeinate -dis "$0" "$@"; fi

mkdir -p "$DST"

RSYNC="$(command -v /opt/homebrew/bin/rsync || command -v /usr/bin/rsync)"
VER="$("$RSYNC" --version | head -1 | awk '{print $3}')"
MAJOR="${VER%%.*}"

OPTS=(
  -rtHi                       # recursive, mtime, hardlinks, itemize (logs each file)
  --no-perms --no-owner --no-group   # NTFS perms/ACLs are meaningless here
  --modify-window=2           # NTFS stores 2-second timestamps; avoids needless re-copies
  --partial                   # keep partial files so an interrupted big file is not lost
  --ignore-errors             # a bad sector must not abort the whole 393 GiB
  --exclude='System Volume Information/'
  --exclude='RECYCLER/'
  --exclude='$Recycle.Bin/'
  --exclude='.DS_Store'
  --exclude='Thumbs.db'
  --exclude='desktop.ini'
)
if [ "$MAJOR" -ge 3 ]; then
  OPTS+=(--info=stats2)       # per-pass transfer summary
fi

echo "=== $(date '+%F %T') starting with $RSYNC $VER ===" >> "$LOG"

fails=0
while :; do
  # wait until the volume is mounted again
  while ! mount | grep -q " on $SRC_VOL ("; do
    echo "--- $(date '+%F %T') $SRC_VOL not mounted, waiting for reconnect (20s) ---" >> "$LOG"
    sleep 20
  done

  echo "=== $(date '+%F %T') pass start ===" >> "$LOG"
  "$RSYNC" "${OPTS[@]}" "$SRC_VOL/" "$DST/" 2>&1 | tee -a "$LOG"
  rc=${PIPESTATUS[0]}

  if [ "$rc" -eq 0 ]; then
    echo "=== $(date '+%F %T') COPY COMPLETE (clean pass, nothing left to copy) ===" >> "$LOG"
    break
  fi

  fails=$((fails + 1))
  echo "!!! $(date '+%F %T') rsync exit $rc, failure $fails/$MAX_FAILS, retry in 30s" >> "$LOG"
  if [ "$fails" -ge "$MAX_FAILS" ]; then
    echo "!!! $(date '+%F %T') giving up - see $LOG" >> "$LOG"
    exit 1
  fi
  sleep 30
done
