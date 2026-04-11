"""Flatten OpenSCAD include trees into single files.

Resolves and inlines all local include/use dependencies into a single .scad file.
BOSL2 includes are preserved as-is. Useful for platforms that require single-file
uploads (e.g. MakerWorld Customizer).

Only effectively used modules, functions, and variables from the dependency chain
are included in the output — unused definitions are omitted.
"""

import hashlib
import json
import logging
import re
from pathlib import Path
from typing import Optional, Set

from scadm.installer import get_install_paths, get_workspace_root

logger = logging.getLogger(__name__)

# Pattern matching OpenSCAD Customizer section markers like /* [General] */
_SECTION_MARKER_RE = re.compile(r"/\*\s*\[(.+?)\]\s*\*/")
# Pattern matching include/use statements
_INCLUDE_RE = re.compile(r"^\s*(include|use)\s*<([^>]+)>\s*$", re.MULTILINE)
# Pattern matching module/function definitions (top-level)
_DEF_START_RE = re.compile(r"^(module|function)\s+(\w+)")
# Pattern matching top-level variable assignments (including $-variables)
_VAR_ASSIGN_RE = re.compile(r"^([\$\w]+)\s*=")


# ---------------------------------------------------------------------------
# Include resolution helpers
# ---------------------------------------------------------------------------


def _load_scadm_dependency_names(project_root: Path) -> Set[str]:
    """Load dependency names from scadm.json.

    Args:
        project_root: Repository root containing scadm.json.

    Returns:
        Set of dependency names declared in scadm.json.
    """
    scadm_path = project_root / "scadm.json"
    if not scadm_path.exists():
        return set()

    data = json.loads(scadm_path.read_text(encoding="utf-8"))
    return {
        dep["name"].strip()
        for dep in data.get("dependencies", [])
        if isinstance(dep.get("name"), str) and dep["name"].strip()
    }


def _split_library_include_path(include_path: str) -> Optional[tuple[str, str]]:
    """Split '<LibName>/rest' into ('LibName', 'rest')."""
    if "/" not in include_path:
        return None
    lib, rest = include_path.split("/", 1)
    if not lib or not rest:
        return None
    return lib, rest


def _is_bosl2(path: str) -> bool:
    """Check if an include path references the BOSL2 library."""
    return path.startswith("BOSL2/")


def _resolve_include_path(
    *,
    current_file: Path,
    include_path: str,
    libraries_dir: Path,
    scadm_dep_names: Set[str],
) -> Optional[Path]:
    """Resolve an OpenSCAD include path to an absolute file path.

    Resolution order:
      1. If prefixed with a scadm dependency name -> bin/openscad/libraries/<dep>/...
      2. Otherwise relative to current file.

    Args:
        current_file: File containing the include statement.
        include_path: The path inside <...>.
        libraries_dir: Absolute path to bin/openscad/libraries.
        scadm_dep_names: Dependency names from scadm.json.

    Returns:
        Absolute Path if resolvable, else None.
    """
    split = _split_library_include_path(include_path)
    if split is not None:
        lib_name, lib_rel = split
        if lib_name in scadm_dep_names and not _is_bosl2(include_path):
            return (libraries_dir / lib_name / lib_rel).resolve()

    return (current_file.parent / include_path).resolve()


# ---------------------------------------------------------------------------
# Content parsing helpers
# ---------------------------------------------------------------------------


def _get_includes(content: str) -> list[tuple[str, str]]:
    """Extract all include/use statements as (directive, path) tuples."""
    # e.g. include <BOSL2/std.scad>, use <lib/helper.scad>
    return _INCLUDE_RE.findall(content)


def _strip_comments(content: str) -> str:
    """Remove single-line and multi-line comments from SCAD content.

    Preserves Customizer section markers /* [Name] */ so callers can
    detect and handle them.
    """
    # Temporarily protect section markers
    markers: list[str] = []

    def _protect_marker(m: re.Match) -> str:
        markers.append(m.group(0))
        return f"__SECTION_MARKER_{len(markers) - 1}__"

    content = _SECTION_MARKER_RE.sub(_protect_marker, content)
    # e.g. /* multi\nline */
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)
    # e.g. // this is a comment
    content = re.sub(r"//.*?$", "", content, flags=re.MULTILINE)
    # Restore markers
    for i, marker in enumerate(markers):
        content = content.replace(f"__SECTION_MARKER_{i}__", marker)
    return content


