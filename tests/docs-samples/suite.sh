#!/bin/bash
# docs-samples: the Lua samples of docs/**/*.rst as the line's docs build shows them (extract.py: the @SPINE_PLUGIN@
# expansion of docs/_ext/spineline.py, `.. only::` on the line's tag), each run in its own process on the plain
# lifecycle host (tests/lifecycle build.sh/run.sh --plain: the real plugin over solar2d_stub.lua) under prelude.lua.
# The cwd is a view of the line's exports in which a sample finds name.* in name/, in the root, under assets/ and
# under assets/characters/ (so "assets/characters/spineboy.atlas" is the line's spineboy). One test per page family
# (extract.py FAMILIES): PASS iff every "run" sample exits 0, every "fragment" sample fails (a sample that runs under
# the prelude is not a fragment) and no marker is bad; "simulator" samples are only counted here; a Simulator
# sample needs its own sim-suite row (A6). Then keys vs pages (keys_pages.py) against the line's tests/api surface,
# in both directions, spineline_test.py's line and base-URL mappings, the API page section contract C-1
# (sections.py), the API toctrees the sidebar shows (sidebar.py), and the firing proofs: an injected failing sample, a
# fragment that runs, a fragment without a reason, a key without a page, a page without a key, a nested section, an
# unknown section name, sections out of order, a sub-section under Overview, a bad header line, a long sidebar label
# and a page listed twice each fail their check. The counts go to $SUITE_OUT/counts.tsv and
# the fragments to $SUITE_OUT/fragments.tsv.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
LC="$W/../lifecycle"
DOCS="$SPINE_REPO/docs"
LINE_SPINES=$SPINE_SPINES
VIEW="$SUITE_OUT/spines"
FAMILIES=$(python3 -B -c 'import sys; sys.path.insert(0, sys.argv[1]); import extract
print(" ".join(sorted({name for _, name in extract.FAMILIES} | {extract.GUIDES})))' "$W")
PROOF=docsSamplesFiringProof

# view: the line's exports as the samples load them
view() {
  local d f
  rm -rf "$VIEW" && mkdir -p "$VIEW"
  for d in "$LINE_SPINES"/*/; do
    d=${d%/}
    ln -s "$d" "$VIEW/${d##*/}"
    for f in "$d"/*; do [[ -f "$f" && ! -e "$VIEW/${f##*/}" ]] && ln -s "$f" "$VIEW/${f##*/}"; done
  done
  ln -s . "$VIEW/assets"
  ln -s . "$VIEW/characters"
}

# samples docs out: extracts docs's samples into out and runs every run and fragment sample, one row per sample in
# out/runs.tsv (family, kind, source, rc), its output in out/<family>/<n>.log
samples() {
  local fam kind source file reason rc
  rm -rf "$2"
  python3 -B "$W/extract.py" "$1" "$SPINE_RUNTIME" "$2"
  : >"$2/runs.tsv"
  while IFS=$'\t' read -r fam kind source file reason; do
    rc=-
    if [[ "$kind" == run || "$kind" == fragment ]]; then
      rc=0
      SPINE_RUNTIME=$SPINE_RUNTIME SPINE_TEST_OUT=$SPINE_TEST_OUT SDKROOT=$SDKROOT SPINE_SPINES=$VIEW OUT=$SUITE_OUT \
        "$LC/run.sh" --plain "$W/prelude.lua" "$file" >"${file%.lua}.log" 2>&1 </dev/null || rc=$?
    fi
    printf '%s\t%s\t%s\t%s\n' "$fam" "$kind" "$source" "$rc" >>"$2/runs.tsv"
  done <"$2/samples.tsv"
}

