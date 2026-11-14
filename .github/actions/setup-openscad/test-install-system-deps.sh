#!/usr/bin/env bash
#
# Tests install-system-deps.sh on a real apt: cold install, offline reinstall from the cached
# .deb files, a required package the cache lacks, and a cache whose package list changed.
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
  # Explicit return: set -e is off when the caller tests this function's status.
  GITHUB_OUTPUT="$output" "$INSTALL" "$deb_dir" >&2 || return
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

# A required package the image shipped is absent from the cache, so losing it must not pass as cached.
printf '== a required package missing from image and cache is not reported as cached\n'
uncached=""
read -r -a required < "$deb_dir/packages.txt"
for package in "${required[@]}"; do
  if [[ " ${names[*]} " != *" $package "* ]] && dpkg -s "$package" > /dev/null 2>&1; then
    uncached="$package"
    break
  fi
done
if [[ -z "$uncached" ]]; then
  printf 'skipped: the cache holds every required package\n'
else
  sudo apt-get remove -y "$uncached"
  if source="$(run_install source)"; then
    fail "removed $uncached, expected a failed fallback to the unreachable mirrors, got source=$source"
  fi
fi
sudo rm -f "$OFFLINE_CONF"

printf '== a changed package list is not served from the cache\n'
printf 'other packages\n' > "$deb_dir/packages.txt"
source="$(run_install source)"
[[ "$source" == network ]] || fail "expected source=network, got '$source'"

printf 'PASS\n'
