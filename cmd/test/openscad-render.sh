#!/usr/bin/env bash
#
# OpenSCAD Renderer - Core Testing Tool
#
# Renders specific .scad files to validate syntax and geometry.
# Use this for:
#   - Testing individual model files during development
#   - Validating exported files (e.g., MakerWorld exports)
#   - Quick smoke tests of specific models
#
# For automated testing of all models in test/ directories, use test-models.sh instead.
#
# Usage:
#   ./cmd/test/openscad-render.sh                 # Run smoke test on wallmount.scad
#   ./cmd/test/openscad-render.sh file1.scad ...  # Test specific files
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INSTALL_DIR="${WORKSPACE_ROOT}/bin/openscad"

# Source common functions (provides detect_platform, find_openscad_exe, logging)
# shellcheck source=../lib/common.sh disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh"

PLATFORM=$(detect_platform)

# Test a single model file
test_model() {
    local model_file="$1"
    local openscad_exe="$2"
    local libraries_dir="$3"
    local output_file
    output_file="/tmp/$(basename "${model_file}" .scad)-test.stl"

    log_info "Testing: ${model_file}"

    # Check if test file exists
    if [[ ! -f "${model_file}" ]]; then
        log_error "Model file not found: ${model_file}"
        return 1
    fi

    # Clean up old test output
    rm -f "${output_file}"

    # Render the test file with OPENSCADPATH set to bundled libraries
    # Use xvfb-run on Linux if available (needed for headless rendering in CI)
    if [[ "${PLATFORM}" == "linux" ]] && command -v xvfb-run &> /dev/null; then
        if OPENSCADPATH="${libraries_dir}" xvfb-run -a "${openscad_exe}" -o "${output_file}" "${model_file}" --export-format=binstl 2>&1 | tee /tmp/openscad-test.log; then
            render_success=true
        else
            render_success=false
        fi
    else
        if OPENSCADPATH="${libraries_dir}" "${openscad_exe}" -o "${output_file}" "${model_file}" --export-format=binstl 2>&1 | tee /tmp/openscad-test.log; then
            render_success=true
        else
            render_success=false
        fi
    fi

    if [[ "${render_success}" == true ]]; then
        # Check if output file was created
        if [[ -f "${output_file}" ]]; then
            local file_size
            file_size=$(stat -c%s "${output_file}" 2>/dev/null || stat -f%z "${output_file}" 2>/dev/null)
            log_success "Test passed! Generated STL: ${file_size} bytes"
            rm -f "${output_file}"
            rm -f /tmp/openscad-test.log
            return 0
        else
            log_error "Test failed: No output file generated"
            cat /tmp/openscad-test.log
            return 1
        fi
    else
        log_error "Test failed: OpenSCAD rendering error"
        cat /tmp/openscad-test.log
        return 1
    fi
}

# Run tests
main() {
    local openscad_exe
    local libraries_dir="${INSTALL_DIR}/libraries"

    log_info "Running OpenSCAD tests..."

    # Find OpenSCAD executable
    if ! openscad_exe=$(find_openscad_exe); then
        log_error "OpenSCAD executable not found. Please install first."
        exit 1
    fi

    # Show OpenSCAD version
    local openscad_version
    openscad_version=$("${openscad_exe}" --version 2>&1 | awk '/OpenSCAD version/ {print $3}')
    log_info "Using OpenSCAD version: ${openscad_version}"
    log_info "Using libraries from: ${libraries_dir}"

    if [[ ! -d "${libraries_dir}" ]]; then
        log_error "Libraries directory not found: ${libraries_dir}"
        exit 1
    fi

    # Test files: either from arguments or default to wallmount
    local test_files=()
    if [[ $# -gt 0 ]]; then
        test_files=("$@")
    else
        test_files=("${WORKSPACE_ROOT}/models/wallmount/parts/wallmount.scad")
    fi

    # Run tests
    local failed=0
    for file in "${test_files[@]}"; do
        if ! test_model "${file}" "${openscad_exe}" "${libraries_dir}"; then
            failed=$((failed + 1))
        fi
        echo ""
    done

    # Report results
    if [[ ${failed} -gt 0 ]]; then
        log_error "${failed} test(s) failed"
        exit 1
    else
        log_success "All tests passed!"
    fi
}

main "$@"