# family out name: every run sample of the family passed, every fragment failed, no marker is bad
family() {
  awk -F'\t' -v f="$2" -v out="$1" '
    FILENAME ~ /samples\.tsv$/ { if ($1 == f) { n++; file[n] = $4; reason[n] = $5 } next }
    $1 != f { next }
    { m++; count[$2]++ }
    $2 == "run" && $4 != 0 { print "FAIL " $3 " (a run sample raised; log " substr(file[m], 1, length(file[m]) - 4) ".log)"; bad = 1 }
    $2 == "fragment" && $4 == 0 { print "FAIL " $3 " (a fragment that runs under the prelude: drop its marker)"; bad = 1 }
    $2 == "bad" { print "FAIL " $3 " (" reason[m] ")"; bad = 1 }
    END {
      printf "%s: %d run, %d fragment, %d simulator\n", f, count["run"], count["fragment"], count["simulator"]
      exit bad
    }' "$1/samples.tsv" "$1/runs.tsv"
}

# proof name page expected text: a scratch docs tree holding only page (text), whose family must fail with expected
proof() {
  local src="$SUITE_OUT/proof-$1" out
  rm -rf "$src" && mkdir -p "$src"
  printf '%s\n' "$4" >"$src/$2"
  samples "$src" "$src.out"
  if out=$(family "$src.out" quickstart); then printf '%s\n' "$out"; echo "the family passed"; return 1; fi
  printf '%s\n' "$out"
  grep -qF "$3" <<<"$out"
}