def _extract_parameters(content: str) -> str:
    """Extract parameter sections from root file, stopping at /* [Hidden] */."""
    sections = []
    current_pos = 0

    while True:
        # e.g. /* [General] */, /* [Parameters] */
        match = _SECTION_MARKER_RE.search(content[current_pos:])
        if not match:
            break

        if match.group(1).lower() == "hidden":
            break

        section_start = current_pos + match.start()
        current_pos += match.end()

        # Next section marker or structural keyword
        # e.g. /* [Hidden] */, \nmodule foo(...), \nfunction bar(...)
        next_section = re.search(
            r"/\*\s*\[.+?\]\s*\*/|\n\s*(?:include|use|module|function)\s+",
            content[current_pos:],
        )
        section_end = current_pos + next_section.start() if next_section else len(content)
        sections.append(content[section_start:section_end])

    return "\n".join(sections).strip() if sections else ""


def _extract_hidden_section(content: str) -> str:
    """Extract /* [Hidden] */ section via line-by-line parser.

    Keeps assignments (including $-variables) and stops at the first
    non-assignment statement (module/function/include/use or geometry call).
    """
    lines = content.splitlines()
    hidden_start = None
    for idx, line in enumerate(lines):
        # e.g. /* [Hidden] */
        if re.search(r"/\*\s*\[Hidden\]\s*\*/", line):
            hidden_start = idx
            break

    if hidden_start is None:
        return ""

    kept: list[str] = [lines[hidden_start]]
    in_multiline_assignment = False

    for line in lines[hidden_start + 1 :]:
        stripped = line.strip()

        if in_multiline_assignment:
            kept.append(line)
            if ";" in stripped:
                in_multiline_assignment = False
            continue

        # e.g. include <BOSL2/std.scad>, module foo(), function bar()
        if re.match(r"^(include|use|module|function)\b", stripped):
            break

        if not stripped or stripped.startswith("//"):
            kept.append(line)
            continue

        # e.g. $fn = 100;, EPSILON = 0.01;, BASE_UNIT =\n    15;
        if _VAR_ASSIGN_RE.match(stripped):
            kept.append(line)
            if ";" not in stripped:
                in_multiline_assignment = True
            continue

        break

    return "\n".join(kept).strip()


# ---------------------------------------------------------------------------
# Parsed definition types for dependency analysis
# ---------------------------------------------------------------------------


class _Definition:
    """A single variable, module, or function definition extracted from SCAD content."""

    __slots__ = ("kind", "name", "lines", "origin")

    def __init__(self, kind: str, name: str, lines: list[str], origin: str = ""):
        self.kind = kind  # "variable", "module", or "function"
        self.name = name
        self.lines = lines  # original source lines
        self.origin = origin  # source file label for origin comments


def _parse_definitions(content: str, origin: str = "") -> list[_Definition]:
    """Parse all top-level definitions (modules, functions, variables) from SCAD content.

    Args:
        content: SCAD source with comments stripped.
        origin: Label for the source file (used in origin comments).

    Returns:
        List of _Definition objects in source order.
    """
    # Strip includes and section markers before parsing
    clean = re.sub(r"^\s*(include|use)\s*<[^>]+>\s*$", "", content, flags=re.MULTILINE)
    clean = _SECTION_MARKER_RE.sub("", clean)

    lines = clean.split("\n")
    defs: list[_Definition] = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()

        # Module or function definition
        m = _DEF_START_RE.match(stripped)
        if m:
            kind = m.group(1)
            name = m.group(2)
            def_lines = [lines[i]]
            brace_count = lines[i].count("{") - lines[i].count("}")
            seen_brace = "{" in lines[i]

            # Function definitions: single-expression functions end with ;
            if kind == "function" and not seen_brace:
                # Collect until ; for single-expression functions
                while i + 1 < len(lines) and ";" not in lines[i]:
                    i += 1
                    def_lines.append(lines[i])
                defs.append(_Definition(kind, name, def_lines, origin))
                i += 1
                continue

            # Module/function with braces
            while seen_brace and brace_count > 0 and i + 1 < len(lines):
                i += 1
                def_lines.append(lines[i])
                brace_count += lines[i].count("{") - lines[i].count("}")
                if "{" in lines[i]:
                    seen_brace = True
            if not seen_brace:
                # Multi-line signature before opening brace
                while i + 1 < len(lines):
                    i += 1
                    def_lines.append(lines[i])
                    if "{" in lines[i]:
                        seen_brace = True
                        brace_count += lines[i].count("{") - lines[i].count("}")
                        break
                while seen_brace and brace_count > 0 and i + 1 < len(lines):
                    i += 1
                    def_lines.append(lines[i])
                    brace_count += lines[i].count("{") - lines[i].count("}")

            defs.append(_Definition(kind, name, def_lines, origin))
            i += 1
            continue

        # Top-level variable assignment (not inside a module/function)
        vm = _VAR_ASSIGN_RE.match(stripped)
        if vm and stripped:
            name = vm.group(1)
            var_lines = [lines[i]]
            if ";" not in stripped:
                while i + 1 < len(lines) and ";" not in lines[i]:
                    i += 1
                    var_lines.append(lines[i])
            defs.append(_Definition("variable", name, var_lines, origin))
            i += 1
            continue

        i += 1

    return defs


