ARG BASE_IMAGE=ghcr.io/sdsu-research-ci/coder-images/pytorch-notebook:2026-01-12

FROM ${BASE_IMAGE}

# Switch to root for linux updates and installs
USER root
WORKDIR /root

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"\
 && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

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
 && rm globusconnectpersonal-latest.tgz \
 && GLOBUS_DIR="$(find /opt -maxdepth 1 -type d -name 'globusconnectpersonal-*' | head -n 1)" \
 && ln -sfn "$GLOBUS_DIR" /opt/globusconnectpersonal

# Download and install latest VS Code
RUN wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" \
    -O /opt/vscode-latest.deb \
 && apt-get install -y /opt/vscode-latest.deb \
 && rm /opt/vscode-latest.deb \
 && echo -e "[Desktop Entry]\nName=Visual Studio Code\nComment=Code Editing. Redefined.\nGenericName=Text Editor\nExec=/usr/share/code/code --disable-dev-shm-usage --unity-launch %F\nIcon=vscode\nType=Application\nStartupNotify=false\nStartupWMClass=Code\nCategories=TextEditor;Development;IDE;\nMimeType=text/plain;inode/directory;application/x-code-workspace;\nActions=new-empty-window;\nKeywords=vscode;\n[Desktop Action new-empty-window]\nName=New Empty Window\nExec=/usr/share/code/code --disable-dev-shm-usage --new-window %F\nIcon=vscode"\
    > /usr/share/applications/code.desktop

# Ensure X11 socket dir has canonical ownership/mode for Xvnc.
RUN mkdir -p /tmp/.X11-unix \
 && chown root:root /tmp/.X11-unix \
 && chmod 1777 /tmp/.X11-unix

# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}

# Install Jupyter Desktop
RUN /opt/conda/bin/conda install -y -q -c manics websockify
RUN pip install jupyter-remote-desktop-proxy

# Install Gymnasium with atari and mujoco environments
RUN pip install swig
RUN pip install -U "gymnasium[all]" shimmy
RUN pip install -U "autorom[accept-rom-license]"

# Install additional packages
RUN pip install -U \
    pytest \
    "ray[rllib]" \
    opencv-python-headless
RUN mamba install -y -n base \
    moviepy \
    ffmpeg \
    tqdm

# Environment variables
ENV PATH=/opt/globusconnectpersonal:$PATH
ENV SDL_AUDIODRIVER=dummy
ENV AUDIODEV=null
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
ENV __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
