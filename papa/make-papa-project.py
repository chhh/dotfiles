#!/usr/bin/env python3
"""Assemble ~/papa-project from the papa-hdd archive.

Picks the NEWEST complete copy of each of the 4 blocks of the home project,
collects every dev-history log (deduplicated by name, newest kept), all written
specs (.doc/.docx/.pdf), and indexes the dated snapshot trees rather than
copying ~800 MB of them. Original Windows mtimes are preserved.
Nothing in ~/papa-hdd is modified.
"""
import os, re, shutil, json, collections, datetime

SRC = "/Users/chhh/papa-hdd"
DST = os.path.expanduser("~/papa-project")
NEWEST = SRC + "/диск C/tns/tek"          # 2026-06-02, 1155 files - the tip of the tree
FALLBACKS = [SRC + "/tek с диска С", SRC + "/___tek", SRC + "/диск Д/tns/tek", SRC + "/диск C/_frm_/tek"]

BLOCKS = ["dml_file_parsing", "dml_graph_model", "sum_02", "sum_03"]
BLOCK_DIR = {"dml_file_parsing": "1_dml_file_parsing", "dml_graph_model": "2_dml_graph_model",
             "sum_02": "3_sum_02", "sum_03": "4_sum_03"}

JUNK_EXT = {'.ncb', '.obj', '.pdb', '.ilk', '.pch', '.idb', '.suo', '.user', '.opt', '.plg',
            '.exp', '.o', '.a', '.iex', '.tlog', '.lastbuildstate', '.log~', '.unsuccessfulbuild'}
JUNK_NAME = {'.ds_store', 'thumbs.db', 'desktop.ini'}
BUILD_DIRS = {'debug', 'release', 'ipch', 'x64', 'win32', 'tmp', 'temp'}
DATE_RE = re.compile(r'(20\d{2}[-_.]\d{2}[-_.]\d{2}|\d{2}[-_.]\d{2}[-_.]\d{4})')
DIARY_DATE = re.compile(r'^\s*\[?(\d{2})[-.](\d{2})[-.](20\d{2}|\d{2})')


def day(ts):
    return datetime.date.fromtimestamp(ts).isoformat()


def src_of(block):
    """newest existing directory for a block, preferring NEWEST root."""
    cands = []
    for root in [NEWEST] + FALLBACKS:
        for name in os.listdir(root) if os.path.isdir(root) else []:
            if name == block or name.startswith(block + " "):
                p = os.path.join(root, name)
                mx = 0
                n = 0
                for dp, dn, fn in os.walk(p):
                    for f in fn:
                        try:
                            st = os.lstat(os.path.join(dp, f))
                        except OSError:
                            continue
                        n += 1
                        mx = max(mx, st.st_mtime)
                cands.append((mx, -n, p))
    if not cands:
        return None, 0, 0
    cands.sort(reverse=True)
    best = cands[0]
    return best[2], best[0], -best[1]


def keep(rel, name):
    if name.lower() in JUNK_NAME or name.startswith('.'):
        return False
    if os.path.splitext(name)[1].lower() in JUNK_EXT:
        return False
    parts = [p.lower() for p in rel.split(os.sep)]
    if any(p in BUILD_DIRS for p in parts[:-1]):
        return False
    if name.lower().endswith('.lnk'):          # Windows shortcuts, inert on a Mac
        return False
    return True


def copy_tree(srcroot, dstdir, stats):
    for dp, dn, fn in os.walk(srcroot):
        dn[:] = [d for d in dn if d.lower() not in BUILD_DIRS and not d.startswith('.')]
        rel_d = os.path.relpath(dp, srcroot)
        for f in fn:
            rel = os.path.normpath(os.path.join(rel_d, f))
            if not keep(rel, f):
                stats['skipped'] += 1
                continue
            sp = os.path.join(dp, f)
            try:
                if not os.path.isfile(sp) or os.path.islink(sp):
                    continue
            except OSError:
                continue
            os.makedirs(os.path.join(dstdir, os.path.dirname(rel)), exist_ok=True)
            shutil.copy2(sp, os.path.join(dstdir, rel))
            st = os.lstat(sp)
            stats['files'] += 1
            stats['bytes'] += st.st_size
            stats['newest'] = max(stats['newest'], st.st_mtime)


def collect_logs():
    """every history*txt in the archive, dedup by basename keeping newest mtime."""
    best = {}
    for dp, dn, fn in os.walk(SRC):
        for f in fn:
            if not f.lower().startswith('history'):
                continue
            if not f.lower().endswith(('.txt', '.doc', '.docx')):
                continue
            p = os.path.join(dp, f)
            try:
                st = os.lstat(p)
            except OSError:
                continue
            if not os.path.isfile(p):
                continue
            k = (f.lower(), os.path.getsize(p) > 1024 * 1024)
            key = re.sub(r'\s+copy(?=\.|$)', '', os.path.splitext(f)[0]).lower()
            if key not in best or st.st_mtime > best[key][1]:
                best[key] = (p, st.st_mtime)
    return sorted(best.values(), key=lambda x: x[1])


