#!/bin/bash
# publish: tools/publish/publish.py on a synthetic private history under $SUITE_OUT (invented names, emails and paths).
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
TOOL="$W/../../tools/publish/publish.py"
F="$SUITE_OUT/fixture"
P="$F/private"
PRIVATE_EMAIL=dev@private.invalid
PUBLIC_EMAIL=pub@example.invalid
DROP='(^|/)secret/'
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null

# private_git args...: git in the private repo as its private author
private_git() {
  GIT_AUTHOR_NAME=dev GIT_AUTHOR_EMAIL=$PRIVATE_EMAIL GIT_COMMITTER_NAME=dev GIT_COMMITTER_EMAIL=$PRIVATE_EMAIL \
    git -C "$P" "$@"
}

# as_public repo args...: git in an export repo as the public identity (author email AUTHOR_EMAIL, if set) at the last
# public commit's date
as_public() {
  local repo=$1
  shift
  GIT_AUTHOR_NAME=Pub GIT_AUTHOR_EMAIL=${AUTHOR_EMAIL:-$PUBLIC_EMAIL} GIT_AUTHOR_DATE="1700007200 +0000" \
    GIT_COMMITTER_NAME=Pub GIT_COMMITTER_EMAIL=$PUBLIC_EMAIL GIT_COMMITTER_DATE="1700007200 +0000" git -C "$repo" "$@"
}

# row fields...: one tab-separated row
row() { local IFS=$'\t'; printf '%s\n' "$*"; }

# fixture: three private commits (private art under secret/, the private email in README.md, then the art gone and a
# .mailmap), a map of four public commits on two lines with an annotated tag each, a deny-file and a hash list
fixture() {
  local c1 c2 c3 secret m="$F/map"
  rm -rf "$F" && mkdir -p "$P/art/secret" "$P/plugin/demo" "$m"
  private_git init -q -b main
  printf '# demo\n\n- Email: <%s>\n' "$PRIVATE_EMAIL" >"$P/README.md"
  printf 'private art\n' >"$P/art/secret/sprite.txt"
  printf 'archive bytes\n' >"$P/plugin/demo/data.tgz"
  printf 'print("one")\n' >"$P/main.lua"
  private_git add -A && private_git commit -qm "first"
  printf 'print("two")\n' >"$P/two.lua"
  private_git add -A && private_git commit -qm "second"
  private_git rm -rq art
  printf '# demo\n\n- Email: <%s>\n' "$PUBLIC_EMAIL" >"$P/README.md"
  printf 'Dev <%s>\n' "$PRIVATE_EMAIL" >"$P/.mailmap"
  private_git add -A && private_git commit -qm "third"
  c1=$(git -C "$P" rev-parse main~2) c2=$(git -C "$P" rev-parse main~1) c3=$(git -C "$P" rev-parse main)
  secret=$(git -C "$P" rev-parse "$c1:art/secret/sprite.txt")
  mkdir -p "$m/msg"
  printf 'Add the demo\n\nThe first scene and its art.\n' >"$m/msg/one.txt"
  printf 'Add a second scene\n' >"$m/msg/two.txt"
  printf 'Remove the art\n' >"$m/msg/three.txt"
  printf 'Keep the first line apart\n' >"$m/msg/legacy.txt"
  printf 'demo 1.0\n' >"$m/msg/tag-v1.txt"
  printf 'demo legacy 0.9\n' >"$m/msg/tag-legacy.txt"
  {
    row identity Pub "$PUBLIC_EMAIL"
    row commit one "$c1" - "1700000000 +0200" msg/one.txt
    row drop one "$DROP"
    row swap one README.md "- Email: <$PRIVATE_EMAIL>" "- Email: <$PUBLIC_EMAIL>"
    row commit two "$c2" one "1700003600 -0500" msg/two.txt
    row drop two "$DROP"
    row swap two README.md "- Email: <$PRIVATE_EMAIL>" "- Email: <$PUBLIC_EMAIL>"
    row trailer two "Co-authored-by: Helper <helper@example.invalid>"
    row commit three "$c3" two "1700007200 +0000" msg/three.txt
    row drop three '^\.mailmap$'
    row commit legacy "$c1" - "1690000000 +0100" msg/legacy.txt
    row drop legacy "$DROP"
    row swap legacy README.md "- Email: <$PRIVATE_EMAIL>" "- Email: <$PUBLIC_EMAIL>"
    row tag refs/tags/v1.0 two msg/tag-v1.txt
    row tag refs/tags/legacy-0.9 legacy msg/tag-legacy.txt
    row ref refs/heads/main three
    row ref refs/heads/legacy legacy
    row ref refs/tags/line three
  } >"$m/map.tsv"
  {
    row text 'dev@private\.invalid'
    row path "$DROP"
    row object "$secret"
    row sha "${c2:0:9}"
  } >"$F/deny.tsv"
  printf '%s  plugin/demo/data.tgz\n' "$(shasum -a 256 <"$P/plugin/demo/data.tgz" | cut -d' ' -f1)" >"$F/hashes.txt"
}

