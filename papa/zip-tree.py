#!/usr/bin/env python3
"""Zip a directory the right way: the archive contains a single top-level
folder, mtimes are preserved, and non-ASCII filenames get the UTF-8 (EFS)
flag so Windows tools don't render Cyrillic as mojibake.

    zip-tree.py <folder> [out.zip] [--no-git]

macOS's /usr/bin/zip stores UTF-8 name bytes WITHOUT setting the flag in the
general-purpose bits (Info-ZIP 3.0), so a CP437 reader shows "___Γòñ├╝Γò¿Γò¥.txt"
instead of "___см.txt". `ditto -c -k --keepParent` has the same flaw. Python's
zipfile sets bit 11 for every non-ASCII name, which is what this uses.

Why you must not run `zip -r x.zip .` from inside the folder: the entries then
have no folder prefix and unzipping scatters the contents into the current
directory. Either run zip from the parent directory, or use this script, which
always stores paths prefixed with the folder's own name.
"""
import os
import sys
import zipfile


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    src = os.path.abspath(argv[1]).rstrip(os.sep)
    base = os.path.basename(src)
    out = argv[2] if len(argv) > 2 and not argv[2].startswith("--") else base + ".zip"
    skip_git = "--no-git" in argv
    if not os.path.isdir(src):
        print("not a directory: %s" % src)
        return 1

    nfiles = ndirs = 0
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for dirpath, dirnames, filenames in os.walk(src):
            dirnames.sort()
            filenames.sort()
            if skip_git and ".git" in dirnames:
                dirnames.remove(".git")
            rel = os.path.relpath(dirpath, src)
            arc = base if rel == "." else os.path.join(base, rel)
            z.write(dirpath, arc)          # keep the directory entry (trailing /)
            ndirs += 1
            for name in filenames:
                z.write(os.path.join(dirpath, name), os.path.join(arc, name))
                nfiles += 1

    zf = zipfile.ZipFile(out)
    infos = zf.infolist()
    nonascii = [i for i in infos if any(ord(c) > 127 for c in i.filename)]
    flagged = [i for i in nonascii if i.flag_bits & 0x800]
    tops = {i.filename.split("/")[0] for i in infos}
    escaping = [i.filename for i in infos if not i.filename.startswith(base + "/")]
    zf.close()

    print("%s\n  %d files + %d dirs -> %.1f MiB" % (out, nfiles, ndirs, os.path.getsize(out) / 1048576))
    print("  top-level entries: %s" % sorted(tops))
    print("  non-ASCII names: %d, of which UTF-8 flagged: %d" % (len(nonascii), len(flagged)))
    if escaping:
        print("  PROBLEM: %d entries outside %s/: %s" % (len(escaping), base, escaping[:3]))
        return 1
    if len(flagged) != len(nonascii):
        print("  PROBLEM: some non-ASCII names are unflagged; Windows readers may mojibake them.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