def _find_used_names(text: str) -> Set[str]:
    """Find all identifier-like names used in a piece of SCAD text."""
    return set(re.findall(r"\b([A-Za-z_]\w*)\b", text))


def _resolve_dependencies(
    needed: Set[str],
    all_defs: list[_Definition],
) -> list[_Definition]:
    """Resolve the transitive closure of definitions needed by *needed* names.

    Starting from the set of names used in the root file's main code and
    parameter/hidden sections, walks the dependency graph of all collected
    definitions and returns only those that are transitively required.

    Args:
        needed: Initial set of identifier names to resolve.
        all_defs: All available definitions from library files.

    Returns:
        Ordered list of definitions that are transitively required.
    """
    by_name: dict[str, _Definition] = {}
    for d in all_defs:
        if d.name not in by_name:
            by_name[d.name] = d

    resolved_names: Set[str] = set()
    queue = list(needed)
    while queue:
        name = queue.pop()
        if name in resolved_names:
            continue
        resolved_names.add(name)
        if name in by_name:
            body = "\n".join(by_name[name].lines)
            for ref in _find_used_names(body):
                if ref not in resolved_names:
                    queue.append(ref)

    # Return in original source order, only those resolved
    return [d for d in all_defs if d.name in resolved_names]


def _extract_main_code(content: str) -> str:
    """Extract main code after parameter/hidden sections.

    Skips leading standalone assignments (already emitted via hidden section)
    but preserves assignments inside modules/calls (keyword args etc.).
    Comments within the main code body are preserved.
    """
    # Find last section marker on original content (markers are /* [Name] */ block comments)
    # e.g. /* [General] */, /* [Hidden] */
    last_section = None
    for match in _SECTION_MARKER_RE.finditer(content):
        last_section = match
    if last_section:
        content = content[last_section.end() :]

    # e.g. include <BOSL2/std.scad>, use <lib/helper.scad>
    content = re.sub(r"^\s*(include|use)\s*<[^>]+>\s*$", "", content, flags=re.MULTILINE)

    lines = content.split("\n")
    result: list[str] = []
    skipping_leading = True
    in_multiline_assignment = False

    for line in lines:
        stripped = line.strip()
        if skipping_leading:
            if in_multiline_assignment:
                if ";" in stripped:
                    in_multiline_assignment = False
                continue
            if not stripped:
                continue
            # e.g. $fn = 100;  or  BASE_UNIT=15; // mm
            if re.match(r"^[\$\w]+\s*=.*;\s*(//.*)?$", stripped):
                continue
            # e.g. pusher_length =\n    BASE_UNIT + BASE_STRENGTH * 2 + TOLERANCE;
            if _VAR_ASSIGN_RE.match(stripped) and ";" not in stripped:
                in_multiline_assignment = True
                continue
            # e.g. // Debug, // Example usage
            if stripped.startswith("//"):
                continue
            skipping_leading = False
        result.append(line)

    return "\n".join(result).strip()


# ---------------------------------------------------------------------------
# Recursive file processing (collects definitions for dependency analysis)
# ---------------------------------------------------------------------------


