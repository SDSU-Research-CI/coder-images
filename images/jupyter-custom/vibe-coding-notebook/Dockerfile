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

# Install Jupyter Desktop (XFCE + TigerVNC) dependencies.
# --no-install-recommends keeps this layer ~1.1 GB instead of ~2.5 GB: the metapackages
# recommend a whole Ubuntu desktop (network-manager, lightdm, whoopsie, modemmanager,
# bluetooth, avahi, yelp, unity, ...), ~630 extra packages. The recommends this image's
# behaviour actually depends on are listed explicitly instead:
#   xdg-utils (xdg-open/xdg-settings, used by browser hand-off and the default-browser
#   config), iproute2 (ip/ss), the desktop portal + keyring (Copilot app sign-in and the
#   Chromium/Firefox screen-share and secret APIs), policykit-1-gnome (pkexec agent),
#   notifications (xfce4-notifyd + notify-send), audio (pulseaudio, panel mixer, pavucontrol),
#   theme + fonts (greybird, murrine, Liberation, Ubuntu) so the desktop looks the same,
#   gnome-menus (garcon application menu), SVG icon rendering, gvfs + tumbler (Thunar
#   trash/volumes/thumbnails), CUPS (browser printing), locales, xfonts-scalable, and the
#   VA-API/Vulkan drivers used by browser video playback.
# Also restored: acl, file, gettext-base, gir1.2-gtk-3.0, python3-dbus, python3-xdg —
# generic CLI/dev utilities that came in as recommends (a few MB total).
# Dropped for real: network-manager, lightdm, whoopsie/apport, modemmanager, bluetooth,
# avahi, yelp, unity-*, screen lockers, upower, colord, ibus, sane, ntfs-3g and the
# xserver-xorg-video-* DDX drivers (the desktop runs on TigerVNC's own X server, not Xorg).
# xfwm4, xfdesktop4, thunar, xfce4-appfinder and xfce4-pulseaudio-plugin are hard Depends,
# so the session itself is unchanged (verified: xfwm4/xfdesktop/xfce4-panel/xfsettingsd all
# start under `dbus-run-session -- xfce4-session`).
RUN apt-get -y update \
 && apt-get -y install --no-install-recommends \
    acl \
    at-spi2-core \
    cups \
    dbus-user-session \
    dbus-x11 \
    dconf-cli \
    file \
    fonts-liberation \
    fonts-ubuntu \
    gettext-base \
    gir1.2-gtk-3.0 \
    gnome-keyring \
    gnome-menus \
    greybird-gtk-theme \
    gtk2-engines-murrine \
    gvfs \
    gvfs-backends \
    iproute2 \
    libcanberra-gtk3-module \
    libcanberra-pulse \
    libnotify-bin \
    librsvg2-common \
    libxfce4util-bin \
    locales \
    mesa-va-drivers \
    mesa-vulkan-drivers \
    pavucontrol \
    policykit-1-gnome \
    pulseaudio \
    pulseaudio-utils \
    python3-dbus \
    python3-xdg \
    tigervnc-standalone-server \
    tigervnc-tools \
    tigervnc-xorg-extension \
    tumbler \
    xclip \
    xdg-dbus-proxy \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-user-dirs \
    xdg-utils \
    xfce4 \
    xfce4-notifyd \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xfonts-scalable \
    xorg \
    xubuntu-icon-theme \
    zenity \
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
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Download and install latest VS Code (desktop)
RUN wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" \
    -O /opt/vscode-latest.deb \
 && apt-get install -y /opt/vscode-latest.deb \
 && rm -f /opt/vscode-latest.deb \
 && apt clean \
 && echo -e "[Desktop Entry]\nName=Visual Studio Code\nComment=Code Editing. Redefined.\nGenericName=Text Editor\nExec=/usr/share/code/code --disable-dev-shm-usage --unity-launch %F\nIcon=vscode\nType=Application\nStartupNotify=false\nStartupWMClass=Code\nCategories=TextEditor;Development;IDE;\nMimeType=text/plain;inode/directory;application/x-code-workspace;\nActions=new-empty-window;\nKeywords=vscode;\n[Desktop Action new-empty-window]\nName=New Empty Window\nExec=/usr/share/code/code --disable-dev-shm-usage --new-window %F\nIcon=vscode" \
    > /usr/share/applications/code.desktop \
 && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install the AI coding CLIs. --no-fund/--no-audit skip registry round-trips; the npm
