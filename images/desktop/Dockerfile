# Selkies KDE Plasma remote desktop (NVIDIA GLX / X.Org), repackaged for Coder.
#
# Base image: ghcr.io/selkies-project/selkies-glx-desktop
#   - Ubuntu 26.04, s6-supervised X11 + Plasma session streamed over WebSockets/WebRTC.
#   - Session account is uid/gid 1000 with login "ubuntu", HOME=/home/ubuntu,
#     and XDG_RUNTIME_DIR/PulseAudio/PipeWire/D-Bus paths under /tmp/runtime-ubuntu.
#   - The base is username-agnostic at runtime (it uses `id -nu`, $HOME and
#     ${XDG_RUNTIME_DIR:-...}), so renaming the account only requires overriding
#     the baked, name-derived ENV vars below (done further down).
#
# Pin this digest and bump deliberately (see AGENTS.md / README.md).
#   26.04 -> sha256:3cce03e42f8841bbdce82bfafc6ef968a310e0234a4d72efaeeb2caf805bbc75
ARG BASE_IMAGE=ghcr.io/selkies-project/selkies-glx-desktop:26.04

FROM ${BASE_IMAGE}

# Bash + pipefail so `curl | sh` pipelines surface download failures instead of
# silently succeeding with an empty stdin.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The image drops privileges to uid 1000 by default; do the root work here.
USER root

ARG BASE_USER=ubuntu
ARG USERNAME=coder
ARG USER_UID=1000
ARG USER_GID=1000
ARG CONDA_DIR=/opt/conda
ARG MINIFORGE_VERSION=26.7.2-0
# Optional Miniforge installer SHA256; empty means the checksum check is skipped.
ARG MINIFORGE_SHA256=
ARG UV_VERSION=0.12.13

ENV DEBIAN_FRONTEND=noninteractive

# Rename the base's session account: override every baked, name-derived ENV var
# so the runtime is self-consistent under the new login (see header note).
ENV USER=${USERNAME} \
    HOME=/home/${USERNAME} \
    XDG_RUNTIME_DIR=/tmp/runtime-${USERNAME} \
    PIPEWIRE_RUNTIME_DIR=/tmp/runtime-${USERNAME} \
    PULSE_RUNTIME_PATH=/tmp/runtime-${USERNAME}/pulse \
    PULSE_SERVER=unix:/tmp/runtime-${USERNAME}/pulse/native \
    DBUS_SYSTEM_BUS_ADDRESS=unix:path=/tmp/runtime-${USERNAME}/dbus-system-bus \
    CONDA_DIR=${CONDA_DIR} \
    PATH=${CONDA_DIR}/bin:/home/${USERNAME}/.local/bin:${PATH}

# The base already ships bash, ca-certificates, curl, git, jq, locales, sudo,
# unzip, wget, xz-utils, vim and the en_US.UTF-8 locale. Only add what is missing.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    neovim \
    rclone \
    tmux \
 && rm -rf /var/lib/apt/lists/*

# Rename ubuntu -> ${USERNAME}, preserving uid/gid and ALL supplementary group
# memberships (sudo, video, render, input, audio, ... which the GPU/audio stack
# depends on). The base is username-agnostic at runtime (uses `id -nu`, $HOME and
# ${XDG_RUNTIME_DIR:-...}) and no service script references /home/ubuntu, so a
# plain login/home rename is enough. Idempotent across rebuilds.
RUN set -eux; \
    if getent group "${BASE_USER}" >/dev/null 2>&1; then \
      groupmod -n "${USERNAME}" "${BASE_USER}"; \
    fi; \
    if getent passwd "${BASE_USER}" >/dev/null 2>&1; then \
      usermod --login "${USERNAME}" \
              --home "/home/${USERNAME}" --move-home \
              --shell /bin/bash \
              "${BASE_USER}"; \
    fi; \
    if [ "$(id -u "${USERNAME}")" != "${USER_UID}" ]; then \
      usermod --uid "${USER_UID}" "${USERNAME}"; \
    fi; \
    if [ "$(getent group "${USERNAME}" | cut -d: -f3)" != "${USER_GID}" ]; then \
      groupmod --gid "${USER_GID}" "${USERNAME}"; \
    fi; \
    for f in /etc/subuid /etc/subgid; do \
      if [ -f "${f}" ] && grep -q "^${BASE_USER}:" "${f}"; then \
        sed -i "s|^${BASE_USER}:|${USERNAME}:|" "${f}"; \
      fi; \
    done; \
    install -d -m 0755 -o "${USER_UID}" -g "${USER_GID}" "/home/${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# Miniforge (conda-forge, architecture-aware), then a lean base env.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) miniforge_arch="x86_64" ;; \
      arm64) miniforge_arch="aarch64" ;; \
      *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    url="https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-${MINIFORGE_VERSION}-Linux-${miniforge_arch}.sh"; \
    curl -fsSL "${url}" -o /tmp/miniforge.sh; \
    if [ -n "${MINIFORGE_SHA256}" ]; then \
      echo "${MINIFORGE_SHA256}  /tmp/miniforge.sh" | sha256sum --check; \
    fi; \
    bash /tmp/miniforge.sh -b -p "${CONDA_DIR}"; \
    rm -f /tmp/miniforge.sh; \
    "${CONDA_DIR}/bin/conda" install -y -n base -c conda-forge mamba pip python; \
    "${CONDA_DIR}/bin/conda" clean -afy

# uv (pinned), installed system-wide.
RUN curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" \
    | env UV_INSTALL_DIR=/usr/local/bin INSTALLER_NO_MODIFY_PATH=1 sh

# Expose conda shell functions to login shells WITHOUT force-activating base
# (the ENV PATH already provides python/conda/mamba/uv; activation is only
# needed for `conda activate`/`conda deactivate` UX). Avoids the PATH
# duplication and non-login-shell surprises of the previous profile snippet.
RUN printf '%s\n' \
    'if [ -f /opt/conda/etc/profile.d/conda.sh ]; then' \
    '  . /opt/conda/etc/profile.d/conda.sh' \
    'fi' \
    > /etc/profile.d/zz-conda.sh \
 && chmod 0644 /etc/profile.d/zz-conda.sh

# The steps above ran as root with HOME=/home/${USERNAME}, so conda left
# root-owned ~/.conda, ~/.cache, ~/.config behind. Hand the home back to the
# session user or first-run conda/desktop writes fail on permission.
RUN chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"

LABEL org.opencontainers.image.title="coder-images/desktop" \
      org.opencontainers.image.description="Selkies KDE Plasma remote desktop (NVIDIA GLX) repackaged for Coder with Miniforge, uv, and CLI tools." \
      org.opencontainers.image.source="https://github.com/SDSU-Research-CI/coder-images"

WORKDIR /home/${USERNAME}
# Named user (not numeric) so the base's `id -nu`-driven entrypoint and the
# web login resolve to ${USERNAME}; the uid still maps to ${USER_UID}.
USER ${USERNAME}