# surface: the line's Lua surface (tests/api/surface.py over the preprocessed bindings) as $SUITE_OUT/surface.tsv
surface() {
  local f
  rm -rf "$SUITE_OUT/surface" && mkdir -p "$SUITE_OUT/surface"
  for f in "$SPINE_REPO"/shared/*.cpp; do
    clang++ -std=c++17 -E "${HOST_INC[@]}" "$f" -o "$SUITE_OUT/surface/$(basename "$f").i"
  done
  python3 -B "$W/../api/surface.py" "$SPINE_REPO/shared" "$SUITE_OUT/surface"/*.i >"$SUITE_OUT/surface.tsv"
}

# check mode surface api: keys_pages.py on the line's pages
check() { python3 -B "$W/keys_pages.py" "$1" "$SPINE_RUNTIME" "${@:2}"; }

# check_fires mode surface api expected: the check fails and names expected
check_fires() {
  local out
  if out=$(check "$1" "$2" "$3"); then printf '%s\n' "$out"; echo "the check passed"; return 1; fi
  printf '%s\n' "$out"
  grep -qF "$4" <<<"$out"
}

# api_fires check name page old new expected: check.py (sections or sidebar) fails on a scratch copy of $API whose page
# has its first old replaced by new, and names the page with expected
api_fires() {
  local api="$SUITE_OUT/$1-$2" out
  rm -rf "$api" && cp -R "$API" "$api"
  python3 -B -c 'import sys, pathlib
page, old, new = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
text = page.read_text(encoding="utf-8")
assert old in text, f"{page}: no {old!r} to replace"
page.write_text(text.replace(old, new, 1), encoding="utf-8")' "$api/$3" "$4" "$5"
  if out=$(python3 -B "$W/$1.py" "$SPINE_RUNTIME" "$api"); then printf '%s\n' "$out"; echo "the check passed"; return 1; fi
  printf '%s\n' "$out"
  grep -F "$3: " <<<"$out" | grep -qF "$6"
}
sections_fires() { api_fires sections "$@"; }
sidebar_fires() { api_fires sidebar "$@"; }

view
export SPINE_SPINES=$VIEW
source "$W/../host/host.sh"
SPINE_RUNTIME=$SPINE_RUNTIME SPINE_TEST_OUT=$SPINE_TEST_OUT SDKROOT=$SDKROOT SPINE_SPINES=$VIEW OUT=$SUITE_OUT \
  "$LC/build.sh" plain
start=$SECONDS
samples "$DOCS" "$SUITE_OUT/docs"
for f in $FAMILIES; do run_test "samples $f" family "$SUITE_OUT/docs" "$f"; done
awk -F'\t' '{ n[$2]++ } END { printf "headless\t%d\nsimulator\t%d\nfragment\t%d\n", n["run"], n["simulator"], n["fragment"] }' \
  "$SUITE_OUT/docs/samples.tsv" | tee "$SUITE_OUT/counts.tsv"
awk -F'\t' '$2 == "fragment" { print $1 "\t" $3 "\t" $5 }' "$SUITE_OUT/docs/samples.tsv" >"$SUITE_OUT/fragments.tsv"
echo "samples: $((SECONDS - start)) s"

surface
API="$DOCS/api_reference"
run_test "keys have pages" check keys "$SUITE_OUT/surface.tsv" "$API"
run_test "pages name keys" check pages "$SUITE_OUT/surface.tsv" "$API"
run_test "spineline line and base url" python3 -B "$W/spineline_test.py" "$DOCS/_ext"
run_test "sections: api pages follow C-1" python3 -B "$W/sections.py" "$SPINE_RUNTIME" "$API"
run_test "sidebar: api toctrees use short labels, each page once" python3 -B "$W/sidebar.py" "$SPINE_RUNTIME" "$API"

run_test "firing: a failing sample fails its family" proof sample quickstart.rst "quickstart.rst:4 (a run sample raised" \
  "$(printf '%s\n' Proof ===== '' '.. code-block:: lua' '' "   error(\"$PROOF\")")"
run_test "firing: a fragment that runs fails its family" proof fragment quickstart.rst "quickstart.rst:4 (a fragment that runs" \
  "$(printf '%s\n' Proof ===== ".. fragment: $PROOF" '.. code-block:: lua' '' '   print(spineboy.timeScale)')"
run_test "firing: a fragment without a reason fails its family" proof reason quickstart.rst "has no one-line reason" \
  "$(printf '%s\n' Proof ===== '.. fragment' '.. code-block:: lua' '' '   local x = y.z')"
cp "$SUITE_OUT/surface.tsv" "$SUITE_OUT/surface-proof.tsv"
printf 'SpineBone\tget\t%s\n' "$PROOF" >>"$SUITE_OUT/surface-proof.tsv"
run_test "firing: a key without a page fails" check_fires keys "$SUITE_OUT/surface-proof.tsv" "$API" \
  "SpineBone.$PROOF: no page"
rm -rf "$SUITE_OUT/api-proof" && cp -R "$API" "$SUITE_OUT/api-proof"
: >"$SUITE_OUT/api-proof/skeleton/bone/$PROOF.rst"
run_test "firing: a page without a key fails" check_fires pages "$SUITE_OUT/surface.tsv" "$SUITE_OUT/api-proof" \
  "skeleton/bone/$PROOF.rst: SpineBone has no public key"
SECTIONS_PAGE=skeleton/clearTrack.rst
run_test "firing: sections catches a nested section" sections_fires nested "$SECTIONS_PAGE" \
  $'Example\n-------\n' $'Example\n.......\n' "heading 'Example' is neither a section"
run_test "firing: sections catches an unknown section name" sections_fires unknown "$SECTIONS_PAGE" \
  $'Example\n-------\n' $'Examples\n--------\n' "unknown section 'Examples'"
run_test "firing: sections catches sections out of order" sections_fires order "$SECTIONS_PAGE" \
  $'Syntax\n------\n' $'Notes\n-----\n' "section 'Parameters' out of order"
run_test "firing: sections catches a sub-section under Overview" sections_fires overview "$SECTIONS_PAGE" \
  $'Overview\n--------\n' $'Overview\n--------\n\nProof\n~~~~~\n' "sub-section 'Proof' under Overview"
run_test "firing: sections catches a bad header line" sections_fires header "$SECTIONS_PAGE" \
  '| **Type:** ' '| **Type**: ' "header line is not"
run_test "firing: sidebar catches a long label" sidebar_fires label skeleton/index.rst \
  'setAnimation() <setAnimation>' 'skeleton:setAnimation() <setAnimation>' \
  "entry 'skeleton:setAnimation() <setAnimation>' is not 'setAnimation() <setAnimation>'"
run_test "firing: sidebar catches a page listed twice" sidebar_fires twice skin/index.rst \
  $'   :maxdepth: 1\n\n' $'   :maxdepth: 1\n\n   setAnimation() <../skeleton/setAnimation>\n' \
  "skeleton/setAnimation is already listed at skeleton/index.rst"
