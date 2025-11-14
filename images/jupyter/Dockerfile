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
    sudo \
    rclone \
    vim \
 && rm -rf /var/lib/apt/lists/*

# Generate the desired locale (en_US.UTF-8)
RUN locale-gen en_US.UTF-8

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

ARG NB_USER=jovyan
RUN usermod -aG sudo "${NB_USER}" && \
    echo "%sudo ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/99-nopasswd
