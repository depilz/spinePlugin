#!/bin/bash
# masks: the line's clipping (SkeletonRenderer render loop, SkeletonClipping, Triangulator) against the editor's, every
# frame of every animation, with comparator.cpp (see its header), plain build. One test per public input, always:
#   example <name>     every example export in SPINE_SPINES that has an atlas, all skins
#   spineboy head-bb   spineboy with its head-bb bounding box shown: the clip must end at that slot (D-B)
#   spineboy-da        spineboy with the clipping bone skin-required and the clip in the setup pose, so the clip sits
#                      on an inactive bone and must not clip (D-A; the comparator edits the loaded data in memory)
# On 4.3 the public rows cover only the D-A/D-B render loop (the reference clipper is the line's own); the 4.3
# clipper and Triangulator are covered only by private tritest43.
# Private inputs (never in the repo) run only when SPINE_MASKS_PRIVATE_DIR is set. Their test ids are the line's rows
# of optional.tsv, declared optional there for the expected-ids manifest; this suite runs exactly those rows:
#   private masked     $SPINE_MASKS_PRIVATE_DIR/masked.txt lists .skel files (atlas beside, same name) relative to
#                      $SPINE_MASKS_PRIVATE_DIR/app, all skins each
#   private tritest43  the triangulation check on every $SPINE_MASKS_PRIVATE_DIR/dump_*.txt clip polygon
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
"$W/build.sh" plain
CMP="$SUITE_OUT/comparator_plain"
SPINES="${SPINE_SPINES:-$SPINE_REPO/Corona/spines}"

# compare test name comparator-options...: the comparator on SPINES/name (name.atlas, name.skel else name.json)
compare() {
  local test=$1 dir="$SPINES/$2/$2" skeleton
  shift 2
  skeleton="$dir.skel"
  [[ -e "$skeleton" ]] || skeleton="$dir.json"
  run_test "$test" "$CMP" run "$dir.atlas" "$skeleton" "$@"
}

for dir in "$SPINES"/*/; do
  name=$(basename "$dir")
  [[ -e "$dir/$name.atlas" ]] || { echo "masks: skipped example $name: no $name.atlas"; continue; }
  compare "example $name" "$name" --skins all
done
compare "spineboy head-bb" spineboy --set head-bb:head --need-clips
compare "spineboy-da" spineboy --inactive-bone clipping --setup-attachment clipping:clipping

private_masked() {
  local skel app="$SPINE_MASKS_PRIVATE_DIR/app" rc=0 count=0
  while read -r skel; do
    [[ -n "$skel" ]] || continue
    count=$((count + 1))
    echo "== $skel"
    "$CMP" run "$app/${skel%.skel}.atlas" "$app/$skel" --skins all || rc=1
  done <"$SPINE_MASKS_PRIVATE_DIR/masked.txt"
  (( rc == 0 && count > 0 ))
}

private_tritest43() {
  local dump rc=0 count=0
  for dump in "$SPINE_MASKS_PRIVATE_DIR"/dump_*.txt; do
    [[ -f "$dump" ]] || continue
    count=$((count + 1))
    "$CMP" tri "$dump" || rc=1
  done
  (( rc == 0 && count > 0 ))
}

if [[ -n "${SPINE_MASKS_PRIVATE_DIR:-}" ]]; then
  while IFS=$'\t' read -r line suite test kind; do
    if [[ "$line" == "$SPINE_RUNTIME" ]]; then run_test "$test" "private_${test#private }"; fi
  done <"$W/optional.tsv"
fi
