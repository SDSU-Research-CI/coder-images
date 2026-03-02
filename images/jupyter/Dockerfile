ARG BASE_IMAGE=quay.io/jupyter/minimal-notebook:latest

FROM ${BASE_IMAGE} AS notebook-image

USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    locales \
    neovim \
    rclone \
    sudo \
    vim \
 && rm -rf /var/lib/apt/lists/*

# Generate the desired locale (en_US.UTF-8)
RUN locale-gen en_US.UTF-8

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

ARG CODE_SERVER_VERSION=latest
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/opt/code-server \
 && ln -s /opt/code-server/bin/code-server /usr/local/bin/code-server

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh \
 && fix-permissions /usr/local/bin \
 && fix-permissions /home/${NB_USER}

USER ${NB_USER}
WORKDIR /home/$NB_USER

RUN pip install jupyter-codeserver-proxy

RUN mamba install -y -n base \
    nb_conda_kernels
