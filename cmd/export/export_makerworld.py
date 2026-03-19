#!/usr/bin/env python3
"""
Export OpenSCAD files for MakerWorld by inlining local includes.

MakerWorld's parametric model feature doesn't support multiple files.
This script merges all local includes into a single file while preserving
BOSL2 library references and the root file's parameters.
"""

import hashlib
import re
import sys
from pathlib import Path
from typing import Set


def strip_comments(content: str) -> str:
    """Remove single-line and multi-line comments from SCAD content.

    Called on library file content to remove all comments before inlining,
    preventing comment clutter in exported files.

    Args:
        content: OpenSCAD source code as string

    Returns:
        Source code with all comments removed
    """
    # Remove multi-line comments: /* anything */
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)
    # Remove single-line comments: // anything until end of line
    content = re.sub(r"//.*?$", "", content, flags=re.MULTILINE)
    return content


def extract_parameters(content: str) -> str:
    """Extract all parameter sections from root file, excluding Hidden section.

    Extracts all parameter sections from root file for the Customizer UI.
    Stops at /* [Hidden] */ to separate user-facing parameters from internal constants.

    Args:
        content: OpenSCAD source code from root file

    Returns:
        All parameter sections (/* [Name] */) concatenated as string, or empty string if none
    """
    # Find all parameter section markers
    sections = []
    current_pos = 0

    while True:
        # Match parameter section markers: /* [SectionName] */
        match = re.search(r"/\*\s*\[(.+?)\]\s*\*/", content[current_pos:])
        if not match:
            break

        section_name = match.group(1)
        # Skip the Hidden section
        if section_name.lower() == "hidden":
            break

        section_start = current_pos + match.start()
        current_pos += match.end()

        # Find where this section ends (next section or code starts)
        # Match: /* [Name] */ OR newline followed by include/use/module/function
        next_section = re.search(r"/\*\s*\[.+?\]\s*\*/|\n\s*(?:include|use|module|function)\s+", content[current_pos:])
        if next_section:
            section_end = current_pos + next_section.start()
        else:
            section_end = len(content)

        sections.append(content[section_start:section_end])

    return "\n".join(sections).strip() if sections else ""


def extract_hidden_section(content: str) -> str:
    """Extract hidden section content from root file (if it exists).

    Extracts the /* [Hidden] */ section from root file. This section contains
    constants and variables that shouldn't appear in the Customizer UI.

    Args:
        content: OpenSCAD source code from root file

    Returns:
        Hidden section with marker and content, or empty string if not found
    """
    # Match: /* [Hidden] */ followed by content until include/use/module/function/$
    match = re.search(r"/\*\s*\[Hidden\]\s*\*/.*?(?=\n(?:include|use|module|function|\$))", content, re.DOTALL)
    return match.group(0) if match else ""


def get_includes(content: str) -> list:
    """Extract all include/use statements with their paths.

    Parses all include/use statements to determine which files need to be processed.

    Args:
        content: OpenSCAD source code

    Returns:
        List of tuples: [(directive, path), ...] e.g., [('include', 'lib/foo.scad'), ...]
    """
    # Match: include <path> or use <path> (start to end of line)
    pattern = r"^\s*(include|use)\s*<([^>]+)>\s*$"
    return re.findall(pattern, content, re.MULTILINE)


def is_bosl2(path: str) -> bool:
    """Check if path references BOSL2 library.

    Determines if an include path references the BOSL2 library.
    BOSL2 includes must be preserved (not inlined) since MakerWorld provides them.

    Args:
        path: Include path from include/use statement

    Returns:
        True if path starts with 'BOSL2/', False otherwise
    """
    return path.startswith("BOSL2/")


def resolve_path(current_file: Path, include_path: str) -> Path:
    """Resolve relative include path from current file location.

    Resolves relative include paths to absolute paths, needed to locate library files for inlining.

    Args:
        current_file: Absolute path to file containing the include statement
        include_path: Relative path from include/use statement

    Returns:
        Absolute resolved path to the included file
    """
    return (current_file.parent / include_path).resolve()


def collect_local_deps(file_path: Path, visited: Set[Path]) -> Set[Path]:
    """Recursively collect all local (non-BOSL2) include dependencies.

    Walks the include/use tree starting from file_path, collecting all local
    files that contribute to the export output.

    Args:
        file_path: Absolute path to starting file
        visited: Set of already-visited files to prevent cycles

    Returns:
        Set of absolute paths to all local dependencies (including file_path itself)
    """
    if file_path in visited or not file_path.exists():
        return set()

    visited.add(file_path)
    deps = {file_path}

    content = file_path.read_text(encoding="utf-8")
    for _, path in get_includes(content):
        if not is_bosl2(path):
            resolved = resolve_path(file_path, path)
            deps |= collect_local_deps(resolved, visited)

    return deps


