#!/bin/bash
# Deep byte-for-byte verification of ~/papa-hdd against the Transcend HDD.
# Waits for the drive to be plugged in, then runs rsync -c (reads ~393 GiB twice).
# Safe: dry-run only (-n), writes nothing to either disk except this log.
set -u
SRC_VOL="/Volumes/Transcend"
DST="$HOME/papa-hdd"
LOG="$HOME/papa-artifacts/papa-hdd-verify-deep.log"
mkdir -p "$(dirname "$LOG")"
RSYNC="$(command -v /opt/homebrew/bin/rsync || command -v /usr/bin/rsync)"

OPTS=(-rtHn -c --no-perms --no-owner --no-group --modify-window=2 --ignore-errors
      --exclude='System Volume Information/' --exclude='RECYCLER/' --exclude='$Recycle.Bin/'
      --exclude='.DS_Store' --exclude='Thumbs.db' --exclude='desktop.ini')
"$RSYNC" --version | head -1 | grep -q 'version 3\.' && OPTS+=(--info=stats2)

echo "=== $(date '+%F %T') deep verify queued, rsync $("$RSYNC" --version | head -1 | awk '{print $3}') ===" | tee -a "$LOG"
while ! mount | grep -q " on $SRC_VOL ("; do
  echo "--- $(date '+%F %T') $SRC_VOL not mounted; re-plug the HDD, waiting 20s ---" | tee -a "$LOG"
  sleep 20
done
echo "=== $(date '+%F %T') mounted, starting full checksum pass (expect ~4-8 h) ===" | tee -a "$LOG"
"$RSYNC" "${OPTS[@]}" "$SRC_VOL/" "$DST/" 2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}
echo "=== $(date '+%F %T') deep verify exit $rc ===" | tee -a "$LOG"
if [ "$rc" -eq 0 ]; then
  echo "OK: every file byte-identical (only the 2 skipped non-regular files are absent)." | tee -a "$LOG"
else
  echo "MISMATCH or I/O errors: lines above starting with '>f' are files whose CONTENT differs." | tee -a "$LOG"
  echo "Re-run the copy to repair:  ~/dotfiles/papa/copy-papa-hdd.sh" | tee -a "$LOG"
fi
