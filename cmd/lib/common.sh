#!/usr/bin/env bash
#
# HomeRacker Common Shell Functions
#
# Shared utilities for installation scripts.
# Usage: source "${SCRIPT_DIR}/lib/common.sh"
#
# Requires WORKSPACE_ROOT and INSTALL_DIR to be set before sourcing.
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

# Platform detection
detect_platform() {
    case "$(uname -s)" in
        Linux*|Darwin*)       echo "linux";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)                    echo "unknown";;
    esac
}

# Find OpenSCAD executable in INSTALL_DIR
find_openscad_exe() {
    local platform
    platform=$(detect_platform)
    if [[ "${platform}" == "windows" ]]; then
        [[ -f "${INSTALL_DIR}/openscad.com" ]] && echo "${INSTALL_DIR}/openscad.com" && return 0
        [[ -f "${INSTALL_DIR}/openscad.exe" ]] && echo "${INSTALL_DIR}/openscad.exe" && return 0
    elif [[ "${platform}" == "macos" ]]; then
        [[ -f "${INSTALL_DIR}/openscad" ]] && echo "${INSTALL_DIR}/openscad" && return 0
        [[ -f "${INSTALL_DIR}/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]] && echo "${INSTALL_DIR}/OpenSCAD.app/Contents/MacOS/OpenSCAD" && return 0
    else
        [[ -f "${INSTALL_DIR}/openscad" ]] && echo "${INSTALL_DIR}/openscad" && return 0
        [[ -f "${INSTALL_DIR}/OpenSCAD.AppImage" ]] && echo "${INSTALL_DIR}/OpenSCAD.AppImage" && return 0
    fi
    return 1
}

# Version file helpers
save_version() {
    local version_file="$1"
    local version="$2"
    echo "${version}" > "${version_file}"
}

get_version() {
    local version_file="$1"
    if [[ -f "${version_file}" ]]; then
        cat "${version_file}"
    else
        echo "none"
    fi
}

# Download helper
download_file() {
    local url="$1"
    local output="$2"

    if ! curl -L -f -o "${output}" "${url}"; then
        log_error "Failed to download from ${url}"
        return 1
    fi
    return 0
}