def _collect_all_definitions(
    file_path: Path,
    processed: Set[Path],
    bosl2_includes: Set[str],
    all_defs: list[_Definition],
    *,
    libraries_dir: Path,
    scadm_dep_names: Set[str],
) -> None:
    """Recursively collect definitions from a library file and its includes.

    Section markers in library files are silently ignored (no error raised).

    Args:
        file_path: Absolute path to library file.
        processed: Set of already-processed files (prevents duplicates).
        bosl2_includes: Accumulator for BOSL2 include statements.
        all_defs: Accumulator for parsed definitions.
        libraries_dir: Absolute path to bin/openscad/libraries.
        scadm_dep_names: Dependency names from scadm.json.
    """
    if file_path in processed:
        return

    processed.add(file_path)
    content = file_path.read_text(encoding="utf-8")

    # Section markers in library files are silently ignored
    if _SECTION_MARKER_RE.search(content):
        logger.debug("Ignoring section markers in library file: %s", file_path)

    # Process includes first (depth-first) so dependencies appear before dependents
    for directive, path in _get_includes(content):
        if _is_bosl2(path):
            bosl2_includes.add(f"{directive} <{path}>")
        else:
            resolved = _resolve_include_path(
                current_file=file_path,
                include_path=path,
                libraries_dir=libraries_dir,
                scadm_dep_names=scadm_dep_names,
            )
            if resolved is not None and resolved.exists():
                _collect_all_definitions(
                    resolved,
                    processed,
                    bosl2_includes,
                    all_defs,
                    libraries_dir=libraries_dir,
                    scadm_dep_names=scadm_dep_names,
                )

    clean_content = _strip_comments(content)
    origin = file_path.name
    defs = _parse_definitions(clean_content, origin=origin)
    all_defs.extend(defs)


# ---------------------------------------------------------------------------
# Checksum
# ---------------------------------------------------------------------------


def _collect_local_deps(
    file_path: Path,
    visited: Set[Path],
    *,
    libraries_dir: Path,
    scadm_dep_names: Set[str],
) -> Set[Path]:
    """Recursively collect all local (non-BOSL2) include dependencies."""
    if file_path in visited or not file_path.exists():
        return set()

    visited.add(file_path)
    deps = {file_path}

    content = file_path.read_text(encoding="utf-8")
    for _, path in _get_includes(content):
        if not _is_bosl2(path):
            resolved = _resolve_include_path(
                current_file=file_path,
                include_path=path,
                libraries_dir=libraries_dir,
                scadm_dep_names=scadm_dep_names,
            )
            if resolved is not None:
                deps |= _collect_local_deps(
                    resolved, visited, libraries_dir=libraries_dir, scadm_dep_names=scadm_dep_names
                )

    return deps


def compute_checksum(input_file: Path, workspace_root: Optional[Path] = None) -> str:
    """Compute SHA256 checksum of all transitive local dependencies.

    Args:
        input_file: Absolute path to root .scad file.
        workspace_root: Project root (auto-detected if None).

    Returns:
        Hex SHA256 digest.
    """
    if workspace_root is None:
        workspace_root = get_workspace_root(input_file.parent)

    _, libraries_dir = get_install_paths(workspace_root)
    scadm_dep_names = _load_scadm_dependency_names(workspace_root)

    deps = _collect_local_deps(
        input_file.resolve(),
        set(),
        libraries_dir=libraries_dir,
        scadm_dep_names=scadm_dep_names,
    )
    resolved_root = workspace_root.resolve()

    # Filter out any deps that resolved outside the workspace (shouldn't
    # happen, but avoids a ValueError from relative_to).
    workspace_deps = {d for d in deps if d.is_relative_to(resolved_root)}

    # Hash flatten.py first (always at a fixed position) so its install
    # location (.venv inside workspace on Windows vs system site-packages
    # on Linux CI) never affects the sort order of other dependencies.
    hasher = hashlib.sha256()
    hasher.update(Path(__file__).resolve().read_bytes())

    for dep in sorted(workspace_deps, key=lambda d: d.relative_to(resolved_root).as_posix()):
        hasher.update(dep.read_bytes())
    return hasher.hexdigest()


# ---------------------------------------------------------------------------
# Main flatten operation
# ---------------------------------------------------------------------------


