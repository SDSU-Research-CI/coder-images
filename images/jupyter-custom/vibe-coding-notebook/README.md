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
- **GPU is a runtime property, not an image property.** Ollama only sees the GPU
  when the container runs with the NVIDIA container runtime (e.g. `--gpus all`).
  Otherwise it falls back to CPU. Models download to `~/.ollama` by default.
- Launch Ollama manually after the workspace starts: `ollama serve` (then
  `ollama pull <model>`).

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
