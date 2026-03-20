"""Flatten OpenSCAD include trees into single files.

Resolves and inlines all local include/use dependencies into a single .scad file.
BOSL2 includes are preserved as-is. Useful for platforms that require single-file
uploads (e.g. MakerWorld Customizer).
"""

import hashlib
import json
import logging
import re
from pathlib import Path
from typing import Optional, Set

from scadm.installer import get_install_paths, get_workspace_root

logger = logging.getLogger(__name__)


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
    return re.findall(r"^\s*(include|use)\s*<([^>]+)>\s*$", content, re.MULTILINE)


def _strip_comments(content: str) -> str:
    """Remove single-line and multi-line comments from SCAD content."""
    # e.g. /* multi\nline */, /* [Hidden] */
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)
    # e.g. // this is a comment
    content = re.sub(r"//.*?$", "", content, flags=re.MULTILINE)
    return content


def _has_parameter_section(content: str) -> bool:
    """Check if content has any parameter section marker /* [Name] */."""
    # e.g. /* [General] */, /* [Hidden] */
    return bool(re.search(r"/\*\s*\[.+?\]\s*\*/", content))


def _extract_parameters(content: str) -> str:
    """Extract parameter sections from root file, stopping at /* [Hidden] */."""
    sections = []
    current_pos = 0

    while True:
        # e.g. /* [General] */, /* [Parameters] */
        match = re.search(r"/\*\s*\[(.+?)\]\s*\*/", content[current_pos:])
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
        if re.match(r"^[\$\w]+\s*=", stripped):
            kept.append(line)
            if ";" not in stripped:
                in_multiline_assignment = True
            continue

        break

    return "\n".join(kept).strip()


def _extract_definitions(content: str) -> str:
    """Extract module/function definitions and top-level variables from library content."""
    lines = content.split("\n")
    result = []
    in_definition = False
    in_variable = False
    brace_count = 0
    seen_brace = False

    for line in lines:
        stripped = line.strip()

        # e.g. module connector(...), function get_color(...)
        if re.match(r"^(module|function)\s+\w+", stripped):
            in_definition = True
            seen_brace = False

        # e.g. HR_YELLOW = [1,1,0];, BASE_UNIT = 15;
        if not in_definition and not in_variable and re.match(r"^\w+\s*=", stripped):
            in_variable = True
            result.append(line)
            if ";" in stripped:
                in_variable = False
            continue

        if in_variable:
            result.append(line)
            if ";" in stripped:
                in_variable = False
            continue

        if in_definition:
            result.append(line)
            brace_count += line.count("{") - line.count("}")
            if "{" in line:
                seen_brace = True
            if seen_brace and brace_count == 0:
                in_definition = False

    return "\n".join(result)


def _extract_main_code(content: str) -> str:
    """Extract main code after parameter/hidden sections.

    Skips leading standalone assignments (already emitted via hidden section)
    but preserves assignments inside modules/calls (keyword args etc.).
    Comments within the main code body are preserved.
    """
    # Find last section marker on original content (markers are /* [Name] */ block comments)
    # e.g. /* [General] */, /* [Hidden] */
    last_section = None
    for match in re.finditer(r"/\*\s*\[.+?\]\s*\*/", content):
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
            if re.match(r"^[\$\w]+\s*=", stripped) and ";" not in stripped:
                in_multiline_assignment = True
                continue
            # e.g. // Debug, // Example usage
            if stripped.startswith("//"):
                continue
            skipping_leading = False
        result.append(line)

    return "\n".join(result).strip()


# ---------------------------------------------------------------------------
# Recursive file processing
# ---------------------------------------------------------------------------


