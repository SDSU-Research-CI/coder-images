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