def flatten_file(
    input_file: Path, output_file: Path, workspace_root: Optional[Path] = None
) -> None:
    """Flatten a .scad file by inlining only effectively used dependencies.

    Produces a single-file output with structure:
      BOSL2 includes -> Parameters -> /* [Hidden] */ (used lib defs + root hidden) -> Main code

    Section markers in library files are silently ignored (only root file
    sections matter). Variables from library files land in the Hidden section
    with an origin comment.

    Args:
        input_file: Absolute path to root .scad file.
        output_file: Absolute path for flattened output.
        workspace_root: Project root (auto-detected if None).
    """
    if workspace_root is None:
        workspace_root = get_workspace_root(input_file.parent)

    _, libraries_dir = get_install_paths(workspace_root)
    scadm_dep_names = _load_scadm_dependency_names(workspace_root)

    if scadm_dep_names and not libraries_dir.exists():
        raise FileNotFoundError(
            f"scadm libraries directory not found. Run `scadm install` first. Expected: {libraries_dir}"
        )

    root_content = input_file.read_text(encoding="utf-8")
    params = _extract_parameters(root_content)
    hidden = _extract_hidden_section(root_content)
    main_code = _extract_main_code(root_content)

    # Collect all definitions from library dependency chain
    processed: Set[Path] = {input_file}
    bosl2_includes: Set[str] = set()
    all_lib_defs: list[_Definition] = []

    for directive, path in _get_includes(root_content):
        if _is_bosl2(path):
            bosl2_includes.add(f"{directive} <{path}>")
        else:
            resolved = _resolve_include_path(
                current_file=input_file,
                include_path=path,
                libraries_dir=libraries_dir,
                scadm_dep_names=scadm_dep_names,
            )
            if resolved is not None and resolved.exists():
                _collect_all_definitions(
                    resolved,
                    processed,
                    bosl2_includes,
                    all_lib_defs,
                    libraries_dir=libraries_dir,
                    scadm_dep_names=scadm_dep_names,
                )

    # Determine which definitions are actually needed
    needed_names: Set[str] = set()
    needed_names |= _find_used_names(params)
    needed_names |= _find_used_names(hidden)
    needed_names |= _find_used_names(main_code)
    # Also include names from root hidden/main that are defined as root variables
    # (they may reference lib constants)
    hidden_content_raw = re.sub(r"/\*\s*\[Hidden\]\s*\*/", "", hidden).strip() if hidden else ""
    needed_names |= _find_used_names(hidden_content_raw)

    used_defs = _resolve_dependencies(needed_names, all_lib_defs)

    # Separate into variables and modules/functions, preserving order
    lib_vars: list[_Definition] = []
    lib_code: list[_Definition] = []
    for d in used_defs:
        if d.kind == "variable":
            lib_vars.append(d)
        else:
            lib_code.append(d)

    # Assemble output
    output_parts: list[str] = []

    if bosl2_includes:
        output_parts.extend(sorted(bosl2_includes))
        output_parts.append("")

    if params:
        output_parts.append(params.strip())
        output_parts.append("")

    output_parts.append("/* [Hidden] */")

    # Library variables (with origin comments), grouped by origin
    if lib_vars:
        current_origin = None
        var_lines: list[str] = []
        for d in lib_vars:
            if d.origin and d.origin != current_origin:
                var_lines.append(f"// --- from {d.origin} ---")
                current_origin = d.origin
            var_lines.extend(d.lines)
        output_parts.append("\n".join(var_lines))

    # Root hidden variables
    if hidden:
        hc = re.sub(r"/\*\s*\[Hidden\]\s*\*/", "", hidden).strip()
        if hc:
            output_parts.append(hc)

    # Library modules/functions
    if lib_code:
        code_lines: list[str] = []
        for d in lib_code:
            code_lines.extend(d.lines)
        output_parts.append("\n".join(code_lines))

    output_parts.append("")
    output_parts.append(main_code)

    output_text = "\n".join(output_parts)
    output_text = "\n".join(line.rstrip() for line in output_text.split("\n"))
    # Collapse 3+ consecutive blank lines to a single blank line
    output_text = re.sub(r"\n{3,}", "\n\n", output_text)
    if not output_text.endswith("\n"):
        output_text += "\n"

    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(output_text, encoding="utf-8", newline="\n")
    logger.info("Flattened: %s -> %s", input_file, output_file)


# ---------------------------------------------------------------------------
# Batch flatten (reads "flatten" key from scadm.json)
# ---------------------------------------------------------------------------