def _process_file(
    file_path: Path,
    processed: Set[Path],
    bosl2_includes: Set[str],
    *,
    libraries_dir: Path,
    scadm_dep_names: Set[str],
) -> str:
    """Recursively process a library file and inline its local includes.

    Args:
        file_path: Absolute path to library file.
        processed: Set of already-processed files (prevents duplicates).
        bosl2_includes: Accumulator for BOSL2 include statements.
        libraries_dir: Absolute path to bin/openscad/libraries.
        scadm_dep_names: Dependency names from scadm.json.

    Returns:
        Cleaned and inlined content.

    Raises:
        ValueError: If library file contains parameter section markers.
    """
    if file_path in processed:
        return ""

    processed.add(file_path)
    content = file_path.read_text(encoding="utf-8")

    if _has_parameter_section(content):
        raise ValueError(
            f"Library file contains parameter section: {file_path}\n"
            f"Library files should not have /* [SectionName] */ markers.\n"
            f"(Re)move them and re-run the flatten!"
        )

    result = []
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
                inlined = _process_file(
                    resolved,
                    processed,
                    bosl2_includes,
                    libraries_dir=libraries_dir,
                    scadm_dep_names=scadm_dep_names,
                )
                if inlined:
                    result.append(inlined)

    clean_content = _strip_comments(content)
    clean_content = _extract_definitions(clean_content)
    # e.g. include <BOSL2/std.scad>, use <lib/helper.scad>
    clean_content = re.sub(r"^\s*(include|use)\s*<[^>]+>\s*$", "", clean_content, flags=re.MULTILINE)
    # Collapse 3+ blank lines to one blank line
    clean_content = re.sub(r"\n\s*\n\s*\n+", "\n\n", clean_content)
    clean_content = clean_content.strip()

    if clean_content:
        result.append(clean_content)
    return "\n\n".join(result)


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
    # Include flatten.py itself so code changes invalidate cache
    deps.add(Path(__file__).resolve())

    resolved_root = workspace_root.resolve()

    def _sort_key(dep: Path) -> tuple[str, str]:
        try:
            return (dep.relative_to(resolved_root).as_posix(), "")
        except ValueError:
            return (dep.name, hashlib.sha256(dep.read_bytes()).hexdigest())

    hasher = hashlib.sha256()
    for dep in sorted(deps, key=_sort_key):
        hasher.update(dep.read_bytes())
    return hasher.hexdigest()


# ---------------------------------------------------------------------------
# Main flatten operation
# ---------------------------------------------------------------------------


def flatten_file(  # pylint: disable=too-many-branches
    input_file: Path, output_file: Path, workspace_root: Optional[Path] = None
) -> None:
    """Flatten a .scad file by inlining all local includes.

    Produces a single-file output with structure:
      BOSL2 includes -> Parameters -> /* [Hidden] */ (inlined libs + root hidden) -> Main code

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

    processed: Set[Path] = {input_file}
    bosl2_includes: Set[str] = set()
    inlined_libs = []

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
                lib_content = _process_file(
                    resolved,
                    processed,
                    bosl2_includes,
                    libraries_dir=libraries_dir,
                    scadm_dep_names=scadm_dep_names,
                )
                if lib_content:
                    inlined_libs.append(lib_content)

    # Assemble output
    output_parts: list[str] = []

    if bosl2_includes:
        output_parts.extend(sorted(bosl2_includes))
        output_parts.append("")

    if params:
        output_parts.append(params.strip())
        output_parts.append("")

    output_parts.append("/* [Hidden] */")
    # Library code first so root Hidden assignments can reference library constants
    if inlined_libs:
        output_parts.append("\n\n".join(inlined_libs))
    if hidden:
        # e.g. /* [Hidden] */  ->  (empty)
        hidden_content = re.sub(r"/\*\s*\[Hidden\]\s*\*/", "", hidden).strip()
        if hidden_content:
            output_parts.append(hidden_content)
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


def _load_flatten_config(workspace_root: Path) -> list[dict]:
    """Load flatten config entries from scadm.json.

    Args:
        workspace_root: Project root containing scadm.json.

    Returns:
        List of {"src": "...", "dest": "..."} dicts.

    Raises:
        FileNotFoundError: If scadm.json not found.
        ValueError: If no flatten config exists.
    """
    scadm_path = workspace_root / "scadm.json"
    if not scadm_path.exists():
        raise FileNotFoundError(f"scadm.json not found at {workspace_root}")

    data = json.loads(scadm_path.read_text(encoding="utf-8"))
    entries = data.get("flatten", [])
    if not entries:
        raise ValueError('No "flatten" entries in scadm.json. Add a "flatten" key with src/dest pairs.')
    return entries


def _discover_scad_files(src_dir: Path, dest_dir: Path) -> list[Path]:
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

    entries = _load_flatten_config(workspace_root)

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
        for scad in _discover_scad_files(src_dir, dest_dir):
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
