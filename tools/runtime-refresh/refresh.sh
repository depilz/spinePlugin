#!/bin/bash
# Three-way refresh of a vendored spine-cpp runtime from one upstream spine-runtimes revision to another.
# usage: tools/runtime-refresh/refresh.sh [--cpp DIR] [--out DIR] <upstream-clone> <base-rev> <new-rev> <runtime-dir>
#        --cpp: the upstream dir holding include/spine and src/spine (4.2: spine-cpp/spine-cpp, the default; 4.3: spine-cpp)
# <runtime-dir> is flat (runtime/spine-4.x/spine: headers and sources side by side); a name.h maps to
# <cpp>/include/spine/name.h upstream, anything else to <cpp>/src/spine/name. Each vendored file upstream changed between
# <base-rev> and <new-rev> is merged with git merge-file (ours = the vendored file, base = <base-rev>, theirs = <new-rev>).
# On a conflict the leading license comment (from a "/*" on line 1 through the first "*/") and the rest of the file are
# merged apart: a conflict in the license comment takes upstream's text; a conflict anywhere else keeps its markers.
# Files upstream never had are kept, files upstream deleted are kept with a warning, files new upstream are added.
# Writes in place, or into a fresh copy of <runtime-dir> at --out DIR (which must not exist).
# Prints one line per file that needs a look: MERGED, LICENSE (took upstream's license comment), CONFLICT (one per
# hunk, with its line range), ADDED, KEPT (not upstream), WARN (deleted upstream, kept), SKIPPED (upstream file the
# runtime does not vendor); then the number of conflicts left.
# Exit 0 = no conflict left, 1 = conflicts left (markers in the tree, see the CONFLICT lines), 2 = usage error.
set -uo pipefail

usage() { sed -n '3,4s/^# //p' "$0"; }
die() { echo "refresh.sh: $*" >&2; exit 2; }
value() { [[ -n "${2:-}" ]] || die "$1 needs a value"; }

# upstream_path name: the file's path in the upstream clone
upstream_path() { case $1 in *.h) echo "$CPP/include/spine/$1" ;; *) echo "$CPP/src/spine/$1" ;; esac; }

has() { git -C "$UP" cat-file -e "$1:$2" 2>/dev/null; }
show() { git -C "$UP" show "$1:$2" >"$3"; }

# upstream_files rev: the name of every file in the rev's include/spine and src/spine
upstream_files() {
  git -C "$UP" ls-tree "$1" "$CPP/include/spine/" "$CPP/src/spine/" | awk '$2 == "blob" { sub(".*/", "", $4); print $4 }'
}

# license_lines file: the number of lines of its leading license comment (0 when it has none)
license_lines() {
  local n
  n=$(awk 'NR == 1 && !/^\/\*/ { exit } /\*\// { print NR; exit }' "$1")
  echo "${n:-0}"
}

# split v: $T/v into $T/v.lic (the license comment) and $T/v.code (the rest), byte for byte
split() {
  local n
  n=$(license_lines "$T/$1")
  if (( n > 0 )); then head -n "$n" "$T/$1" >"$T/$1.lic"; else : >"$T/$1.lic"; fi  # BSD head rejects -n 0
  tail -n "+$((n + 1))" "$T/$1" >"$T/$1.code"
}

# merge3 ours base theirs: git merge-file in place into ours; returns the number of conflicts
merge3() {
  local rc=0
  git merge-file -q -L vendored -L "$BASE" -L "$NEW" "$1" "$2" "$3" || rc=$?
  (( rc < 128 )) || die "git merge-file failed on $1"
  return "$rc"
}

# merge_apart name: merges the license comment and the rest of $T/ours apart into the file; counts its conflicts
merge_apart() {
  local v rc=0
  for v in ours base new; do split "$v"; done
  if ! merge3 "$T/ours.lic" "$T/base.lic" "$T/new.lic"; then
    cp "$T/new.lic" "$T/ours.lic"
    echo "LICENSE $1: conflict in the license comment, took upstream's"
  fi
  merge3 "$T/ours.code" "$T/base.code" "$T/new.code" || rc=$?
  cat "$T/ours.lic" "$T/ours.code" >"$OUT/$1"
  (( conflicts += rc ))
  awk -v f="$1" '/^<<<<<<< /{ s = NR } /^>>>>>>> /{ print "CONFLICT " f " lines " s "-" NR }' "$OUT/$1"
}

# refresh_file name: the vendored file brought from BASE to NEW
refresh_file() {
  local p
  p=$(upstream_path "$1")
  if ! has "$NEW" "$p"; then
    if has "$BASE" "$p"; then echo "WARN $1: deleted upstream, kept"; else echo "KEPT $1: not upstream"; fi
    return
  fi
  show "$NEW" "$p" "$T/new" || die "cannot read $NEW:$p"
  if has "$BASE" "$p"; then show "$BASE" "$p" "$T/base" || die "cannot read $BASE:$p"; else : >"$T/base"; fi
  cmp -s "$T/base" "$T/new" && return
  cp "$OUT/$1" "$T/ours"
  cp "$T/ours" "$T/merged"
  if merge3 "$T/merged" "$T/base" "$T/new"; then cp "$T/merged" "$OUT/$1"; else merge_apart "$1"; fi
  cmp -s "$T/ours" "$OUT/$1" || echo "MERGED $1"
}

# add_new_files: every NEW file the runtime lacks; added when it is new since BASE
add_new_files() {
  local f
  upstream_files "$BASE" >"$T/base-files"
  for f in $(upstream_files "$NEW"); do
    [[ -e "$OUT/$f" ]] && continue
    if grep -qxF "$f" "$T/base-files"; then echo "SKIPPED $f: upstream file the runtime does not vendor"; continue; fi
    show "$NEW" "$(upstream_path "$f")" "$OUT/$f" || die "cannot read $NEW:$(upstream_path "$f")"
    echo "ADDED $f"
  done
}

CPP=spine-cpp/spine-cpp OUT=""
while (( $# )); do
  case $1 in
    -h|--help) usage; exit 0 ;;
    --cpp) value "$@"; CPP=$2; shift 2 ;;
    --out) value "$@"; OUT=$2; shift 2 ;;
    -*) die "unknown option $1 (--help)" ;;
    *) break ;;
  esac
done
(( $# == 4 )) || die "expected <upstream-clone> <base-rev> <new-rev> <runtime-dir> (--help)"
UP=$1 BASE=$2 NEW=$3 RUNTIME=$4
[[ -d "$RUNTIME" ]] || die "no runtime dir $RUNTIME"
for rev in "$BASE" "$NEW"; do
  git -C "$UP" rev-parse -q --verify "$rev^{commit}" >/dev/null || die "no commit $rev in $UP"
  has "$rev" "$CPP/include/spine" && has "$rev" "$CPP/src/spine" || die "no $CPP/{include,src}/spine at $rev (--cpp)"
done
if [[ -n "$OUT" ]]; then
  [[ ! -e "$OUT" ]] || die "--out $OUT exists"
  cp -Rp "$RUNTIME" "$OUT" || die "cannot copy $RUNTIME to $OUT"
else
  OUT=$RUNTIME
fi

T=$(mktemp -d "${TMPDIR:-/tmp}/runtime-refresh.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT
conflicts=0
for f in "$OUT"/*; do [[ -f "$f" ]] && refresh_file "${f##*/}"; done
add_new_files
echo "$conflicts conflict(s) left outside license comments in $OUT"
(( conflicts == 0 )) || exit 1
