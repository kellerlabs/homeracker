#!/bin/bash
# Grammar diff: what changed in OpenSCAD's lexer and parser between the nightly pinned at a base commit and at HEAD.
# Usage: grammar-diff.sh <base-commit> <out-dir>
# Writes <out-dir>/grammar.diff, <out-dir>/grammar.log and a sparse checkout of OpenSCAD's src/core and tests at
# <out-dir>/openscad, then prints key=value lines for $GITHUB_OUTPUT: old, new and changed (true when the diff is
# not empty). A nightly is built from master at some time on its date (UTC), so the range starts before the old
# nightly's date and ends after the new one's. A grammar commit on either day may show up twice, but never gets missed.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <base-commit> <out-dir>" >&2
  exit 2
fi
readonly BASE="$1"
readonly OUT="$2"
readonly UPSTREAM="https://github.com/openscad/openscad"
readonly GRAMMAR=(src/core/lexer.l src/core/parser.y)

# Prints the pinned nightly as YYYY-MM-DD, or nothing unless OpenSCAD is pinned to a dated nightly ("latest" is not).
nightly_date() {
  python3 -c '
import json, re, sys
openscad = json.load(sys.stdin).get("openscad", {})
version = str(openscad.get("version", ""))
if openscad.get("type") == "nightly" and re.fullmatch(r"[0-9]{4}[.][0-9]{2}[.][0-9]{2}", version):
    print(version.replace(".", "-"))
'
}

old="$(git show "${BASE}:scadm.json" | nightly_date)"
new="$(nightly_date < scadm.json)"
echo "old=${old}"
echo "new=${new}"
if [[ -z "${old}" || -z "${new}" || "${old}" == "${new}" ]]; then
  echo "changed=false"
  exit 0
fi

mkdir -p "${OUT}"
clone="${OUT}/openscad"
rm -rf "${clone}"
# History from a week before the old nightly, without file contents until they are needed.
since="$(date -u -d "${old} -7 days" +%Y-%m-%d)"
git clone --quiet --filter=blob:none --no-checkout --shallow-since="${since}" "${UPSTREAM}" "${clone}"
old_commit="$(git -C "${clone}" rev-list -1 --first-parent --before="${old} 00:00:00 +0000" HEAD)"
new_commit="$(git -C "${clone}" rev-list -1 --first-parent --before="${new} 23:59:59 +0000" HEAD)"

git -C "${clone}" diff "${old_commit}" "${new_commit}" -- "${GRAMMAR[@]}" > "${OUT}/grammar.diff"
git -C "${clone}" log --format='%h %ad %s' --date=short "${old_commit}..${new_commit}" -- "${GRAMMAR[@]}" \
  > "${OUT}/grammar.log"
# Grammar and parser sources plus OpenSCAD's own test models, as material for the canary.
git -C "${clone}" sparse-checkout set --no-cone /src/core/ /tests/data/scad/
git -C "${clone}" checkout --quiet "${new_commit}"

if [[ -s "${OUT}/grammar.diff" ]]; then
  echo "changed=true"
else
  echo "changed=false"
fi