def load_flatten_config(workspace_root: Path) -> list[dict]:
    """Load flatten config entries from scadm.json.

    Args:
        workspace_root: Project root containing scadm.json.

    Returns:
        List of {"src": "...", "dest": "..."} dicts.

    Raises:
        FileNotFoundError: If scadm.json not found.
        ValueError: If JSON is malformed, no flatten config, or entries are invalid.
    """
    scadm_path = workspace_root / "scadm.json"
    if not scadm_path.exists():
        raise FileNotFoundError(f"scadm.json not found at {workspace_root}")

    try:
        data = json.loads(scadm_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON in {scadm_path}: {e}") from e

    entries = data.get("flatten", [])
    if not entries:
        raise ValueError('No "flatten" entries in scadm.json. Add a "flatten" key with src/dest pairs.')

    for i, entry in enumerate(entries):
        if not isinstance(entry, dict) or not entry.get("src") or not entry.get("dest"):
            raise ValueError(
                f'Invalid flatten entry at index {i} in scadm.json: expected {{"src": "...", "dest": "..."}}'
            )

    return entries


def discover_scad_files(src_dir: Path, dest_dir: Path) -> list[Path]:
    """Discover .scad files in src_dir, excluding dest_dir subtree."""
    files = []
    for scad in sorted(src_dir.rglob("*.scad")):
        try:
            scad.relative_to(dest_dir)
        except ValueError:
            files.append(scad)
    return files


def _resolve_output_path(input_file: Path, src_dir: Path, dest_dir: Path) -> Path:
    """Map an input file under src_dir to its output path under dest_dir."""
    rel = input_file.relative_to(src_dir)
    return dest_dir / rel


def flatten_all(
    workspace_root: Optional[Path] = None,
    checksums_file: Optional[Path] = None,
) -> bool:
    """Batch-flatten all files configured in scadm.json.

    Args:
        workspace_root: Project root (auto-detected if None).
        checksums_file: Path to checksums file for caching. Defaults to
            <workspace_root>/models/.flatten-checksums.

    Returns:
        True if all files flattened successfully.
    """
    if workspace_root is None:
        workspace_root = get_workspace_root()

    if checksums_file is None:
        checksums_file = workspace_root / "models" / ".flatten-checksums"

    entries = load_flatten_config(workspace_root)

    # Load existing checksums
    stored: dict[str, str] = {}
    if checksums_file.exists():
        for line in checksums_file.read_text(encoding="utf-8").splitlines():
            parts = line.split(None, 1)
            if len(parts) == 2:
                stored[parts[1]] = parts[0]

    all_files: list[tuple[Path, Path]] = []
    for entry in entries:
        src_dir = (workspace_root / entry["src"]).resolve()
        dest_dir = (workspace_root / entry["dest"]).resolve()
        if not src_dir.is_dir():
            logger.error("Source directory not found: %s", src_dir)
            return False
        for scad in discover_scad_files(src_dir, dest_dir):
            all_files.append((scad, _resolve_output_path(scad, src_dir, dest_dir)))

    if not all_files:
        logger.error("No .scad files found to flatten")
        return False

    logger.info("Found %d file(s) to flatten", len(all_files))

    failed = 0
    skipped = 0
    flattened = 0
    new_checksums: list[str] = []

    for input_file, output_file in all_files:
        rel_path = input_file.relative_to(workspace_root).as_posix()
        current_checksum = compute_checksum(input_file, workspace_root)

        if stored.get(rel_path) == current_checksum:
            logger.info("Skipping (unchanged): %s", rel_path)
            skipped += 1
            new_checksums.append(f"{current_checksum}  {rel_path}")
            continue

        try:
            flatten_file(input_file, output_file, workspace_root)
            flattened += 1
            new_checksums.append(f"{current_checksum}  {rel_path}")
        except (ValueError, FileNotFoundError) as exc:
            logger.error("Failed to flatten %s: %s", rel_path, exc)
            failed += 1

    # Write checksums
    checksums_file.parent.mkdir(parents=True, exist_ok=True)
    checksums_file.write_text(
        "\n".join(sorted(new_checksums, key=lambda l: l.split(None, 1)[1])) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    logger.info("Summary: %d skipped, %d flattened, %d failed", skipped, flattened, failed)
    return failed == 0
