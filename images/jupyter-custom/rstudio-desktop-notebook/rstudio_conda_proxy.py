"""Register a Jupyter server-proxy RStudio tile for each conda env containing R.

This file is installed as ``jupyter_server_config.py`` and executed by
jupyter_server at startup. It discovers conda environments that ship an
executable ``bin/R`` and exposes each one through ``jupyter-rsession-proxy``
(RStudio Server bound to that environment's R via ``--rsession-which-r``).

Each environment is launched inside ``conda activate <prefix>`` so the
environment's ``PATH``, ``activate.d`` hooks (e.g. ``PROJ_LIB``, ``GDAL_DATA``,
reticulate's Python) and library paths apply -- mirroring how a kernel picks up
its own environment. The conda *base* prefix is intentionally skipped: the stock
``rstudio`` tile from ``jupyter-rsession-proxy`` already covers the base R.

Environments created after Jupyter starts are picked up on the next Jupyter
restart. Extra search roots can be supplied with the colon-separated
``JUPYTER_RSESSION_PROXY_ENV_DIRS`` environment variable.
"""

import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


def _conda_executable():
    conda = os.environ.get("CONDA_EXE")
    if conda and os.path.exists(conda):
        return conda
    return shutil.which("conda")


def _conda_base():
    """Resolve the conda installation root (its base prefix)."""
    conda = _conda_executable()
    if conda:
        try:
            result = subprocess.run(
                [conda, "info", "--base"], check=True, capture_output=True, text=True
            )
            base = result.stdout.strip()
            if base:
                return Path(base).resolve()
        except (OSError, subprocess.CalledProcessError):
            pass
    if conda:
        # <base>/bin/conda -> <base>
        return Path(conda).resolve().parent.parent
    return Path(os.environ.get("CONDA_PREFIX", "/opt/conda")).resolve()


def _env_list_from_conda(conda):
    environments = []
    if not conda:
        return environments
    try:
        result = subprocess.run(
            [conda, "env", "list", "--json"], check=True, capture_output=True, text=True
        )
        environments.extend(Path(p) for p in json.loads(result.stdout).get("envs", []))
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        pass
    return environments


def _candidate_prefixes(base_prefix):
    """Return deduped conda env prefixes that are not the base install."""
    conda = _conda_executable()
    candidates = list(_env_list_from_conda(conda))

    # Prefix-created envs outside envs_dirs are not guaranteed to appear in
    # `conda env list`, so also probe common roots one level deep. The home
    # directory supports `conda create -p ~/my-r-env`.
    search_roots = [
        Path.home(),
        Path.home() / ".conda" / "envs",
        Path.home() / "envs",
        Path("/opt/conda/envs"),
    ]
    for var in ("CONDA_ENVS_PATH", "JUPYTER_RSESSION_PROXY_ENV_DIRS"):
        for entry in os.environ.get(var, "").split(os.pathsep):
            if entry:
                search_roots.append(Path(entry).expanduser())

    known = set()
    for env in candidates:
        try:
            resolved = env.resolve()
        except OSError:
            continue
        if resolved != base_prefix and (resolved / "bin" / "R").is_file():
            known.add(resolved)

    for root in search_roots:
        if not root.is_dir():
            continue
        try:
            if root.resolve() != base_prefix and (root / "bin" / "R").is_file():
                known.add(root.resolve())
            for child in root.iterdir():
                try:
                    resolved = child.resolve()
                except OSError:
                    continue
                if resolved != base_prefix and child.is_dir() and (child / "bin" / "R").is_file():
                    known.add(resolved)
        except OSError:
            continue

    return sorted(known)


def _proxy_key(name):
    slug = re.sub(r"[^A-Za-z0-9_-]+", "-", name).strip("-") or "environment"
    return f"rstudio-conda-{slug}"


def _activation_wrapper(inner_command, prefix, conda_sh):
    """Wrap setup_rserver's command so the env is activated before rserver execs."""

    def _command(port, unix_socket):
        argv = inner_command(port, unix_socket)
        if conda_sh:
            script = (
                "set -e; "
                f". {shlex.quote(conda_sh)}; "
                f"conda activate {shlex.quote(prefix)}; "
                f"exec {shlex.join(argv)}"
            )
        else:
            script = f"set -e; exec {shlex.join(argv)}"
        return ["bash", "-lc", script]

    return _command


def discover_rstudio_servers():
    try:
        from jupyter_rsession_proxy import setup_rserver
    except ImportError:
        print(
            "rstudio_conda_proxy: jupyter-rsession-proxy is not installed; "
            "skipping conda R environment discovery.",
            file=sys.stderr,
        )
        return {}

    servers = {}
    base_prefix = _conda_base()
    conda_sh = base_prefix / "etc" / "profile.d" / "conda.sh"
    conda_sh = str(conda_sh) if conda_sh.is_file() else None

    used = set()
    for prefix in _candidate_prefixes(base_prefix):
        r_path = prefix / "bin" / "R"
        if not (r_path.is_file() and os.access(r_path, os.X_OK)):
            continue

        key = _proxy_key(prefix.name)
        suffix = 2
        while key in used:
            key = f"{_proxy_key(prefix.name)}-{suffix}"
            suffix += 1
        used.add(key)

        entry = setup_rserver(
            prefix=key,
            r_path=str(r_path),
            launcher_title=f"RStudio ({prefix.name})",
        )
        entry["command"] = _activation_wrapper(entry["command"], str(prefix), conda_sh)
        servers[key] = entry

    return servers


try:
    c.ServerProxy.servers.update(discover_rstudio_servers())
except Exception as exc:  # never let discovery failures break Jupyter startup
    print(f"rstudio_conda_proxy: failed to register conda R servers: {exc}", file=sys.stderr)
