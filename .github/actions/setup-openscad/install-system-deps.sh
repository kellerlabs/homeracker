#!/usr/bin/env bash
#
# Installs the system packages OpenSCAD needs. Cached .deb files install offline; the mirrors
# are only contacted when the cache is empty or its packages do not fit the runner image.
#
# Usage: install-system-deps.sh <deb-dir>
#
# Writes to $GITHUB_OUTPUT:
#   source  cache or network
#   hash    names the downloaded set, only set when <deb-dir> holds a new one to save

set -euo pipefail

readonly PACKAGES=(xvfb libglu1-mesa libfuse2 libegl1 libxcb-cursor0)
readonly DEB_DIR="${1:?usage: install-system-deps.sh <deb-dir>}"
# apt reads and writes .deb files in DEB_DIR in place of /var/cache/apt/archives.
readonly APT_OPTIONS=(-y --no-install-recommends -o Acquire::Retries=5 -o Dir::Cache::Archives="$DEB_DIR")
readonly MANIFEST="$DEB_DIR/packages.txt"
readonly OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

install_from_cache() {
  [[ -f "$MANIFEST" && "$(<"$MANIFEST")" == "${PACKAGES[*]}" ]] || return 1
  local debs=("$DEB_DIR"/*.deb)
  [[ -e "${debs[0]}" ]] || return 1
  sudo apt-get install "${APT_OPTIONS[@]}" --no-download "${debs[@]}"
}

install_from_network() {
  sudo rm -rf "$DEB_DIR"
  mkdir -p "$DEB_DIR"
  sudo apt-get update -o Acquire::Retries=5
  sudo apt-get install "${APT_OPTIONS[@]}" -o APT::Keep-Downloaded-Packages=true "${PACKAGES[@]}"

  local debs=("$DEB_DIR"/*.deb)
  # Nothing was downloaded when the image already ships every package, so there is nothing to cache.
  [[ -e "${debs[0]}" ]] || return 0
  printf '%s\n' "${PACKAGES[*]}" > "$MANIFEST"
  local hash
  hash="$(sha256sum "${debs[@]}" "$MANIFEST" | cut -d' ' -f1 | sha256sum | cut -c1-16)"
  printf 'hash=%s\n' "$hash" >> "$OUTPUT"
}

if install_from_cache; then
  printf 'source=cache\n' >> "$OUTPUT"
else
  install_from_network
  printf 'source=network\n' >> "$OUTPUT"
fi