# variant name: a copy of the map directory to seed a defect in; prints its path
variant() { rm -rf "$F/$1" && cp -R "$F/map" "$F/$1" && echo "$F/$1"; }

# export_to out [map-dir]: the export of the map (default the fixture's) into a new repo out
export_to() { rm -rf "$1" && python3 "$TOOL" export --map "${2:-$F/map}/map.tsv" --repo "$P" "$1"; }

# verify target map-dir [flag...]: the verifier over target with the fixture's deny-file and the hash list HASHES
# (default the fixture's)
verify() {
  local target=$1 map=$2
  shift 2
  python3 "$TOOL" verify --map "$map/map.tsv" --repo "$P" --deny-file "$F/deny.tsv" \
    --hashes "${HASHES:-$F/hashes.txt}" --hash-ref refs/tags/v1.0 "$@" "$target"
}

# fires check detail target [map-dir [flag...]]: the verifier exits 1 with a FAIL line of check whose detail matches
# the regex
fires() {
  local check=$1 detail=$2 out rc=0
  out=$(verify "$3" "${4:-$F/map}" "${@:5}") || rc=$?
  printf 'rc %s\n%s\n' "$rc" "$out"
  (( rc == 1 )) && grep -qE "^FAIL $check: $detail" <<<"$out"
}

# delta repo private public: name-status of the tree of public (a rev of repo) against the tree of private (a rev of the
# private repo)
delta() {
  GIT_ALTERNATE_OBJECT_DIRECTORIES="$P/.git/objects" git -C "$1" diff-tree -r --name-status \
    "$(git -C "$P" rev-parse "$2^{tree}")" "$3^{tree}"
}

# same_shas: a second export from a clone at another path, with another TZ, a GIT_* environment and a HOME whose git
# config signs commits with a failing gpg and records another encoding, prints the same commits, trees and refs, and
# the two repos hold the same refs
same_shas() {
  local out="$SUITE_OUT/twice" first second
  rm -rf "$out" && mkdir -p "$out/home"
  git clone -q --no-hardlinks "$P" "$out/elsewhere/private"
  cp -R "$F/map" "$out/elsewhere/map"
  printf '[commit]\n\tgpgSign = true\n[gpg]\n\tprogram = false\n[i18n]\n\tcommitEncoding = ISO-8859-1\n' \
    >"$out/home/.gitconfig"
  first=$(TZ=Pacific/Auckland export_to "$out/a")
  second=$(TZ=America/Sao_Paulo HOME="$out/home" GIT_CONFIG_GLOBAL="$out/home/.gitconfig" GIT_AUTHOR_NAME=Other \
    GIT_COMMITTER_DATE="1000000000 +0000" python3 "$TOOL" export --map "$out/elsewhere/map/map.tsv" \
    --repo "$out/elsewhere/private" "$out/b")
  printf '%s\n' "$first"
  [[ -n "$first" && "$first" == "$second" ]] &&
    [[ "$(git -C "$out/a" for-each-ref)" == "$(git -C "$out/b" for-each-ref)" ]]
}

