#!/bin/bash
# Verify ~/papa-hdd against the HDD using the same filters as the copy.
# Anything printed under "STILL MISSING / DIFFERENT" is not yet copied correctly.
set -u
SRC="/Volumes/Transcend"
DST="$HOME/papa-hdd"

RSYNC="$(command -v /opt/homebrew/bin/rsync || command -v /usr/bin/rsync)"
OPTS=(
  -rtHi -n --no-perms --no-owner --no-group --modify-window=2 --ignore-errors
  --exclude='System Volume Information/'
  --exclude='RECYCLER/'
  --exclude='$Recycle.Bin/'
  --exclude='.DS_Store'
  --exclude='Thumbs.db'
  --exclude='desktop.ini'
)

echo "== metadata pass (size + mtime, fast) =="
"$RSYNC" "${OPTS[@]}" "$SRC/" "$DST/" | tee /tmp/papa-missing.txt
echo "-> lines listed above; 0 means everything is present"

if [ "${1:-}" = "--deep" ]; then
  echo "== content pass (full checksum of both sides, reads all ~393 GiB, hours) =="
  "$RSYNC" "${OPTS[@]}" -c "$SRC/" "$DST/" | tee /tmp/papa-missing-deep.txt
fi
