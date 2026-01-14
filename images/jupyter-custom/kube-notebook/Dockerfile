ARG BASE_IMAGE=quay.io/jupyter/minimal-notebook:2025-07-07

FROM ${BASE_IMAGE}

# Switch to root for linux updates and installs
USER root
WORKDIR /root

# Install rclone and kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"\
 && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
 && curl -O https://rclone.org/install.sh \
 && bash /root/install.sh \
 && rm -f /root/install.sh \
 && curl -fsSL https://code-server.dev/install.sh | sh

# Install Jupyter Desktop dependencies, zip and vim, Globus dependencies
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
 && apt clean \
 && rm -rf /var/lib/apt/lists/* \
 && fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"

WORKDIR /opt

# Install Google Chrome
RUN curl -O "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
 && dpkg -i google-chrome-stable_current_amd64.deb || true \
 && apt-get install -y -f \
 && rm /opt/google-chrome-stable_current_amd64.deb

# Install GlobusConnectPersonal
RUN wget https://downloads.globus.org/globus-connect-personal/linux/stable/globusconnectpersonal-latest.tgz \
 && tar xzf globusconnectpersonal-latest.tgz \
 && rm globusconnectpersonal-latest.tgz

# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}

# Install Jupyter Desktop
RUN /opt/conda/bin/conda install -y -q -c manics websockify
RUN pip install jupyter-remote-desktop-proxy jupyter-codeserver-proxy
RUN pip install nbgitpuller

ENV PATH=/opt/globusconnectpersonal-3.2.7:$PATH
