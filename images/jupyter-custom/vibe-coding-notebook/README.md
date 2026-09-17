# vibe-coding-notebook
A Jupyter Notebook container image for "vibe coding" with terminal and desktop
AI coding agents, built on this repo's repackaged PyTorch (CUDA 12) notebook so
Ollama can use a GPU when scheduled on an NVIDIA node.

## Software Included
- Ollama
- OpenCode (`opencode`)
- Claude Code (`claude`)
- OpenAI Codex CLI (`codex`)
- GitHub Copilot CLI (`copilot`)
- Node.js 22 (for the CLIs above)
- Jupyter Desktop (XFCE over VNC)
- VS Code (desktop) and Code Server (browser)
- GitHub Copilot desktop app (GUI; launcher `github-copilot`, XFCE menu entry "GitHub Copilot")
- OpenCode desktop app (GUI; launcher `opencode-desktop`, XFCE menu entry "OpenCode")
- Google Chrome
- Mozilla Firefox (**default browser** — see [Default browser](#default-browser))
- GNOME Terminal (**default terminal emulator** — see [Default terminal](#default-terminal))
- nb-venv-kernels (discover venv/uv project envs as Jupyter kernels; supersedes nb_conda_kernels)
- JupyterLab extensions: jupyter-ai (AI chat/magics, incl. Ollama), jupyter-collaboration +
  jupyterlab-chat (realtime co-editing), jupyter-lsp, jupyterlab-code-formatter, jupyterlab-git
- rclone, tmux, vim, neovim, uv, nb_conda_kernels (inherited from base)

> Note: Chrome, VS Code, and the OpenCode desktop app are Chromium/Electron based and are
> launched with `--no-sandbox` (baked into the XFCE `.desktop` launchers and the
> `google-chrome`/`code`/`opencode-desktop` terminal wrappers) because the container's seccomp
> policy blocks unprivileged user namespaces.
> Firefox hits the same restriction but has no `--no-sandbox` flag, so its internal content-process
> sandbox is disabled via `MOZ_DISABLE_CONTENT_SANDBOX=1` (et al.) in the `firefox` wrapper and
> `.desktop` launcher; the container provides isolation instead. code-server is unaffected.
>
> The GitHub Copilot desktop app is Tauri/WebKitGTK, not Electron, so it takes no `--no-sandbox`
> flag. Its WebKit web-process sandbox (bubblewrap) and DMABUF renderer hit the same seccomp and
> no-GPU restrictions, so the `github-copilot` wrapper exports `WEBKIT_FORCE_SANDBOX=0`,
> `WEBKIT_DISABLE_DMABUF_RENDERER=1` and `WEBKIT_DISABLE_COMPOSITING_MODE=1` instead.

### Not included: Cursor
Cursor was installed here up through `dev-v0.0.6` and removed in `dev-v0.0.7`. Pointing it at
your own model endpoint — an OpenAI account with the student's own API key, for instance —
requires a paid subscription, which is the wrong shape for a course image: students should pay
their model provider, not a client that fronts it. VS Code (desktop and code-server), the
OpenCode / Claude Code / Codex / Copilot CLIs, and the OpenCode desktop app cover the same
workflows without that restriction.

### Preinstalled VS Code extensions
Desktop VS Code: Claude Code (`Anthropic.claude-code`), Codex (`openai.chatgpt`),
and OpenCode (`sst-dev.opencode`). **GitHub Copilot and Copilot Chat ship built-in**
with the current Microsoft VS Code build, so they are available out of the box
without being installed.

code-server (browser) gets the Open VSX-available subset only
(Claude Code, Codex, OpenCode). **GitHub Copilot is intentionally omitted** from
code-server because Microsoft does not permit it on non-Microsoft VS Code builds.

## Usage notes
- **No credentials are baked into the image.** Authenticate each tool at runtime:
  - Copilot CLI: `copilot login`, or export `GH_TOKEN`/`COPILOT_GITHUB_TOKEN`
  - Claude Code / Codex / OpenCode: set the provider API keys or run their login flow
    (`opencode` -> `/connect`)
  - GitHub Copilot desktop app: sign in from its welcome screen; the device flow opens
    Chrome/Firefox inside the desktop
  - OpenCode desktop app: it uses the same XDG config (`~/.config/opencode`) and data
    (`~/.local/share/opencode`) directories as the `opencode` CLI, so provider credentials
    and sessions are shared between the two
- **GPU is a runtime property, not an image property.** Ollama only sees the GPU
  when the container runs with the NVIDIA container runtime (e.g. `--gpus all`).
  Otherwise it falls back to CPU. Models download to `~/.ollama` by default.
- Launch Ollama manually after the workspace starts: `ollama serve` (then
  `ollama pull <model>`).

### GitHub Copilot desktop app
- Installed from the official Linux `.deb` (`github` package). The public link
  [gh.io/copilot-app-linux](https://gh.io/copilot-app-linux) serves the AppImage build of
  the same release, which needs FUSE to mount and therefore cannot run in these
  containers; the `.deb` carries the identical payload and lets `apt` resolve the
  WebKitGTK/GTK3/AppIndicator dependencies.
- Launch it from the XFCE menu (Development) once the Jupyter Desktop session is up, or
  from a desktop terminal with `github-copilot &`. The upstream launcher name is
  `github` (`/usr/bin/github`); the `github-copilot` wrapper is preferred because it sets
  the WebKitGTK sandbox/renderer fallbacks.
- The package also drops `git-credential-copilot` in `/usr/bin`; it is installed but not
  wired into any Git config.
- The app's own updater only handles AppImage installs, so treat the image as the update
  mechanism: bump `COPILOT_APP_REF` and rebuild. Its profile lives under `~/.copilot`
  (logs in `~/.copilot/logs`, state in `~/.copilot/data.db`), so sign-in persists with the
  home volume.
- Harmless startup noise: `fusermount3: fuse device not found` / `fuse init failed` from
  `xdg-document-portal` (no `/dev/fuse` in the container) and ALSA/JACK messages (no sound
  device). Neither affects the desktop.

### OpenCode desktop app
- Installed from the official Linux `.deb` (`opencode` package, ~446 MB installed), downloaded
  from [opencode.ai/download/stable/linux-x64-deb](https://opencode.ai/download/stable/linux-x64-deb).
  That link always serves the newest stable build and there is no versioned URL, so the image
  build is the pin (the installed version shows in `dpkg -l opencode`).
- Every dependency the package declares is already installed by the desktop layer, so adding the
  app costs exactly one Debian package and its payload — no new libraries.
- **It does not replace the CLI.** The `.deb` installs its binary as `/opt/OpenCode/ai.opencode.desktop`
  (also registered as `/usr/bin/ai.opencode.desktop` via `update-alternatives`) and never touches
  `/usr/bin/opencode`, which keeps resolving to the npm `opencode-ai` CLI.
- Launch it from the XFCE menu (Development) once the Jupyter Desktop session is up, or from a
  desktop terminal with `opencode-desktop &`. It is Electron, so it needs `--no-sandbox` like
  Chrome/VS Code; the `opencode-desktop` wrapper supplies it, and the image repoints the
  `ai.opencode.desktop` alternative at the wrapper (priority 200) so that name works too.
- The GUI shares the CLI's XDG directories — config in `~/.config/opencode`, data in
  `~/.local/share/opencode` (`opencode.db`, `log/`, `repos/`, and the credential store) — and
  keeps its own Chromium profile in `~/.config/ai.opencode.desktop` (window state, cookies,
  `drafts.sqlite`). All three live under `$HOME`, so settings and sign-in persist with the
  home volume.
- Its built-in updater (`app-update.yml`, `~/.config/ai.opencode.desktop/opencode.updater`)
  cannot write to the root-owned `/opt/OpenCode` install, so treat the image as the update
  mechanism: rebuild to pick up a new stable release.
- The visible launcher (`Name=OpenCode`, `Categories=Development`) owns `x-scheme-handler/opencode`,
  so `opencode://` callbacks route back to the GUI, while its outbound links use the default
  browser, Firefox (see [Default browser](#default-browser)). The package also ships a
  `NoDisplay=true` duplicate entry, left in place.

### Default browser
Firefox is the default. Chrome's `.deb` registers itself in `update-alternatives`, so
without this the desktop, `xdg-open` and the Copilot app's OAuth sign-in handoff all
opened Chrome. The image overrides every layer the desktop consults:

- `/usr/share/applications/defaults.list` — system-wide MIME defaults
  (`text/html`, `text/xml`, `application/xhtml+xml`, `x-scheme-handler/http|https|about|unknown`)
- `x-www-browser` / `gnome-www-browser` alternatives → `/usr/local/bin/firefox`
- `/etc/xdg/xfce4/helpers.rc` + `~/.config/xfce4/helpers.rc` — XFCE's preferred `WebBrowser=firefox`
- `~/.config/mimeapps.list` — per-user defaults (pre-seeded in the image, so a fresh
  Coder home volume still starts out with Firefox)

Chrome stays fully installed and launchable (`google-chrome`, or its menu/panel entry).
To change the default at runtime, use the XFCE *Preferred Applications* dialog (writes
`~/.config/xfce4/helpers.rc`) and/or `xdg-mime default google-chrome.desktop text/html`.

### Default terminal
GNOME Terminal is the preferred terminal emulator, so Thunar's *Open Terminal Here*, the
desktop's *Open Terminal*, and the XFCE menu all open it:

- `gnome-terminal` is installed explicitly (it used to arrive only as a transitive dependency
  of the desktop stack, which a base bump could have dropped) and is marked manually installed.
- `x-terminal-emulator` → `/usr/bin/gnome-terminal.wrapper` via `update-alternatives`, so
  terminal launches from a shell or a `.desktop` file land on it too.
- `/etc/xdg/xfce4/helpers.rc` and `~/.config/xfce4/helpers.rc` set `TerminalEmulator=gnome-terminal`.

### No keyring prompts
Chrome, OpenCode, VS Code and the Copilot app all store tokens through the freedesktop
Secret Service. `gnome-keyring-daemon` is the provider, and because a container has no PAM
login there is no password to unlock its *Login* keyring with — so on the first secret write
it D-Bus-activates `gcr-prompter` and blocks the calling app on a "choose a password for your
keyring" dialog that nobody has an answer for.

The image therefore seeds `~/.local/share/keyrings/login.keyring` with an **empty password**,
which the daemon unlocks silently: no dialog, and secrets persist in the home volume.
`desktop-defaults.sh` writes it, and runs three ways so it works no matter what the home
directory looks like:

- at build time, for a baked-in home;
- from `/usr/local/bin/start-notebook.d/10-vibe-desktop-defaults.sh` at container start
  (Coder mounts a volume over `/home/jovyan`, which hides the baked file);
- from `/etc/xdg/autostart/vibe-desktop-defaults.desktop` when the XFCE session starts.

It is idempotent and only adds what is missing, so a choice made in the *Preferred
Applications* dialog is never overwritten.

Two consequences worth knowing:

- **Secrets are stored in plaintext** in `~/.local/share/keyrings/login.keyring`. That is the
  deliberate trade for a single-user teaching container; do not reuse this image for shared
  or sensitive accounts.
- A keyring that predates this change and *was* given a password keeps prompting. Delete it
  (`rm ~/.local/share/keyrings/login.keyring`) and restart the workspace; the hook recreates
  a working one. The hook also moves aside any keyring in the obsolete pre-INI format as
  `login.keyring.bak` rather than deleting it.

Setting the keyring password to `jovyan` instead would *not* fix this: nothing in the
container unlocks it at login, so the dialog would still appear — it would simply ask for a
password students are told to type.

## Image size
The image bundles several complete desktop applications on top of a CUDA PyTorch stack,
so it is big by design. Note that `docker images` reports the **sum of uncompressed layer
tars**, which overstates the files actually present (a file rewritten by a later layer is
counted in both). Measured on the current dev tag:

| measure | v0.0.3 (before) | v0.0.5 (optimized) | v0.0.6 (+ OpenCode GUI) | v0.0.7 (− Cursor) | v0.0.8 (+ keyring/terminal) |
|---|---|---|---|---|---|
| `docker images` SIZE (uncompressed layers) | 40.8 GB | 33.8 GB | 34.4 GB | 33.1 GB | **33.1 GB** |
| real content (`du -xs /` in a container) | 23 GB | 20 GB | 20.4 GB | 19.5 GB | **19.5 GB** |
| `docker save` (what a push/pull transfers) | 13.36 GB | 10.01 GB | 10.16 GB | 9.88 GB | **9.85 GB** |
| installed Debian packages | 1168 | 880 | 881 | 880 | **880** |

The OpenCode desktop app costs +0.6 GB of layer data, +150 MB of transfer and exactly one
package (all of its dependencies were already installed). Dropping Cursor in v0.0.7 gave back
0.9 GB of content and also cost no packages — its `.deb` pulled in nothing VS Code didn't
already need. v0.0.8 (keyring + preferred-terminal defaults) is one small layer of scripts and
config files: no new packages, no measurable change in size.

Where the 19.5 GB of content lives:

| path | size | what |
|---|---|---|
| `/opt/conda` | 8.8 GB | PyTorch + CUDA 12 (from the base image) |
| `/usr/local/lib/ollama` | 2.1 GB | Ollama + its CUDA 12/13 and Vulkan runtime libs |
| `/usr/bin/github` + `/usr/lib/GitHub Copilot` | 1.25 GB | GitHub Copilot desktop app |
| `/usr/share/code` | 1.0 GB | VS Code |
| `/opt/code-server` | 0.7 GB | code-server |
| `/opt/OpenCode` | 0.45 GB | OpenCode desktop app |
| `/opt/google` | 0.44 GB | Google Chrome |
| `/usr/lib/firefox` | 0.32 GB | Firefox |

What was done to shrink it, without dropping any feature:

- **`--no-install-recommends` on the desktop layer** (1168 → 880 packages). The XFCE/`xorg`
  metapackages recommend an entire Ubuntu desktop — network-manager, lightdm, whoopsie,
  apport, modemmanager, bluetooth, avahi, yelp, unity-*, ibus, sane, ntfs-3g, screen
  lockers, ~300 packages. Everything the image actually relies on is now listed explicitly
  (portal + keyring, notifications, audio, themes/fonts, `xdg-utils`, `gvfs`/`tumbler`,
  CUPS, VA-API/Vulkan drivers, and small CLI utilities such as `file`/`envsubst`).
  The `xserver-xorg-video-*` DDX drivers were dropped because the desktop runs on
  TigerVNC's own X server, not Xorg.
- **One `fix-permissions` pass instead of four.** The Jupyter helper re-chmods/re-chgrps
  every file in `$HOME` that isn't already group-writable, and Docker then re-archives the
  whole tree into a new layer — ~3 GB of layer data per pass for ~1 GB of files. The layers
  that write to `$HOME`/`$CONDA_DIR` now run under `umask 002`, so the files already match
  what `fix-permissions` wants and the single remaining pass is nearly free.
- **Cache hygiene.** `pip --no-cache-dir`, `conda clean --all`, `npm --no-fund --no-audit`
  plus `npm cache clean` in the same layer, `apt clean` in every apt layer, and deletion of
  the `CachedExtensionVSIXs` copies VS Code and code-server keep next to the installed
  extensions.

The remaining gap between 33.1 GB of layers and 19.5 GB of content is inherited: the Jupyter
base image's own `fix-permissions` passes over `/opt/conda` add ~6.7 GB
(`pytorch-notebook:2026-08-03` reports 18.7 GB but contains 12 GB). Flattening this image
(`docker export | docker import`, re-adding `ENV`/`CMD`/`ENTRYPOINT` via `--change`) would
collapse that too, at the cost of sharing no layers with the base image any more.

Further trims that *would* remove functionality, so they are left alone:
`/usr/local/lib/ollama/cuda_v13` (811 MB, only used on a CUDA 13 driver), `cups` (~240 MB,
printing from the desktop), and Chrome (~0.44 GB) if Firefox alone is enough.

## Build
Build locally (custom images are not built in GitHub Actions). Local builds are tagged
`<jupyter_tag>-dev-vX.Y.Z`; bump the patch number for each new one
(current: `2026-08-03-dev-v0.0.8`, which adds the keyring and preferred-terminal defaults on
top of the Cursor removal, the OpenCode desktop app, the GitHub Copilot desktop app, the
Firefox default-browser change, and the ~7 GB of layer bloat removed — see
[Image size](#image-size)). The build context must be the repo root: the Dockerfile `COPY`s
`desktop-defaults.sh` from this directory.

```bash
docker build . \
  --platform linux/amd64 \
  -f images/jupyter-custom/vibe-coding-notebook/Dockerfile \
  -t ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:dev
```

Override the base image/tag if needed:

```bash
docker build . \
  --platform linux/amd64 \
  -f images/jupyter-custom/vibe-coding-notebook/Dockerfile \
  --build-arg BASE_IMAGE=ghcr.io/sdsu-research-ci/coder-images/pytorch-notebook:latest \
  -t ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:<tag>
```

Pin the GitHub Copilot desktop app version instead of tracking the newest release:

```bash
docker build . \
  --platform linux/amd64 \
  -f images/jupyter-custom/vibe-coding-notebook/Dockerfile \
  --build-arg COPILOT_APP_REF=v1.1.21 \
  -t ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:<tag>
```

Retag for release:

```bash
docker image tag \
  ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:dev \
  ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:<jupyter_tag>
```

Push the release tag:

```bash
docker push ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:<jupyter_tag>
```

This image is based on this repo's repackaged `pytorch-notebook` image (which is
itself based on the
[Jupyter Docker Stacks PyTorch image](https://github.com/jupyter/docker-stacks/tree/main/images/pytorch-notebook)).
