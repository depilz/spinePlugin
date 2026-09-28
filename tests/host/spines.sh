# The runtime lines' example exports; source this file from bash (tests/run.sh and tests/host/host.sh do).
#   SPINE_REPO      checkout whose Corona*/spines are read
#   SPINE_TEST_OUT  the 4.3 flat view goes to $SPINE_TEST_OUT/spines

# flat_spines src view: links an export tree in the 4.3 layout (folder/export/name[-pro|-ess].*) into the 4.2 flat
# layout (view/name/name.*) and prints view. name.skel and name.json are the plain export, else -pro, else -ess
# (Corona43/Spine.lua's order); name.atlas falls back to the folder's atlas (sack lives in 7-anticipation).
flat_spines() {
  local src=$1 view=$2 export folder f name dir ext cand
  rm -rf "$view"
  for export in "$src"/*/export; do
    folder=${export%/export}; folder=${folder##*/}
    for f in "$export"/*.skel "$export"/*.json; do
      [[ -e "$f" ]] || continue
      name=${f##*/}; name=${name%.*}; name=${name%-pro}; name=${name%-ess}
      dir="$view/$name"
      [[ -d "$dir" ]] && continue
      mkdir -p "$dir"
      ln -s "$export"/* "$dir/"
      for ext in atlas skel json; do
        for cand in "$name.$ext" "$name-pro.$ext" "$name-ess.$ext" "$folder.$ext"; do
          [[ -e "$dir/$cand" ]] || continue
          [[ "$cand" == "$name.$ext" ]] || ln -s "$cand" "$dir/$name.$ext"
          break
        done
      done
    done
  done
  echo "$view"
}

# line_spines runtime: the line's example exports in the 4.2 flat layout, the suites' cwd (SPINE_SPINES)
line_spines() {
  case "$1" in
    4.2) echo "$SPINE_REPO/Corona/spines" ;;
    *) flat_spines "$SPINE_REPO/Corona${1//./}/spines" "$SPINE_TEST_OUT/spines" ;;
  esac
}

# export_version file: the Spine version an export was made with, from the JSON skeleton.spine field or the
# .skel header (8-byte hash, then the version as a string whose one-byte varint length counts the terminator)
export_version() {
  local n
  case "$1" in
    *.json) grep -m 1 -oE '"spine" *: *"[^"]*"' "$1" | head -n 1 | cut -d '"' -f 4 ;;
    *.skel)
      n=$(od -An -tu1 -j8 -N1 "$1" | tr -d ' ')
      if (( n > 1 && n < 128 )); then tail -c +10 "$1" | head -c $((n - 1)); fi ;;
  esac
}

# spines_check: fails unless every export in SPINE_SPINES/*/ was made with Spine SPINE_RUNTIME; runs once per
# (SPINE_RUNTIME, SPINE_SPINES), remembered in SPINE_SPINES_CHECKED
spines_check() {
  local f v bad=0 seen=0 key="$SPINE_RUNTIME:$SPINE_SPINES"
  [[ "${SPINE_SPINES_CHECKED:-}" == "$key" ]] && return 0
  for f in "$SPINE_SPINES"/*/*.json "$SPINE_SPINES"/*/*.skel; do
    [[ -e "$f" ]] || continue
    seen=$((seen + 1))
    v=$(export_version "$f" || true)
    [[ "$v" == "$SPINE_RUNTIME".* ]] && continue
    (( bad++ < 5 )) && echo "spines: $f is a Spine '${v:-?}' export, not $SPINE_RUNTIME" >&2
  done
  (( seen )) || { echo "spines: no .json/.skel export under $SPINE_SPINES/*/" >&2; return 1; }
  (( bad )) && { echo "spines: $bad of $seen exports under $SPINE_SPINES are not Spine $SPINE_RUNTIME" >&2; return 1; }
  export SPINE_SPINES_CHECKED=$key
}