def diary_span(path):
    """first and last dated diary entry inside a history log."""
    for enc in ("utf-8", "cp1251", "koi8-r", "latin-1"):
        try:
            t = open(path, 'rb').read().decode(enc)
            break
        except Exception:
            t = None
    if not t:
        return None, None
    ds = []
    for m in DIARY_DATE.finditer(t):
        d, mo, y = m.groups()
        y = "20" + y if len(y) == 2 else y
        try:
            ds.append(datetime.date(int(y), int(mo), int(d)))
        except Exception:
            pass
    if not ds:
        return None, None
    return min(ds).isoformat(), max(ds).isoformat()


def snapshot_index():
    rows = []
    for dp, dn, fn in os.walk(SRC):
        for d in dn:
            if not DATE_RE.search(d) or not any(b in d for b in BLOCKS):
                continue
            p = os.path.join(dp, d)
            cnt = 0
            mx = 0
            for _, _, f3 in os.walk(p):
                cnt += len(f3)
            try:
                mx = os.lstat(p).st_mtime
            except OSError:
                pass
            rows.append((os.path.relpath(p, SRC), cnt, day(mx)))
    return sorted(set(rows))


inv = {"blocks": {}, "logs": [], "snapshots": [], "specs": []}
os.makedirs(DST, exist_ok=True)

# 1. the four blocks, newest source
for b in BLOCKS:
    p, mx, n = src_of(b)
    if not p:
        inv["blocks"][b] = {"missing": True}
        continue
    d = os.path.join(DST, BLOCK_DIR[b])
    stats = {"files": 0, "bytes": 0, "skipped": 0, "newest": 0}
    copy_tree(p, d, stats)
    inv["blocks"][b] = {"from": p, "total_files_on_source": n, "newest_mtime": day(mx),
                        "copied_files": stats['files'], "copied_bytes": stats['bytes'],
                        "skipped_junk": stats['skipped'], "dest": os.path.relpath(d, DST)}
    print("%-18s from %-42s last %s -> %4d files %6.1f MiB (skipped %d junk)" % (
        b, p.replace(SRC + "/", ""), day(mx), stats['files'], stats['bytes'] / 1048576, stats['skipped']))

# 2. his own project note at the root of the package
for note in ["___см.txt"]:
    for root in [NEWEST] + FALLBACKS:
        f = os.path.join(root, note)
        if os.path.exists(f):
            shutil.copy2(f, os.path.join(DST, note))
            inv["readme_note"] = {"from": f, "mtime": day(os.lstat(f).st_mtime)}
            break

# 3. all history logs, deduplicated
logdir = os.path.join(DST, "_history_logs")
os.makedirs(logdir, exist_ok=True)
for p, mx in collect_logs():
    f = os.path.basename(p)
    tgt = os.path.join(logdir, f)
    if os.path.exists(tgt):
        f = os.path.basename(os.path.dirname(p)) + "__" + f
        tgt = os.path.join(logdir, f)
    shutil.copy2(p, tgt)
    a, z = diary_span(p)
    inv["logs"].append({"file": f, "from": p, "bytes": os.lstat(p).st_size,
                        "mtime": day(mx), "entries_from": a, "entries_to": z})
print("logs: %d unique history files" % len(inv["logs"]))

# 4. written specs (.doc/.docx/.pdf) inside the newest tree
specdir = os.path.join(DST, "_specs")
os.makedirs(specdir, exist_ok=True)
for dp, dn, fn in os.walk(NEWEST):
    for f in fn:
        if os.path.splitext(f)[1].lower() in ('.doc', '.docx', '.pdf', '.xls', '.xlsx'):
            sp = os.path.join(dp, f)
            rel = os.path.relpath(sp, NEWEST)
            os.makedirs(os.path.join(specdir, os.path.dirname(rel)), exist_ok=True)
            shutil.copy2(sp, os.path.join(specdir, rel))
            inv["specs"].append({"file": rel, "bytes": os.lstat(sp).st_size,
                                 "mtime": day(os.lstat(sp).st_mtime)})
print("specs: %d office/pdf files" % len(inv["specs"]))

# 5. index of dated snapshot trees (left in place, not copied)
inv["snapshots"] = snapshot_index()
print("snapshot trees indexed: %d" % len(inv["snapshots"]))

with open(os.path.join(DST, "_INVENTORY.json"), "w") as fh:
    json.dump(inv, fh, ensure_ascii=False, indent=1)

tot = sum(v.get("copied_bytes", 0) for v in inv["blocks"].values()) \
    + sum(l["bytes"] for l in inv["logs"]) + sum(s["bytes"] for s in inv["specs"])
print("\nTOTAL package: %.1f MiB" % (tot / 1048576))
print("\n--- logs, newest first ---")
for l in inv["logs"][::-1][:28]:
    print("  %-52s %7.0f KiB  mtime %s  entries %s..%s" % (
        l["file"][:52], l["bytes"] / 1024, l["mtime"], l["entries_from"] or "?", l["entries_to"] or "?"))
