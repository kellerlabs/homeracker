#!/usr/bin/env bash
#
# OpenSCAD PNG Export Tool
#
# Exports an isometric preview PNG from an OpenSCAD model file.
# Output is written to a renders/ subfolder as renders/<basename>.png.
#
# Usage:
#   ./cmd/export/export-png.sh <input.scad> [options]
#   ./cmd/export/export-png.sh models/pinpusher/pinpusher.scad
#   ./cmd/export/export-png.sh models/pinpusher/pinpusher.scad --imgsize 1200,900
#   ./cmd/export/export-png.sh models/pinpusher/pinpusher.scad --camera 0,0,0,45,0,25,100
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INSTALL_DIR="${WORKSPACE_ROOT}/bin/openscad"

# Source common functions (provides detect_platform, find_openscad_exe, logging)
# shellcheck source=../lib/common.sh disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

# Defaults
DEFAULT_CAMERA="0,0,0,55,0,35,80"
DEFAULT_IMGSIZE="800,600"
DEFAULT_COLORSCHEME="Tomorrow"

usage() {
    echo "Usage: $(basename "$0") <input.scad> [--camera CAM] [--imgsize WxH] [--colorscheme NAME]"
    echo ""
    echo "Options:"
    echo "  --camera        Camera params: translate_x,y,z,rot_x,y,z,dist (default: ${DEFAULT_CAMERA})"
    echo "  --imgsize       Image size: width,height (default: ${DEFAULT_IMGSIZE})"
    echo "  --colorscheme   OpenSCAD color scheme (default: ${DEFAULT_COLORSCHEME})"
    echo "                  Available: Cornfield, Metallic, Sunset, Starnight, BeforeDawn,"
    echo "                  Nature, Daylight Gem, Nocturnal Gem, DeepOcean, Solarized,"
    echo "                  Tomorrow, Tomorrow Night, ClearSky, Monotone"
    exit 1
}

# Parse arguments
[[ $# -lt 1 ]] && usage

INPUT_FILE="$1"
shift

CAMERA="${DEFAULT_CAMERA}"
IMGSIZE="${DEFAULT_IMGSIZE}"
COLORSCHEME="${DEFAULT_COLORSCHEME}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --camera)      CAMERA="$2"; shift 2;;
        --imgsize)     IMGSIZE="$2"; shift 2;;
        --colorscheme) COLORSCHEME="$2"; shift 2;;
        *)             log_error "Unknown option: $1"; usage;;
    esac
done

# Validate input
if [[ ! -f "${INPUT_FILE}" ]]; then
    log_error "File not found: ${INPUT_FILE}"
    exit 1
fi

# Resolve output path: renders/ subdir, same name, .png extension
INPUT_DIR=$(dirname "${INPUT_FILE}")
INPUT_BASE=$(basename "${INPUT_FILE}" .scad)
RENDERS_DIR="${INPUT_DIR}/renders"
mkdir -p "${RENDERS_DIR}"
OUTPUT_FILE="${RENDERS_DIR}/${INPUT_BASE}.png"

# Find OpenSCAD
if ! OPENSCAD_EXE=$(find_openscad_exe); then
    log_error "OpenSCAD not found. Run 'scadm install' first."
    exit 1
fi

LIBRARIES_DIR="${INSTALL_DIR}/libraries"

log_info "Exporting PNG: ${INPUT_FILE} → ${OUTPUT_FILE}"

if OPENSCADPATH="${LIBRARIES_DIR}" "${OPENSCAD_EXE}" \
    -o "${OUTPUT_FILE}" \
    --render \
    --camera="${CAMERA}" \
    --autocenter --viewall \
    --imgsize="${IMGSIZE}" \
    --colorscheme="${COLORSCHEME}" \
    "${INPUT_FILE}" 2>&1; then

    if [[ -f "${OUTPUT_FILE}" ]]; then
        local_size=$(stat -c%s "${OUTPUT_FILE}" 2>/dev/null || stat -f%z "${OUTPUT_FILE}" 2>/dev/null)
        log_success "Exported: ${OUTPUT_FILE} (${local_size} bytes)"
    else
        log_error "Export failed: no output file generated"
        exit 1
    fi
else
    log_error "OpenSCAD export failed"
    exit 1
fi