def compute_checksum(input_file: Path, script_file: Path) -> str:
    """Compute SHA256 checksum of all transitive local dependencies.

    Hashes the input file, all its local includes (recursively), and the
    export script itself. Used for cache invalidation.

    Args:
        input_file: Absolute path to root .scad file
        script_file: Absolute path to this export script

    Returns:
        Hex SHA256 digest of combined file contents
    """
    deps = collect_local_deps(input_file, set())
    deps.add(script_file)

    hasher = hashlib.sha256()
    for dep in sorted(deps):
        hasher.update(dep.read_bytes())
    return hasher.hexdigest()


def has_parameter_section(content: str) -> bool:
    """Check if content has any parameter section marker /* [Name] */.

    Validates that library files don't contain parameter sections.
    Library files should only have definitions, not Customizer parameters.

    Args:
        content: OpenSCAD source code to validate

    Returns:
        True if any parameter section markers found, False otherwise
    """
    # Match: /* [anything] */
    return bool(re.search(r"/\*\s*\[.+?\]\s*\*/", content))


def extract_definitions(content: str) -> str:
    """Extract module/function definitions and top-level variables.

    Extracts module/function definitions and top-level variables from library files.
    Used to inline library content while preserving all necessary code.

    Args:
        content: OpenSCAD source code from library file

    Returns:
        Extracted definitions and variables as string, excluding include statements and comments
    """
    lines = content.split("\n")
    result = []
    in_definition = False  # True when inside a module/function definition (between braces)
    in_variable = False  # True when inside a multi-line variable assignment (until semicolon)
    brace_count = 0  # Tracks nesting depth of braces to detect end of module/function

    for line in lines:
        stripped = line.strip()

        # Start of module or function: module name or function name
        if re.match(r"^(module|function)\s+\w+", stripped):
            in_definition = True

        # Top-level variable assignment (start): varname = ...
        if not in_definition and not in_variable and re.match(r"^\w+\s*=", stripped):
            in_variable = True
            result.append(line)
            # Check if assignment ends on same line
            if ";" in stripped:
                in_variable = False
            continue

        # Continue multi-line variable assignment
        if in_variable:
            result.append(line)
            if ";" in stripped:
                in_variable = False
            continue

        if in_definition:
            result.append(line)
            brace_count += line.count("{") - line.count("}")
            if brace_count == 0 and "{" in line:
                in_definition = False

    return "\n".join(result)


def process_file(file_path: Path, processed: Set[Path], bosl2_includes: Set[str]) -> str:
    """Recursively process a library file and inline its local includes.

    Processes library files only (not root files). Validates that library files
    don't contain parameter sections, then extracts and inlines their content.

    Args:
        file_path: Absolute path to library file being processed
        processed: Set of already-processed files to prevent duplicates
        bosl2_includes: Set to accumulate BOSL2 include statements

    Returns:
        Cleaned and inlined content from library file

    Raises:
        ValueError: If library file contains parameter section markers
    """
    if file_path in processed:
        return ""

    processed.add(file_path)
    content = file_path.read_text(encoding="utf-8")

    # Validate: library files must NOT have parameter sections
    if has_parameter_section(content):
        raise ValueError(
            f"Library file contains parameter section: {file_path}\n"
            f"Library files should not have /* [SectionName] */ markers.\n"
            f"(Re)move them and re-run the export!"
        )

    result = []

    for directive, path in get_includes(content):
        if is_bosl2(path):
            bosl2_includes.add(f"{directive} <{path}>")
        else:
            resolved = resolve_path(file_path, path)
            if resolved.exists():
                inlined = process_file(resolved, processed, bosl2_includes)
                if inlined:
                    result.append(inlined)

    # Strip comments, then extract only definitions
    clean_content = strip_comments(content)
    clean_content = extract_definitions(clean_content)
    # Remove: include <path> or use <path> lines
    clean_content = re.sub(r"^\s*(include|use)\s*<[^>]+>\s*$", "", clean_content, flags=re.MULTILINE)
    # Remove excessive blank lines: 3+ consecutive newlines → 2 newlines
    clean_content = re.sub(r"\n\s*\n\s*\n+", "\n\n", clean_content)
    clean_content = clean_content.strip()

    if clean_content:
        result.append(clean_content)
    return "\n\n".join(result)


