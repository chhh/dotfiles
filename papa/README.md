# papa — the scripts that rescued and packaged Mikhail's archive

These are the tools used to get his work off the failing external HDD and into a readable package.
They are here (in `dotfiles`, under git) so they are not lost and are not loose in the home directory.

| file | what it does |
|---|---|
| `copy-papa-hdd.sh` | resumable copy of the Transcend HDD to `~/papa-hdd`. Never deletes, preserves Windows mtimes, reads from a slow NTFS disk in one pass. |
| `verify-papa-hdd.sh` | verifies the copy with the same filters the copy used (name/size pass). |
| `verify-deep-when-plugged.sh` | waits for the drive, then runs a full byte-for-byte checksum pass (`rsync -c`, reads ~393 GiB, hours). |
| `make-papa-project.py` | assembles `~/papa-project` from `~/papa-hdd`: the four source blocks, deduplicated logs, specs and inventory. |
| `zip-tree.py` | builds a zip that preserves the NTFS EFS flag workaround; used to produce `~/papa-project.zip`. |

**Logs and the zip are not here.** They live in `~/papa-artifacts/` (about 54 MB): a 31 MB copy log is a
record, not source, and does not belong in a git repository. The scripts write their logs there too.

The work they fed into is in three repositories: `~/papa-project` (the archive, read-only reference),
`~/papa-rebuild` (the rebuild), and `~/papa-hdd` (the mirror of the drive — the only copy, never written to).