# exact_delta: name-status of each public tree against its private tree is exactly the map's drops and swaps, and the
# swapped README.md line reads the public email
exact_delta() {
  local e="$SUITE_OUT/delta"
  export_to "$e" >/dev/null
  [[ "$(delta "$e" main~2 legacy)" == $'M\tREADME.md\nD\tart/secret/sprite.txt' ]] &&
    [[ "$(delta "$e" main~1 v1.0)" == $'M\tREADME.md\nD\tart/secret/sprite.txt' ]] &&
    [[ "$(delta "$e" main main)" == $'D\t.mailmap' ]] &&
    [[ "$(git -C "$e" show v1.0:README.md)" == "# demo"$'\n\n'"- Email: <$PUBLIC_EMAIL>" ]]
}

# drop_matching_nothing: export exits 2 on a drop no path of its commit matches, naming it
drop_matching_nothing() {
  local v out rc=0
  v=$(variant nomatch)
  row drop three '^nothing/' >>"$v/map.tsv"
  out=$(export_to "$SUITE_OUT/nomatch" "$v" 2>&1) || rc=$?
  printf 'rc %s\n%s\n' "$rc" "$out"
  (( rc == 2 )) && grep -q 'three: drop ^nothing/ matches no path' <<<"$out"
}

# passes target [flag...]: the verifier exits 0 with every check OK
passes() {
  local out rc=0
  out=$(verify "$1" "$F/map" "${@:2}") || rc=$?
  printf 'rc %s\n%s\n' "$rc" "$out"
  (( rc == 0 )) && [[ "$(grep -c '^OK ' <<<"$out")" == 7 ]] && ! grep -q '^FAIL' <<<"$out"
}

pub_clone() {
  rm -rf "$SUITE_OUT/clone"
  git clone -q "$F/export" "$SUITE_OUT/clone"
  passes "$SUITE_OUT/clone" --pub
}

# pub_extra_branch: with --pub, a branch of the clone's origin that the map does not name fails refs
pub_extra_branch() {
  local c="$SUITE_OUT/pub-extra"
  rm -rf "$c" && git clone -q "$F/export" "$c"
  git -C "$c" update-ref refs/remotes/origin/extra refs/remotes/origin/main
  fires refs 'extra refs/heads/extra$' "$c" "$F/map" --pub
}

# seeded name: a copy of the fixture's export to seed a defect in; prints its path
seeded() { rm -rf "$SUITE_OUT/$1" && cp -R "$F/export" "$SUITE_OUT/$1" && echo "$SUITE_OUT/$1"; }

other_identity() {
  local e c
  e=$(seeded identity)
  c=$(git -C "$e" log -1 --format=%B main |
    AUTHOR_EMAIL=other@example.invalid as_public "$e" commit-tree "main^{tree}" -p main~1)
  git -C "$e" update-ref refs/heads/main "$c"
  fires identity "commit $c: author Pub <other@example.invalid>" "$e"
}

# message_seed name file text check detail: an export of a map whose message file carries text fails check
message_seed() {
  local v
  v=$(variant "$1")
  printf '%s\n' "$3" >>"$v/msg/$2"
  export_to "$SUITE_OUT/$1" "$v" >/dev/null
  fires "$4" "$5" "$SUITE_OUT/$1" "$v"
}

# message_id: the id is assembled at run time so this file itself passes the leak scan
message_id() {
  local id
  id=$(printf '%s%s' Q 9)
  message_seed leak-id three.txt "Fixes $id in the parser" messages ".*matches '$id'"
}

message_sha() {
  local sha
  sha=$(git -C "$P" rev-parse --short=9 main~1)
  message_seed leak-sha two.txt "From $sha" messages ".*matches '$sha'"
}

extra_trailer() {
  message_seed trailer three.txt $'\nSigned-off-by: Someone <someone@example.invalid>' trailers \
    ".*trailers \['Signed-off-by: Someone <someone@example.invalid>'\], the map \[\]"
}