def extract_main_code(content: str) -> str:
    """Extract main code (after parameters/hidden sections), excluding variable assignments.

    Extracts the main code section from root file (after all parameter sections).
    Filters out variable assignments to keep only geometry-generating calls.

    Args:
        content: OpenSCAD source code from root file

    Returns:
        Main code section containing only module/function calls, not variable assignments
    """
    # First strip all comments
    content = strip_comments(content)
    # Remove everything before the main code starts (all parameter sections)
    # Find last parameter section marker: /* [anything] */
    last_section = None
    for match in re.finditer(r"/\*\s*\[.+?\]\s*\*/", content):
        last_section = match

    if last_section:
        # Start from after the last parameter section
        content = content[last_section.end() :]

    # Remove include statements: include <path> or use <path>
    content = re.sub(r"^\s*(include|use)\s*<[^>]+>\s*$", "", content, flags=re.MULTILINE)

    # Filter out variable assignments, keep only function/module calls and other statements
    lines = content.split("\n")
    result = []
    for line in lines:
        stripped = line.strip()
        # Skip empty lines and variable assignments: varname = value;
        if not stripped or re.match(r"^\w+\s*=.*;\s*$", stripped):
            continue
        result.append(line)

    return "\n".join(result).strip()


def export_for_makerworld(input_file: Path, output_file: Path):
    """Export SCAD file with inlined includes for MakerWorld.

    Main orchestrator that processes input file and generates MakerWorld-compatible output.
    Assembles final file with structure: BOSL2 includes → Parameters → Hidden → Main code.

    Args:
        input_file: Absolute path to root .scad file to export
        output_file: Absolute path where exported file will be written

    Returns:
        None (writes to output_file and prints confirmation message)
    """
    processed: Set[Path] = set()
    bosl2_includes: Set[str] = set()

    root_content = input_file.read_text(encoding="utf-8")
    params = extract_parameters(root_content)
    hidden = extract_hidden_section(root_content)
    main_code = extract_main_code(root_content)

    # Process includes (mark root as processed to avoid re-processing)
    processed.add(input_file)
    inlined_libs = []
    for directive, path in get_includes(root_content):
        if is_bosl2(path):
            bosl2_includes.add(f"{directive} <{path}>")
        else:
            resolved = resolve_path(input_file, path)
            if resolved.exists():
                lib_content = process_file(resolved, processed, bosl2_includes)
                if lib_content:
                    inlined_libs.append(lib_content)

    # Build final output
    output_parts = []

    # BOSL2 includes at top
    if bosl2_includes:
        output_parts.extend(sorted(bosl2_includes))
        output_parts.append("")

    # Parameters section
    if params:
        output_parts.append(params.strip())
        output_parts.append("")

    # Hidden section with inlined library constants
    output_parts.append("/* [Hidden] */")
    if hidden:
        # Extract just the content after /* [Hidden] */, removing the marker: /* [Hidden] */
        hidden_content = re.sub(r"/\*\s*\[Hidden\]\s*\*/", "", hidden).strip()
        if hidden_content:
            output_parts.append(hidden_content)

    # Add inlined library content to hidden section
    if inlined_libs:
        output_parts.append("\n\n".join(inlined_libs))

    output_parts.append("")

    # Main code from root file
    output_parts.append(main_code)

    # Build final output with proper line endings
    output_text = "\n".join(output_parts)
    # Strip trailing whitespace from each line
    output_text = "\n".join(line.rstrip() for line in output_text.split("\n"))
    # Ensure file ends with exactly one newline (LF)
    if not output_text.endswith("\n"):
        output_text += "\n"

    # Write with LF line endings (newline='\n' prevents Windows CRLF conversion)
    output_file.write_text(output_text, encoding="utf-8", newline="\n")
    print(f"Exported: {output_file}")


if __name__ == "__main__":
    checksum_mode = "--checksum" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--checksum"]

    if len(args) != 1:
        print(f"Usage: {sys.argv[0]} [--checksum] <input.scad>")
        sys.exit(1)

    input_path = Path(args[0])
    if not input_path.exists():
        print(f"Error: {input_path} not found")
        sys.exit(1)

    script_path = Path(__file__).resolve()

    if checksum_mode:
        print(compute_checksum(input_path.resolve(), script_path))
        sys.exit(0)

    # Output to models/<model_type>/makerworld/
    project_root = input_path
    while project_root.parent != project_root and not (project_root / "models").exists():
        project_root = project_root.parent

    # Auto-detect model type from input path (e.g., models/core/parts -> core)
    models_dir = project_root / "models"
    relative_path = input_path.relative_to(models_dir)
    model_type = relative_path.parts[0]  # First component is model type (core, gridfinity, etc.)

    output_path = models_dir / model_type / "makerworld" / input_path.name
    output_path.parent.mkdir(parents=True, exist_ok=True)

    export_for_makerworld(input_path, output_path)
