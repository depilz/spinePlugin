#!/bin/bash
# runtime_guard.sh [--repo dir] [range]: flags every non-merge commit in range (default origin/main..HEAD) that
# changes a file under one line's runtime/spine-<line>/ without changing a counterpart of it under the other line,
# unless the commit message has a "Runtime-other: <reason>" trailer.
# A file's counterparts are the same path under the other line plus its pairs in tests/guard/counterparts.tsv (whose
# first row names the two lines). Prints one FLAG line per unmatched file; exit 0 none, 1 flagged, 2 usage/git error.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
MAP=$W/counterparts.tsv

die() { echo "runtime_guard.sh: $*" >&2; exit 2; }

repo=.
if [[ "${1:-}" == --repo ]]; then repo=${2:?--repo needs a directory}; shift 2; fi
range=${1:-origin/main..HEAD}
commits=$(git -C "$repo" rev-list --no-merges "$range") || die "cannot list the commits of '$range' in $repo"

# unmatched: reads a commit's changed paths on stdin, prints "path<TAB>counterpart..." for each runtime file none of
# whose counterparts (the same path under the other line, then its map pairs) changed
unmatched() {
  awk -F'\t' '
    FNR == NR {
      if ($0 ~ /^#/ || $0 == "") next
      if (!l1) { l1 = $1; l2 = $2; next }
      if ($1 != "-" && $2 != "-") { pair[l1 "/" $1] = pair[l1 "/" $1] " " l2 "/" $2; pair[l2 "/" $2] = pair[l2 "/" $2] " " l1 "/" $1 }
      next
    }
    { changed[$0] = 1; paths[++n] = $0 }
    END {
      for (i = 1; i <= n; i++) {
        if (!match(paths[i], "^runtime/spine-[^/]+/")) continue
        line = substr(paths[i], 15, RLENGTH - 15); rel = substr(paths[i], RLENGTH + 1)
        if (line == l1) other = l2; else if (line == l2) other = l1; else continue
        k = split(other "/" rel pair[line "/" rel], c, " ")
        out = ""
        for (j = 1; j <= k; j++) { if (("runtime/spine-" c[j]) in changed) break; out = out " runtime/spine-" c[j] }
        if (j > k) print paths[i] "\t" substr(out, 2)
      }
    }' "$MAP" -
}

bad=0
for c in $commits; do
  [[ -n "$(git -C "$repo" log -1 --format='%(trailers:key=Runtime-other,valueonly)' "$c")" ]] && continue
  subject=$(git -C "$repo" log -1 --format='%h %s' "$c")
  while IFS=$'\t' read -r path cands; do
    found=""
    for cand in $cands; do git -C "$repo" cat-file -e "$c:$cand" 2>/dev/null && found="$found $cand"; done
    echo "FLAG $subject: $path, counterpart unchanged:${found:- none}"; bad=1
  done < <(git -C "$repo" diff-tree --no-commit-id --name-only -r "$c" | unmatched)
done
exit $bad
