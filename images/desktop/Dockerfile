ARG BASE_IMAGE=ghcr.io/selkies-project/nvidia-glx-desktop:24.04

FROM ${BASE_IMAGE}

USER root

ARG USERNAME=coder
ARG USER_UID=1000
ARG USER_GID=1000
ARG MINIFORGE_VERSION=25.3.1-0

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV HOME=/home/${USERNAME}
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV PATH=${CONDA_DIR}/bin:/home/${USERNAME}/.local/bin:${PATH}
ENV USER=${USERNAME}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    bzip2 \
    ca-certificates \
    curl \
    git \
    locales \
    neovim \
    rclone \
    sudo \
    tmux \
    unzip \
    wget \
    xz-utils \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

RUN existing_group_by_gid="$(getent group "${USER_GID}" | cut -d: -f1 || true)" \
 && if [ -n "${existing_group_by_gid}" ] && [ "${existing_group_by_gid}" != "${USERNAME}" ]; then \
      groupmod -n "${USERNAME}" "${existing_group_by_gid}"; \
    elif [ -z "${existing_group_by_gid}" ] && getent group "${USERNAME}" >/dev/null; then \
      groupmod -g "${USER_GID}" "${USERNAME}"; \
    elif [ -z "${existing_group_by_gid}" ]; then \
      groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi \
 && existing_user_by_uid="$(getent passwd "${USER_UID}" | cut -d: -f1 || true)" \
 && if [ -n "${existing_user_by_uid}" ] && [ "${existing_user_by_uid}" != "${USERNAME}" ]; then \
      user_home="$(getent passwd "${existing_user_by_uid}" | cut -d: -f6)"; \
      usermod --login "${USERNAME}" --home "/home/${USERNAME}" --move-home --gid "${USER_GID}" --shell /bin/bash "${existing_user_by_uid}"; \
      if [ "${user_home}" != "/home/${USERNAME}" ] && [ -d "${user_home}" ]; then chown -R "${USER_UID}:${USER_GID}" "/home/${USERNAME}"; fi; \
    elif id -u "${USERNAME}" >/dev/null 2>&1; then \
      usermod --uid "${USER_UID}" --gid "${USER_GID}" --shell /bin/bash "${USERNAME}"; \
    else \
      useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}"; \
    fi \
 && install -d -m 0755 -o "${USER_UID}" -g "${USER_GID}" "/home/${USERNAME}" \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
 && chmod 0440 "/etc/sudoers.d/${USERNAME}"

RUN arch="$(dpkg --print-architecture)" \
 && case "${arch}" in \
      amd64) miniforge_arch="x86_64" ;; \
      arm64) miniforge_arch="aarch64" ;; \
      *) echo "Unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-Linux-${miniforge_arch}.sh" -o /tmp/miniforge.sh \
 && bash /tmp/miniforge.sh -b -p "${CONDA_DIR}" \
 && rm -f /tmp/miniforge.sh \
 && "${CONDA_DIR}/bin/conda" install -y -n base -c conda-forge mamba pip python \
 && "${CONDA_DIR}/bin/conda" clean -afy

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

RUN printf '%s\n' \
    'export PATH=/opt/conda/bin:$PATH' \
    'if [ -f /opt/conda/etc/profile.d/conda.sh ]; then' \
    '  . /opt/conda/etc/profile.d/conda.sh' \
    '  conda activate base' \
    'fi' \
    > /etc/profile.d/conda.sh \
 && chmod 0644 /etc/profile.d/conda.sh \
 && printf '%s\n' \
    'if [ -f /etc/profile.d/conda.sh ]; then' \
    '  . /etc/profile.d/conda.sh' \
    'fi' \
    >> "/home/${USERNAME}/.bashrc" \
 && chown "${USER_UID}:${USER_GID}" "/home/${USERNAME}/.bashrc"

WORKDIR /home/${USERNAME}
USER ${USERNAME}
