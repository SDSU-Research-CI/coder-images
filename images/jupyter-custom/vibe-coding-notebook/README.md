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
- Mozilla Firefox
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

## Build
Build locally (custom images are not built in GitHub Actions):

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