# cache (~700 MB of tarballs under $npm_config_cache) is purged in the same layer so it
# never lands in an image layer.
RUN npm install -g --no-fund --no-audit \
    opencode-ai \
    @anthropic-ai/claude-code \
    @openai/codex \
    @github/copilot \
 && npm cache clean --force \
 && rm -rf "$(npm config get cache)" /root/.npm /root/.cache

# Ensure X11 socket dir has canonical ownership/mode for Xvnc.
RUN mkdir -p /tmp/.X11-unix \
 && chown root:root /tmp/.X11-unix \
 && chmod 1777 /tmp/.X11-unix

# NOTE: no fix-permissions pass here. The root installs above land in /usr, /opt and
# /usr/local, which are read-only-by-design for the notebook user, and ${CONDA_DIR} is
# untouched by root. fix-permissions rewrites metadata, and Docker re-archives every file
# it touches into a new layer, so a pass over ${CONDA_DIR} (8.8 GB) or ${HOME} (~2 GB)
# costs that much image size again. The single pass over ${HOME} happens in the last
# layer, after the caches are scrubbed.

# Switch back to notebook user
USER ${NB_USER}
WORKDIR /home/${NB_USER}

# Install Jupyter Desktop
RUN umask 002 \
 && /opt/conda/bin/conda install -y -q -c manics websockify \
 && conda clean -y -q --all \
 && pip install --no-cache-dir jupyter-remote-desktop-proxy

# Preinstall VS Code agent extensions into the desktop VS Code.
# GitHub Copilot (and Copilot Chat) now ship built-in with current VS Code, so they
# are intentionally NOT installed here (attempting to reinstall them fails as a
# "built-in extension cannot be downgraded"). Extension installs are non-fatal so a
# transient registry error does not break the build.
RUN umask 002 \
 && for ext in \
      Anthropic.claude-code \
      openai.chatgpt \
      sst-dev.opencode ; do \
      code --install-extension "${ext}" --force \
        || echo "WARN: could not install ${ext} into VS Code"; \
    done \
 && rm -rf /home/"${NB_USER}"/.config/Code/CachedExtensionVSIXs

# Preinstall the Open VSX-available subset into code-server (browser VS Code).
# GitHub Copilot is omitted because Microsoft does not permit it on non-Microsoft builds.
RUN umask 002 \
 && for ext in \
      Anthropic.claude-code \
      openai.chatgpt \
      sst-dev.opencode ; do \
      code-server --install-extension "${ext}" \
        || echo "WARN: could not install ${ext} into code-server"; \
    done \
 && rm -rf /home/"${NB_USER}"/.cache/code-server

# Discover venv/uv project environments as Jupyter kernels.
# Drop-in superset of nb_conda_kernels (already in the base); auto-enables as the
# default KernelSpecManager on install. Keep kernels scoped to project venvs for vibe coding.
RUN umask 002 \
 && pip install --no-cache-dir nb-venv-kernels

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

