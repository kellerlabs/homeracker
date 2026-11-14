#!/usr/bin/env bash
#
# Tests install-system-deps.sh on a real apt: cold install, offline reinstall from the cached
# .deb files, and a cache whose package list changed.
# Removes and reinstalls system packages, so run it on a disposable machine only.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly INSTALL="$SCRIPT_DIR/install-system-deps.sh"
readonly OFFLINE_CONF=/etc/apt/apt.conf.d/99-setup-openscad-offline-test

work="$(mktemp -d)"
readonly work
readonly deb_dir="$work/debs"
trap 'sudo rm -f "$OFFLINE_CONF"; sudo rm -rf "$work"' EXIT

# Runs the install script and prints the value it wrote for the given output name.
run_install() {
  local output="$work/output"
  : > "$output"
  GITHUB_OUTPUT="$output" "$INSTALL" "$deb_dir" >&2
  sed -n "s/^$1=//p" "$output"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

printf '== cold install downloads from the mirrors\n'
source="$(run_install source)"
[[ "$source" == network ]] || fail "expected source=network, got '$source'"
debs=("$deb_dir"/*.deb)
[[ -e "${debs[0]}" ]] || fail "no .deb files to cache, the image already ships every package"

printf '== cached install works with the mirrors unreachable\n'
names=()
for deb in "${debs[@]}"; do
  names+=("$(dpkg-deb -f "$deb" Package)")
done
sudo apt-get remove -y "${names[@]}"
printf 'Acquire::http::Proxy "http://127.0.0.1:9";\nAcquire::https::Proxy "http://127.0.0.1:9";\n' \
  | sudo tee "$OFFLINE_CONF" > /dev/null
source="$(run_install source)"
[[ "$source" == cache ]] || fail "expected source=cache, got '$source'"
dpkg -s "${names[@]}" > /dev/null || fail "cached install left packages missing"

printf '== a changed package list is not served from the cache\n'
printf 'other packages\n' > "$deb_dir/packages.txt"
source="$(run_install source)"
[[ "$source" == network ]] || fail "expected source=network, got '$source'"

printf 'PASS\n'
