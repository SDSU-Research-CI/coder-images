ARG BASE_IMAGE=ghcr.io/sdsu-research-ci/coder-images/pytorch-notebook:2026-08-03

FROM ${BASE_IMAGE}

# Switch to root for OS packages, desktop stack, and CLIs
USER root
WORKDIR /root

ARG NODE_MAJOR=22

# Prerequisites used by the installer steps below
RUN apt-get -y update \
 && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    debianutils \
    gnupg \
    wget \
    zip \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Install Jupyter Desktop (XFCE + TigerVNC) dependencies
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
 && rm -rf /var/lib/apt/lists/*

# Install Node.js (NodeSource) so the AI coding CLIs can be installed via npm
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && apt-get -y install nodejs \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Install Firefox from the upstream Mozilla APT repository.
# Ubuntu 24.04's `firefox` package is a snap stub that cannot run inside a container.
RUN install -d -D /etc/apt/keyrings \
 && wget -qO /etc/apt/keyrings/packages.mozilla.org.asc https://packages.mozilla.org/apt/repo-signing-key.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list \
 && printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla \
 && apt-get -y update \
 && apt-get -y install firefox \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
WORKDIR /opt
RUN curl -O "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
 && dpkg -i google-chrome-stable_current_amd64.deb || true \
 && apt-get install -y -f \
 && rm -f /opt/google-chrome-stable_current_amd64.deb \
 && rm -rf /var/lib/apt/lists/*

# Download and install latest VS Code (desktop)
RUN wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" \
    -O /opt/vscode-latest.deb \
 && apt-get install -y /opt/vscode-latest.deb \
 && rm -f /opt/vscode-latest.deb \
 && echo -e "[Desktop Entry]\nName=Visual Studio Code\nComment=Code Editing. Redefined.\nGenericName=Text Editor\nExec=/usr/share/code/code --disable-dev-shm-usage --unity-launch %F\nIcon=vscode\nType=Application\nStartupNotify=false\nStartupWMClass=Code\nCategories=TextEditor;Development;IDE;\nMimeType=text/plain;inode/directory;application/x-code-workspace;\nActions=new-empty-window;\nKeywords=vscode;\n[Desktop Action new-empty-window]\nName=New Empty Window\nExec=/usr/share/code/code --disable-dev-shm-usage --new-window %F\nIcon=vscode" \
    > /usr/share/applications/code.desktop \
 && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install the AI coding CLIs
RUN npm install -g \
    opencode-ai \
    @anthropic-ai/claude-code \
    @openai/codex \
    @github/copilot

# Ensure X11 socket dir has canonical ownership/mode for Xvnc.
RUN mkdir -p /tmp/.X11-unix \
 && chown root:root /tmp/.X11-unix \
 && chmod 1777 /tmp/.X11-unix

# Fix any permissions issues caused by installing software via root
RUN fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"

# Switch back to notebook user
USER ${NB_USER}
WORKDIR /home/${NB_USER}

# Install Jupyter Desktop
RUN /opt/conda/bin/conda install -y -q -c manics websockify \
 && pip install jupyter-remote-desktop-proxy

# Preinstall VS Code agent extensions into the desktop VS Code.
# GitHub Copilot (and Copilot Chat) now ship built-in with current VS Code, so they
# are intentionally NOT installed here (attempting to reinstall them fails as a
# "built-in extension cannot be downgraded"). Extension installs are non-fatal so a
# transient registry error does not break the build.
RUN for ext in \
      Anthropic.claude-code \
      openai.chatgpt \
      sst-dev.opencode ; do \
      code --install-extension "${ext}" --force \
        || echo "WARN: could not install ${ext} into VS Code"; \
    done

# Preinstall the Open VSX-available subset into code-server (browser VS Code).
# GitHub Copilot is omitted because Microsoft does not permit it on non-Microsoft builds.
RUN for ext in \
      Anthropic.claude-code \
      openai.chatgpt \
      sst-dev.opencode ; do \
      code-server --install-extension "${ext}" \
        || echo "WARN: could not install ${ext} into code-server"; \
    done

RUN fix-permissions "/home/${NB_USER}"

# Discover venv/uv project environments as Jupyter kernels.
# Drop-in superset of nb_conda_kernels (already in the base); auto-enables as the
# default KernelSpecManager on install. Keep kernels scoped to project venvs for vibe coding.
RUN pip install nb-venv-kernels

# Chrome and VS Code are Chromium/Electron based. The container's seccomp policy blocks
# unprivileged user namespaces, so their sandbox aborts ("Failed to move to new namespace").
# Force --no-sandbox for the XFCE desktop launchers and for terminal invocation, and restore
# the setuid sandbox helper as a fallback. Firefox and code-server are unaffected.
USER root
RUN sed -i 's#^Exec=/usr/bin/google-chrome-stable#Exec=/usr/bin/google-chrome-stable --no-sandbox --disable-dev-shm-usage#' \
      /usr/share/applications/google-chrome.desktop \
 && sed -i 's#^Exec=/usr/share/code/code#Exec=/usr/share/code/code --no-sandbox#' \
      /usr/share/applications/code.desktop \
 && printf '#!/bin/sh\nexec /usr/bin/google-chrome-stable --no-sandbox --disable-dev-shm-usage "$@"\n' > /usr/local/bin/google-chrome \
 && printf '#!/bin/sh\nexec /usr/share/code/code --no-sandbox --disable-dev-shm-usage "$@"\n' > /usr/local/bin/code \
 && chmod +x /usr/local/bin/google-chrome /usr/local/bin/code \
 && chown root:root /opt/google/chrome/chrome-sandbox /usr/share/code/chrome-sandbox \
 && chmod 4755 /opt/google/chrome/chrome-sandbox /usr/share/code/chrome-sandbox
USER ${NB_USER}

# Environment variables
ENV SDL_AUDIODRIVER=dummy
ENV AUDIODEV=null
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
ENV __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
