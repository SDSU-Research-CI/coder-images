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
- VS Code (desktop), Cursor (desktop), and Code Server (browser)
- GitHub Copilot desktop app (GUI; launcher `github-copilot`, XFCE menu entry "GitHub Copilot")
- Google Chrome
- Mozilla Firefox (**default browser** — see [Default browser](#default-browser))
- nb-venv-kernels (discover venv/uv project envs as Jupyter kernels; supersedes nb_conda_kernels)
- JupyterLab extensions: jupyter-ai (AI chat/magics, incl. Ollama), jupyter-collaboration +
  jupyterlab-chat (realtime co-editing), jupyter-lsp, jupyterlab-code-formatter, jupyterlab-git
- rclone, tmux, vim, neovim, uv, nb_conda_kernels (inherited from base)

> Note: Chrome, VS Code, and Cursor are Chromium/Electron based and are launched with
> `--no-sandbox` (baked into the XFCE `.desktop` launchers and the `google-chrome`/`code`/`cursor`
> terminal wrappers) because the container's seccomp policy blocks unprivileged user namespaces.
> Firefox hits the same restriction but has no `--no-sandbox` flag, so its internal content-process
> sandbox is disabled via `MOZ_DISABLE_CONTENT_SANDBOX=1` (et al.) in the `firefox` wrapper and
> `.desktop` launcher; the container provides isolation instead. code-server is unaffected.
>
> The GitHub Copilot desktop app is Tauri/WebKitGTK, not Electron, so it takes no `--no-sandbox`
> flag. Its WebKit web-process sandbox (bubblewrap) and DMABUF renderer hit the same seccomp and
> no-GPU restrictions, so the `github-copilot` wrapper exports `WEBKIT_FORCE_SANDBOX=0`,
> `WEBKIT_DISABLE_DMABUF_RENDERER=1` and `WEBKIT_DISABLE_COMPOSITING_MODE=1` instead.

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

## Image size
The image bundles several complete desktop applications on top of a CUDA PyTorch stack,
so it is big by design. Note that `docker images` reports the **sum of uncompressed layer
tars**, which overstates the files actually present (a file rewritten by a later layer is
counted in both). Measured on `2026-08-03-dev-v0.0.5`:

| measure | before (v0.0.3) | now (v0.0.5) |
|---|---|---|
| `docker images` SIZE (uncompressed layers) | 40.8 GB | **33.8 GB** |
| `du -xsh /` inside a running container (real content) | 23 GB | **20 GB** |
| `docker save \| wc -c` (what a push/pull transfers) | 13.36 GB | **10.75 GB** |
| installed Debian packages | 1168 | 880 |

Where the 20 GB of content lives:

| path | size | what |
|---|---|---|
| `/opt/conda` | 8.8 GB | PyTorch + CUDA 12 (from the base image) |
| `/usr/local/lib/ollama` | 2.1 GB | Ollama + its CUDA 12/13 and Vulkan runtime libs |
| `/usr/bin/github` + `/usr/lib/GitHub Copilot` | 1.25 GB | GitHub Copilot desktop app |
| `/usr/share/code` | 1.0 GB | VS Code |
| `/usr/share/cursor` | 0.9 GB | Cursor |
| `/opt/code-server` | 0.7 GB | code-server |
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

The remaining gap between 33.8 GB of layers and 20 GB of content is inherited: the Jupyter
base image's own `fix-permissions` passes over `/opt/conda` add ~6.7 GB
(`pytorch-notebook:2026-08-03` reports 18.7 GB but contains 12 GB). Flattening this image
(`docker export | docker import`, re-adding `ENV`/`CMD`/`ENTRYPOINT` via `--change`) would
collapse that too, at the cost of sharing no layers with the base image any more.

Further trims that *would* remove functionality, so they are left alone:
`/usr/local/lib/ollama/cuda_v13` (811 MB, only used on a CUDA 13 driver), `cups` (~240 MB,
printing from the desktop), and Chrome or Cursor (~0.4–0.9 GB each) if only one is needed.

## Build
Build locally (custom images are not built in GitHub Actions). Local builds are tagged
`<jupyter_tag>-dev-vX.Y.Z`; bump the patch number for each new one
(current: `2026-08-03-dev-v0.0.5`, which adds the GitHub Copilot desktop app, makes
Firefox the default browser, and trims ~7 GB of layer bloat — see
[Image size](#image-size)).

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
