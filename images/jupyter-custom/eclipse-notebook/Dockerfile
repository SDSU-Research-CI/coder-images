ARG BASE_IMAGE=ghcr.io/sdsu-research-ci/coder-images/minimal-notebook:2026-01-12

FROM ${BASE_IMAGE}

USER root
WORKDIR /opt/

ENV ECLIPSE_VERSION=2024-06
ENV ECLIPSE_URL=https://ftp2.osuosl.org/pub/eclipse/technology/epp/downloads/release/2024-06/R/eclipse-cpp-2024-06-R-linux-gtk-x86_64.tar.gz

# Install latest Eclipse C/C++
RUN apt-get -y update \
 && apt-get install -y build-essential \
 && wget $ECLIPSE_URL -O eclipse.tar.gz \
 && tar -xf eclipse.tar.gz -C /opt/ \
 && rm eclipse.tar.gz \
 && touch /usr/share/applications/eclipse.desktop \
 && echo -e "[Desktop Entry]\nVersion = $ECLIPSE_VERSION\nType = Application\nTerminal = false\nName = Eclipse C/C++\nExec = /opt/eclipse/eclipse\nIcon = /opt/eclipse/icon.xpm\nCategories = Application;" > /usr/share/applications/eclipse.desktop \
 && chmod +x /usr/share/applications/eclipse.desktop \
 && touch /etc/novnc.conf \
 && echo "WebClipboard.enabled: true" >> /etc/novnc.conf \
 && echo "SendClipboard: both" >> /etc/novnc.conf

# Install Jupyter Desktop Dependencies
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
 && apt clean \
 && rm -rf /var/lib/apt/lists/* \
 && fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"

# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}

# Install Jupyter Desktop Proxy
RUN /opt/conda/bin/conda install -y -q -c manics websockify \
 && pip install jupyter-remote-desktop-proxy