# kept_private: a map that keeps the first commit's art and email fails deny on the text, the path and the object
kept_private() {
  local v e="$SUITE_OUT/kept" object
  v=$(variant kept)
  grep -v -e $'^drop\tone\t' -e $'^swap\tone\t' "$F/map/map.tsv" >"$v/map.tsv"
  export_to "$e" "$v" >/dev/null
  object=$(git -C "$P" rev-parse main~2:art/secret/sprite.txt)
  fires deny 'text dev@private' "$e" "$v" &&
    fires deny 'path \(\^\|/\)secret/ matches art/secret/sprite.txt$' "$e" "$v" &&
    fires deny "object $object \(blob\)" "$e" "$v"
}

wrong_hash() {
  printf '%064d  plugin/demo/data.tgz\n' 0 >"$F/wrong-hashes.txt"
  HASHES="$F/wrong-hashes.txt" fires hashes 'refs/tags/v1.0:plugin/demo/data.tgz is [0-9a-f]{64}, the list 0{64}$' \
    "$F/export"
}

extra_ref() {
  local e
  e=$(seeded extra-ref)
  git -C "$e" update-ref refs/notes/extra main
  fires refs 'extra refs/notes/extra$' "$e"
}

missing_ref() {
  local e
  e=$(seeded missing-ref)
  git -C "$e" update-ref -d refs/tags/line
  fires refs 'missing refs/tags/line$' "$e"
}

# tree_off_map: main replaced by a commit of the same identity, date and message with one more file fails trees
tree_off_map() {
  local e blob tree c
  e=$(seeded tree)
  blob=$(printf 'extra\n' | git -C "$e" hash-object -w --stdin)
  tree=$( (git -C "$e" ls-tree main; printf '100644 blob %s\textra.txt\n' "$blob") | git -C "$e" mktree)
  c=$(git -C "$e" log -1 --format=%B main | as_public "$e" commit-tree "$tree" -p main~1)
  git -C "$e" update-ref refs/heads/main "$c"
  fires trees "three $c: extra.txt is \('100644', '$blob'\), the map absent" "$e"
}

# scan_trees: scan passes the last private tree without .mailmap and fails the first one on its art and email
scan_trees() {
  local out rc=0
  python3 "$TOOL" scan --deny-file "$F/deny.tsv" --repo "$P" --drop '^\.mailmap$' main || return 1
  out=$(python3 "$TOOL" scan --deny-file "$F/deny.tsv" --repo "$P" main~2) || rc=$?
  printf 'rc %s\n%s\n' "$rc" "$out"
  (( rc == 1 )) && grep -q '^FAIL deny: path (^|/)secret/ matches art/secret/sprite.txt$' <<<"$out" &&
    grep -q '^FAIL deny: text dev@private\\.invalid in blob ' <<<"$out"
}

fixture
export_to "$F/export" >"$SUITE_OUT/export.out"
run_test "export: a clone at another path, TZ, HOME and git config gives the same SHAs" same_shas
run_test "export: public trees are the private trees minus exactly the map's drops and swaps" exact_delta
run_test "export: a drop that matches no path fails" drop_matching_nothing
run_test "verify: the export passes" passes "$F/export"
run_test "verify --pub: a clone of the export passes" pub_clone
run_test "firing: another identity fails identity" other_identity
run_test "firing: an undeclared trailer fails trailers" extra_trailer
run_test "firing: an id in a message fails messages" message_id
run_test "firing: a private sha in a message fails messages" message_sha
run_test "firing: a kept private file fails deny on text, path and object" kept_private
run_test "firing: a wrong archive hash fails hashes" wrong_hash
run_test "firing: an extra ref fails refs" extra_ref
run_test "firing: a missing ref fails refs" missing_ref
run_test "firing: --pub, an origin branch off the map fails refs" pub_extra_branch
run_test "firing: a tree off the map fails trees" tree_off_map
run_test "scan: a public tree passes and a private one fails" scan_trees
