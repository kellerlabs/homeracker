"""OpenSCAD Dependency Manager (scadm)."""

__version__ = "0.4.10"

from scadm.installer import (
    install_openscad,
    install_libraries,
    get_installed_openscad_version,
    get_installed_lib_version,
)

__all__ = [
    "__version__",
    "install_openscad",
    "install_libraries",
    "get_installed_openscad_version",
    "get_installed_lib_version",
]
