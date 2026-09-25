#!/bin/bash
# gate: tools/release-gate/gate.sh on each tracked archive with the defaults it reads from the checkout, one test per
# archive. Then the gate itself against archives of released tags (git show): 1.5.0's win32 archive (a 4.3 DLL) must
# fail on version, runtime and 4.3 markers as v1.5.0/4.2, 1.3.0's and 1.2.5's (toolchain 4.4/4.5 strings beside 4.2)
# must pass as their version/4.2, and 1.5.0's other archives must pass.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
GATE="$W/../../tools/release-gate/gate.sh"
PACKAGE=plugin/com.studycat.spine/plugin.spine

for plat in android iphone mac-sim win32; do
  run_test "$plat/data.tgz" "$GATE" --repo "$SPINE_REPO" "$plat"
done

# tag_gate tag platform version: the gate on the tag's archive, extracted into $SUITE_OUT/tags, as version/4.2
tag_gate() {
  local dir="$SUITE_OUT/tags/$1"
  git -C "$SPINE_REPO" rev-parse -q --verify "$1^{commit}" >/dev/null || { echo "tag $1 not available (fetch tags)"; return 2; }
  mkdir -p "$dir/$2"
  git -C "$SPINE_REPO" show "$1:$PACKAGE/$2/data.tgz" >"$dir/$2/data.tgz" || return 2
  "$GATE" --plugin-dir "$dir" --version "$3" --runtime 4.2 "$2"
}

# rejects tag platform version reason...: the gate fails (exit 1) and the binary's FAIL line names every reason
rejects() {
  local out reason rc=0
  out=$(tag_gate "$1" "$2" "$3") || rc=$?
  printf '%s\n' "$out"
  (( rc == 1 )) || return 1
  shift 3
  for reason in "$@"; do grep -qE "^FAIL .*::.* $reason( |\$)" <<<"$out" || return 1; done
}

for plat in android iphone mac-sim; do
  run_test "1.5.0:$plat/data.tgz passes as v1.5.0/4.2" tag_gate 1.5.0 "$plat" v1.5.0
done
run_test "1.5.0:win32/data.tgz fails as v1.5.0/4.2 on version, runtime and 4.3-markers" rejects 1.5.0 win32 v1.5.0 version runtime 4.3-markers
run_test "1.3.0:win32/data.tgz passes as v1.3.0/4.2" tag_gate 1.3.0 win32 v1.3.0
run_test "1.2.5:win32/data.tgz passes as v1.2.5/4.2" tag_gate 1.2.5 win32 v1.2.5
