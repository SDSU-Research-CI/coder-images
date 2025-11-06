ARG BASE_IMAGE=quay.io/jupyter/minimal-notebook:2025-07-07

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
    sudo \
    rclone \
    && rm -rf /var/lib/apt/lists/*

# Generate the desired locale (en_US.UTF-8)
RUN locale-gen en_US.UTF-8

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Remove the `jovyan` user and add a user `coder` so that you're not developing as the `root` user
RUN userdel -r ${NB_USER} \
 && useradd coder \
    --create-home \
    --shell=/bin/bash \
    --uid=1000 \
    --user-group \
 && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
 && chown -R coder:coder /home/coder

# Switch to coder user, override env vars from Jupyter base image
USER coder
WORKDIR /home/coder
ENV HOME=/home/coder
ENV NB_USER=coder

FROM notebook-image AS local-testing

USER root
WORKDIR /root

# Fix permissions for coder home directory
RUN chown -R coder:coder /home/coder

# Add directory for coder install for local testing in Docker; transer owner to coder user & group
RUN mkdir -p /opt/code-server \
 && chown -R coder:coder /opt/code-server

USER coder
WORKDIR /home/coder

# Install coder/code-server for local testing in Docker -- coder will install its own version at runtime
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/opt/code-server

# Override entrypoint and healthcheck from Jupyter base image for local testing in Docker
COPY run-coder.sh /opt/run-coder.sh
ENTRYPOINT [ "sh", "/opt/run-coder.sh" ]
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=5 \
  CMD curl -fsS http://0.0.0.0:13337/healthz || exit 1

# Expose coder port for local testing in Docker
EXPOSE 13337

