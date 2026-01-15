ARG BASE_IMAGE=ghcr.io/sdsu-research-ci/coder-images/r-notebook:2026-01-12

FROM ${BASE_IMAGE}

ARG UBUNTU_VERSION_CODENAME=jammy
ARG RSTUDIO_VERSION=2025.05.1-513

USER root
WORKDIR /opt

# Install Jupyter Desktop dependencies, zip and vim, RStudio dependencies
RUN apt-get -y update \
 && apt-get -y install \
    dbus-x11 \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xorg \
    xubuntu-icon-theme \
    tigervnc-standalone-server \
    tigervnc-xorg-extension \
    zip \
    vim \
    tk \
    tcllib \
    libxkbcommon-x11-0 \
    libnss3 \
    libssl-dev \
    libclang-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"

# Install RStudio Desktop
RUN wget "https://download1.rstudio.org/electron/${UBUNTU_VERSION_CODENAME}/amd64/rstudio-${RSTUDIO_VERSION}-amd64.deb" \
 && apt-get install -y ./"rstudio-${RSTUDIO_VERSION}-amd64.deb" \
 && rm ./"rstudio-${RSTUDIO_VERSION}-amd64.deb"

# Install RStudio Server
RUN curl -o rstudio-server.deb -fsSL "https://download2.rstudio.org/server/${UBUNTU_VERSION_CODENAME}/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb" && \
    apt-get update && \
    apt-get install -y ./rstudio-server.deb && rm -f rstudio-server.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}

# Install Jupyter Desktop proxy
RUN mamba install -y -q -c manics websockify
RUN pip install jupyter-server-proxy jupyter-remote-desktop-proxy 

# Install R Session Proxy
RUN pip install jupyter-rsession-proxy

ENV LD_LIBRARY_PATH=/opt/conda/lib/R/lib:$LD_LIBRARY_PATH
