#!/bin/bash
# run.sh: named-only
# docs: the Sphinx build of docs/ once per plugin line (SPINE_DOCS_LINE, the lines of docs/_ext/spineline.py), each with
# -W --keep-going -E into its own output and doctree dir, in a venv made from docs/requirements.txt under $SUITE_OUT
# (a missing Python or network fails "venv" and every build row; there is no skip). Per line: the build exits 0 with
# no warning; its rendered pages name no plugin.spine4x but its own, outside the pages that name both lines on purpose
# (ALLOWED); and a scratch copy of docs/ with a broken :doc: link in index.rst fails the build on that link. Runs on the
# 4.2 line only (ONLY_42 in tests/run.sh): the docs tree is one for both runtime lines.
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
source "$W/../lib.sh"
DOCS="$SPINE_REPO/docs"
VENV="$SUITE_OUT/venv"
ALLOWED="index migration naming"
BROKEN=i11-no-such-page

# make_venv: the venv with docs/requirements.txt installed, reinstalled when the requirements change
make_venv() {
  cmp -s "$DOCS/requirements.txt" "$VENV/requirements.txt" && [[ -x "$VENV/bin/sphinx-build" ]] && return
  rm -rf "$VENV"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q -r "$DOCS/requirements.txt"
  cp "$DOCS/requirements.txt" "$VENV/requirements.txt"
}

# build line src out: the line's build of src into $SUITE_OUT/<out>/{html,doctrees}, its warnings on stdout
build() {
  rm -rf "$SUITE_OUT/$3"
  SPINE_DOCS_LINE=$1 "$VENV/bin/sphinx-build" -W --keep-going -E -q -b html -d "$SUITE_OUT/$3/doctrees" "$2" \
    "$SUITE_OUT/$3/html" 2>&1
}

# clean_build line: exits 0 and writes no warning
clean_build() {
  local out
  out=$(build "$1" "$DOCS" "build-$1") || { printf '%s\n' "$out"; return 1; }
  printf '%s\n' "$out"
  ! grep -q WARNING <<<"$out"
}

# own_name line plugin: every plugin.spine4x in the line's rendered pages outside ALLOWED is the line's own
own_name() {
  local html="$SUITE_OUT/build-$1/html" page bad=0
  [[ -f "$html/index.html" ]] || { echo "no build of $1"; return 1; }
  while IFS= read -r page; do
    case " $ALLOWED " in *" ${page%.html} "*) continue ;; esac
    if grep -oE 'plugin\.spine4[0-9]' "$html/$page" | grep -qvxF "$2"; then echo "names another line: $page"; bad=1; fi
  done < <(cd "$html" && find . -name '*.html' -not -path './_sources/*' | sed 's|^\./||' | sort)
  return $bad
}

# broken_link_fails line: a scratch docs/ whose index.rst links a missing page fails the build on that link
broken_link_fails() {
  local src="$SUITE_OUT/broken-src-$1" out
  rm -rf "$src"
  rsync -a --exclude _build --exclude .venv --exclude venv --exclude env "$DOCS/" "$src/"
  printf '\n:doc:`%s`\n' "$BROKEN" >>"$src/index.rst"
  if out=$(build "$1" "$src" "broken-$1"); then printf '%s\n' "$out"; echo "the broken link built"; return 1; fi
  printf '%s\n' "$out"
  grep -q "WARNING: unknown document: '$BROKEN'" <<<"$out"
}

run_test venv make_venv
while read -r line plugin; do
  run_test "$line build: exit 0, no warning" clean_build "$line"
  run_test "$line pages name only $plugin outside $ALLOWED" own_name "$line" "$plugin"
  run_test "$line broken :doc: fails the build" broken_link_fails "$line"
done < <(python3 -c 'import sys; sys.path.insert(0, sys.argv[1]); import spineline
for line, v in spineline.LINES.items(): print(line, v["plugin"])' "$DOCS/_ext")