# Firefox's content-process sandbox fails under the container seccomp policy too, but Firefox
# has no --no-sandbox flag; it is disabled via MOZ_DISABLE_*_SANDBOX env vars (the container
# provides isolation instead).
#
# NOTE: Cursor was removed here (dev-v0.0.7). Its support for custom model endpoints is gated
# behind a paid subscription, which does not fit a teaching image where students bring their
# own API keys; VS Code (desktop + code-server) and the CLI agents cover the same workflows.
USER root
RUN printf '#!/bin/sh\nexport MOZ_DISABLE_CONTENT_SANDBOX=1\nexport MOZ_DISABLE_GPU_SANDBOX=1\nexport MOZ_DISABLE_RDD_SANDBOX=1\nexport MOZ_DISABLE_GMP_SANDBOX=1\nexec /usr/bin/firefox "$@"\n' > /usr/local/bin/firefox \
 && chmod +x /usr/local/bin/firefox \
 && for f in /usr/share/applications/*[Ff]irefox*.desktop; do \
      [ -e "$f" ] && sed -i -E 's#^Exec=#Exec=env MOZ_DISABLE_CONTENT_SANDBOX=1 MOZ_DISABLE_GPU_SANDBOX=1 MOZ_DISABLE_RDD_SANDBOX=1 MOZ_DISABLE_GMP_SANDBOX=1 #' "$f"; \
    done
USER ${NB_USER}

# Install the GitHub Copilot desktop app (Linux GUI). The public download link
# (https://gh.io/copilot-app-linux) serves an AppImage, which needs FUSE to mount and so
# cannot run in these containers; the same release publishes an .deb with the identical
# payload, so install that instead. COPILOT_APP_REF=latest tracks the newest release;
# set it to a tag (e.g. v1.1.21) to pin. xdg-utils is pulled in for the app's browser
# handoff during sign-in (xdg-open -> Chrome/Firefox).
USER root
ARG COPILOT_APP_REF=latest
RUN curl -fL "https://github.com/github/app/releases/${COPILOT_APP_REF}/download/GitHub-Copilot-linux-x64.deb" \
      -o /opt/github-copilot.deb \
 && apt-get -y update \
 && apt-get install -y xdg-utils /opt/github-copilot.deb \
 && rm -f /opt/github-copilot.deb \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# The .deb installs the app as /usr/bin/github (package name `github`) plus a
# "GitHub Copilot.desktop" launcher whose Categories= is empty, so XFCE never shows it.
# Rename the launcher, give it a category, and point it at a wrapper that turns off the
# WebKitGTK features that need privileges or a GPU this container doesn't have: the
# bubblewrap web-process sandbox (same unprivileged-userns restriction that forces
# --no-sandbox on Chrome/VS Code) and the DMABUF/GBM renderer (Xvnc has no DRI, Mesa
# falls back to llvmpipe). Being Tauri/WebKitGTK rather than Electron, the app itself
# takes no --no-sandbox flag.
RUN printf '#!/bin/sh\nexport WEBKIT_FORCE_SANDBOX=0\nexport WEBKIT_DISABLE_DMABUF_RENDERER=1\nexport WEBKIT_DISABLE_COMPOSITING_MODE=1\nexport GDK_BACKEND=x11\nexec /usr/bin/github "$@"\n' > /usr/local/bin/github-copilot \
 && chmod +x /usr/local/bin/github-copilot \
 && mv "/usr/share/applications/GitHub Copilot.desktop" /usr/share/applications/github-copilot.desktop \
 && sed -i -e 's#^Exec=.*#Exec=/usr/local/bin/github-copilot %u#' \
           -e 's#^Categories=.*#Categories=Development;Utility;#' \
        /usr/share/applications/github-copilot.desktop \
 && (update-desktop-database /usr/share/applications || true)

# Install the OpenCode desktop app (Linux GUI). The stable download link
# (https://opencode.ai/download/stable/linux-x64-deb) always serves the newest
# opencode-desktop-linux-amd64.deb and there is no versioned URL, so the image build is
# the pin. Every Depends (libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6,
# libatspi2.0-0, libuuid1, libsecret-1-0, xdg-utils) is already installed by the desktop
# layer above, so --no-install-recommends adds no packages, only the ~446 MB payload.
# Its postinst registers the app in update-alternatives and the desktop database; it installs
# no `opencode` binary, so the npm CLI already provided by this image is untouched.
RUN curl -fL "https://opencode.ai/download/stable/linux-x64-deb" -o /opt/opencode-desktop.deb \
 && apt-get -y update \
 && apt-get install -y --no-install-recommends /opt/opencode-desktop.deb \
 && rm -f /opt/opencode-desktop.deb \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# OpenCode desktop is Electron (Chromium 140 / Electron 42), so it needs --no-sandbox like
# Chrome/VS Code. The package ships the binary as /opt/OpenCode/ai.opencode.desktop
# and registers it in update-alternatives as /usr/bin/ai.opencode.desktop, but installs no
# `opencode` launcher, so it cannot shadow the npm CLI. Add an `opencode-desktop` wrapper and
# point both .desktop files and the alternatives group at it (higher priority) so every way of
# starting the GUI gets --no-sandbox; the raw alternative aborts with "Failed to move to new
# namespace" under the container's seccomp policy even though the .deb ships its own setuid
# chrome-sandbox.
RUN printf '#!/bin/sh\nexec /opt/OpenCode/ai.opencode.desktop --no-sandbox --disable-dev-shm-usage "$@"\n' > /usr/local/bin/opencode-desktop \
 && chmod +x /usr/local/bin/opencode-desktop \
 && for f in /usr/share/applications/ai.opencode.desktop.desktop /usr/share/applications/opencode-desktop.desktop; do \
      [ -e "$f" ] && sed -i 's#^Exec=/opt/OpenCode/ai.opencode.desktop#Exec=/usr/local/bin/opencode-desktop#' "$f"; \
    done \
 && update-alternatives --install /usr/bin/ai.opencode.desktop ai.opencode.desktop /usr/local/bin/opencode-desktop 200 \
 && update-alternatives --set ai.opencode.desktop /usr/local/bin/opencode-desktop \
 && (update-desktop-database /usr/share/applications || true)

# Make Firefox the default browser. Chrome's .deb registers itself as the default in
# update-alternatives (x-www-browser / gnome-www-browser), and with no MIME defaults on
# the system xdg-open/xdg-settings fall back to that, so links (and the Copilot app's
# OAuth sign-in handoff) opened Chrome. Override every layer the desktop consults:
# system-wide MIME defaults (used by xdg-open/xdg-mime for every user, including a fresh
# Coder home volume), the alternatives, and XFCE's preferred WebBrowser helper. The
# firefox.desktop launcher already carries the MOZ_DISABLE_*_SANDBOX env (see above), and
# the alternative points at the /usr/local/bin/firefox wrapper for the same reason.
RUN printf '[Default Applications]\napplication/xhtml+xml=firefox.desktop\ntext/html=firefox.desktop\ntext/xml=firefox.desktop\nx-scheme-handler/about=firefox.desktop\nx-scheme-handler/http=firefox.desktop\nx-scheme-handler/https=firefox.desktop\nx-scheme-handler/unknown=firefox.desktop\n' \
      > /usr/share/applications/defaults.list \
 && update-desktop-database /usr/share/applications \
 && update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/firefox 300 \
 && update-alternatives --install /usr/bin/gnome-www-browser gnome-www-browser /usr/local/bin/firefox 300 \
 && update-alternatives --set x-www-browser /usr/local/bin/firefox \
 && update-alternatives --set gnome-www-browser /usr/local/bin/firefox \
 && mkdir -p /etc/xdg/xfce4 \
 && printf '[Preferred Applications]\nWebBrowser=firefox\n' > /etc/xdg/xfce4/helpers.rc \
 && mkdir -p "/home/${NB_USER}/.config/xfce4" \
 && printf '[Default Applications]\nx-scheme-handler/http=firefox.desktop\nx-scheme-handler/https=firefox.desktop\ntext/html=firefox.desktop\n' \
      > "/home/${NB_USER}/.config/mimeapps.list" \
 && cp /etc/xdg/xfce4/helpers.rc "/home/${NB_USER}/.config/xfce4/helpers.rc" \
 && chown "${NB_USER}:${NB_GID}" "/home/${NB_USER}/.config/mimeapps.list" \
      "/home/${NB_USER}/.config/xfce4" "/home/${NB_USER}/.config/xfce4/helpers.rc"
USER ${NB_USER}

# JupyterLab AI + collaboration + coding ergonomics. Single pip transaction so the
# resolver reconciles their overlapping JupyterLab/ydoc pins. jupyterlab-lsp is the
# Lab frontend (jupyter-lsp alone is only the server side); python-lsp-server provides
# the actual Python language server so completion/hover work out of the box.
#
# umask 002 makes the notebook user's new files group-writable up front, which is what
# fix-permissions below enforces anyway; without it every file in $HOME is rewritten
# (metadata-only, but Docker re-archives each one into a new layer, ~2 GB here).
RUN umask 002 \
 && pip install --no-cache-dir \
    jupyter-ai \
    jupyter-collaboration \
    jupyterlab-chat \
    jupyterlab-lsp \
    python-lsp-server[all] \
    jupyterlab-code-formatter \
    jupyterlab-git \
    black \
    isort

# Scrub the build-time caches (npm tarballs, pip/conda caches, the VSIX copies VS Code and
# code-server keep next to the installed extensions, code-server's compiled cache) and then
# run the single fix-permissions pass over the notebook user's home. Doing both here keeps
# the caches out of the permissions layer instead of archiving them twice.
USER root
RUN rm -rf \
      "/home/${NB_USER}/.npm" \
      "/home/${NB_USER}/.cache/code-server" \
      "/home/${NB_USER}/.cache/conda" \
      "/home/${NB_USER}/.cache/pip" \
      "/home/${NB_USER}/.config/Code/CachedExtensionVSIXs" \
      "/home/${NB_USER}/.local/share/code-server/CachedExtensionVSIXs" \
      /root/.cache /root/.npm \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb \
 && fix-permissions "/home/${NB_USER}"

# Desktop defaults that have to survive a persistent home volume: GNOME Terminal as the
# preferred terminal emulator, and an empty-password Login keyring so that Chrome, OpenCode,
# VS Code and the Copilot app never block on a "choose a password for your keyring" dialog
# (there is no PAM login in a container, so the daemon cannot unlock a password-protected
# keyring and falls back to prompting gcr-prompter, which students cannot answer). The
# script also runs at container start and at session start because Coder mounts a volume
# over ${HOME}, hiding anything baked in here; see desktop-defaults.sh.
#
# This extends the /etc/xdg/xfce4/helpers.rc written by the default-browser layer above, and
# is the single place to edit preferred applications now.
#
# gnome-terminal is already in the image but only as a transitive dependency of the desktop
# stack (it provides x-terminal-emulator), so it is installed explicitly to make the
# dependency intentional; that costs no extra download.
USER root
COPY images/jupyter-custom/vibe-coding-notebook/desktop-defaults.sh /usr/local/bin/vibe-desktop-defaults.sh
RUN apt-get -y update \
 && apt-get install -y --no-install-recommends gnome-terminal \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 755 /usr/local/bin/vibe-desktop-defaults.sh \
 && printf '#!/bin/bash\n/usr/local/bin/vibe-desktop-defaults.sh\n' \
      >/usr/local/bin/start-notebook.d/10-vibe-desktop-defaults.sh \
 && chmod 755 /usr/local/bin/start-notebook.d/10-vibe-desktop-defaults.sh \
 && printf '[Desktop Entry]\nType=Application\nName=Vibe coding desktop defaults\nComment=Apply per-user keyring and preferred-application defaults\nExec=/usr/local/bin/vibe-desktop-defaults.sh\nTerminal=false\nNoDisplay=true\nX-GNOME-Autostart-Phase=Applications\nX-GNOME-Autostart-enabled=true\n' \
      >/etc/xdg/autostart/vibe-desktop-defaults.desktop \
 && update-alternatives --set x-terminal-emulator /usr/bin/gnome-terminal.wrapper \
 && printf '[Preferred Applications]\nTerminalEmulator=gnome-terminal\nTerminalEmulatorDismissed=true\nWebBrowser=firefox\nWebBrowserDismissed=true\n' \
      >/etc/xdg/xfce4/helpers.rc
USER ${NB_USER}
RUN /usr/local/bin/vibe-desktop-defaults.sh

# Environment variables
ENV SDL_AUDIODRIVER=dummy
ENV AUDIODEV=null
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
ENV __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
