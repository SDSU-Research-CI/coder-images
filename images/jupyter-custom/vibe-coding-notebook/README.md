# vibe-coding-notebook
A Jupyter Notebook container image for "vibe coding" with terminal and desktop
AI coding agents, built on this repo's repackaged PyTorch (CUDA 12) notebook so
Ollama can use a GPU when scheduled on an NVIDIA node.

## Software Included
**Agents and CLIs**
- Ollama
- OpenCode (`opencode`), Claude Code (`claude`), OpenAI Codex CLI (`codex`), GitHub Copilot CLI (`copilot`)
- Node.js 22 (for the CLIs above)
- rclone, tmux, vim, neovim, uv, nb_conda_kernels (inherited from the base image)

**Desktop (XFCE over VNC)**
- VS Code (desktop) and code-server (browser)
- GitHub Copilot desktop app (launcher `github-copilot`, menu entry "GitHub Copilot")
- OpenCode desktop app (launcher `opencode-desktop`, menu entry "OpenCode")
- Google Chrome, plus Firefox (**default browser**) and GNOME Terminal (**default terminal emulator**)

**Jupyter**
- nb-venv-kernels (discover venv/uv project envs as Jupyter kernels; supersedes nb_conda_kernels)
- jupyter-ai (AI chat/magics, incl. Ollama), jupyter-collaboration + jupyterlab-chat (realtime
  co-editing), jupyter-lsp, jupyterlab-code-formatter, jupyterlab-git

**VS Code extensions.** Desktop VS Code ships with Claude Code (`Anthropic.claude-code`),
Codex (`openai.chatgpt`) and OpenCode (`sst-dev.opencode`); GitHub Copilot and Copilot Chat are
built into Microsoft's VS Code build. code-server (browser) gets the Open VSX-available subset
only (Claude Code, Codex, OpenCode) — Copilot is intentionally omitted because Microsoft does not
permit it on non-Microsoft VS Code builds.

> Chrome, VS Code and the OpenCode desktop app are Chromium/Electron based and are launched with
> `--no-sandbox` (baked into their `.desktop` launchers and their `google-chrome`/`code`/
> `opencode-desktop` terminal wrappers) because the container's seccomp policy blocks unprivileged
> user namespaces. Firefox hits the same restriction but has no `--no-sandbox` flag, so its
> content-process sandbox is disabled via `MOZ_DISABLE_*_SANDBOX=1` in the `firefox` wrapper and
> `.desktop` launcher. The GitHub Copilot desktop app is Tauri/WebKitGTK rather than Electron, so
> its wrapper exports `WEBKIT_FORCE_SANDBOX=0`, `WEBKIT_DISABLE_DMABUF_RENDERER=1` and
> `WEBKIT_DISABLE_COMPOSITING_MODE=1` instead. In every case the container provides the isolation.
> code-server is unaffected.

## NRP LLM Access
Every agent in this image can talk to SDSU's NRP managed LLM service instead of a personal
subscription or API key. Nothing is baked into the image: request access, then paste the config
for your tool into your workspace.

### Requesting access
Faculty may request access on behalf of their courses or student researchers by completing the
[ServiceNow catalog item](https://sdsu.service-now.com/sp?id=sc_cat_item&sys_id=97a539211bb825505764fd1b1e4bcb00)
with the **NRP LLM Access** option. After it is approved:

1. Confirm you belong to a group with the LLM flag on the [namespaces page](https://nrp.ai/namespaces).
2. Create a token on the [LLM token page](https://nrp.ai/llmtoken).

### Endpoint and token
| | |
|---|---|
| OpenAI-compatible base URL | `https://ellm.nrp-nautilus.io/v1` |
| Anthropic-compatible base URL | `https://ellm.nrp-nautilus.io/anthropic` |
| Auth | the token as `Authorization: ******` |

```bash
# list the models your token can use
curl -s -H "Authorization: Bearer $LLM_TOKEN" https://ellm.nrp-nautilus.io/v1/models
```

The catalog currently covers `qwen3`, `qwen3-small`, `glm-5`, `deepseek-v4-flash`, `kimi`,
`minimax-m2`, `gpt-oss`, `gemma` and `gemma-small` (`qwen3-embedding` is an embedding model, not a
chat model). Treat that as a snapshot — model ids, context lengths and thinking controls are NRP's
to change. Requests without a `cache_salt` can share cached prompts with other users of the same
model; see NRP's [API access](https://nrp.ai/documentation/userdocs/ai/llm-managed/api-access/)
page for adding one if your prompts are sensitive.

### VS Code (Copilot Chat)
Desktop VS Code only — code-server has no Copilot Chat. Command Palette (`Ctrl+Shift+P`) →
**Chat: Manage Language Models** → **Add Models** → **Custom Endpoint**, then paste:

```json
{
  "name": "NRP",
  "vendor": "customendpoint",
  "apiKey": "${input:chat.lm.secret.2630e22e}",
  "apiType": "chat-completions",
  "models": [
    { "id": "glm-5", "name": "glm-5", "url": "https://ellm.nrp-nautilus.io/v1/chat/completions", "toolCalling": true, "vision": false, "maxInputTokens": 1048576, "maxOutputTokens": 100000 },
    { "id": "qwen3", "name": "qwen3", "url": "https://ellm.nrp-nautilus.io/v1/chat/completions", "toolCalling": true, "vision": true,  "maxInputTokens": 1000000, "maxOutputTokens": 100000 },
    { "id": "kimi",  "name": "kimi",  "url": "https://ellm.nrp-nautilus.io/v1/chat/completions", "toolCalling": true, "vision": true,  "maxInputTokens": 131072,  "maxOutputTokens": 100000 }
  ]
}
```

The `${input:...}` key makes VS Code ask for your token the first time you use one of the models
and store it securely afterwards. The models then appear in the Copilot Chat model picker.

### OpenCode (CLI and desktop app)
`~/.config/opencode/opencode.jsonc` — the desktop app reads the same file, so this configures both.
Either export `OPENAI_API_KEY` with your token or replace `{env:OPENAI_API_KEY}` with the token.

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "NRP/qwen3",
  "small_model": "NRP/qwen3-small",
  "provider": {
    "NRP": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "NRP",
      "options": {
        "baseURL": "https://ellm.nrp-nautilus.io/v1",
        "apiKey": "{env:OPENAI_API_KEY}"
      },
      "models": {
        "qwen3": {
          "name": "qwen3",
          "limit": { "context": 1000000, "output": 65536 },
          "modalities": { "input": ["text", "image", "video"], "output": ["text"] },
          "tool_call": true,
          "reasoning": true,
          "attachment": true
        },
        "qwen3-small": {
          "name": "qwen3-small",
          "limit": { "context": 1000000, "output": 65536 },
          "tool_call": true,
          "reasoning": true
        }
      }
    }
  }
}
```

`Ctrl+P` → *Switch models* picks `NRP`, *Switch model variant* picks a thinking level. NRP's page
has a longer config that declares every model in the catalog with its per-model thinking controls.
An editor validating against `opencode.ai/config.json` underlines `NRP/qwen3` because the schema
only knows the models.dev catalog; OpenCode resolves it from the `provider` block above.

### Claude Code
`~/.claude/settings.json` — Claude Code uses the Anthropic-compatible endpoint. Replace each
`<name-of-nrp-model>` with a model id from `/v1/models`, and
`<context-size-of-model>` with that model's context length.

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://ellm.nrp-nautilus.io/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "<llm-token>",
    "ANTHROPIC_MODEL": "<name-of-nrp-model>",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "<name-of-nrp-model>",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "<name-of-nrp-model>",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "<name-of-nrp-model>",
    "ANTHROPIC_DEFAULT_FABLE_MODEL": "<name-of-nrp-model>",
    "CLAUDE_CODE_SUBAGENT_MODEL": "<name-of-nrp-model>",
    "ENABLE_TOOL_SEARCH": "false",
    "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "<context-size-of-model>",
    "CLAUDE_CODE_EFFORT_LEVEL": "max",
    "CLAUDE_STREAM_IDLE_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1",
    "CLAUDE_CODE_ENABLE_TELEMETRY": "0",
    "DISABLE_TELEMETRY": "1",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_MAX_RETRIES": "10"
  }
}
```

### GitHub Copilot CLI
Environment variables — `COPILOT_PROVIDER_MAX_PROMPT_TOKENS` is the model's context length and
`COPILOT_PROVIDER_MAX_OUTPUT_TOKENS` a smaller value (roughly 1/16 to 1/4 of it, depending on the
task).

```bash
export COPILOT_PROVIDER_BASE_URL="https://ellm.nrp-nautilus.io/v1"
export COPILOT_PROVIDER_KEY="<llm-token>"
export COPILOT_MODEL="<name-of-nrp-model>"
export COPILOT_PROVIDER_MAX_PROMPT_TOKENS="<context-length>"
export COPILOT_PROVIDER_MAX_OUTPUT_TOKENS="<max-output>"
```

### Other tools
NRP publishes ready-made configs for the tools above (plus Crush, pi, Kimi CLI and omp, which are
not in this image) and nothing yet for the Codex CLI. The endpoint is OpenAI-compatible, so any
client that accepts a custom base URL and bearer token — Codex, jupyter-ai's provider settings, the
OpenAI SDKs — can use it.

> **Check [NRP's client configurations](https://nrp.ai/documentation/userdocs/ai/llm-managed/client-configs/)
> often.** NRP updates those configs on its own schedule, which is not this image's release
> cadence, so the snippets above can lag on model ids, context limits and options. NRP's version
> wins.

## Usage notes
- **No credentials are baked into the image.** Authenticate at runtime: `copilot login` (or export
  `GH_TOKEN`/`COPILOT_GITHUB_TOKEN`), each CLI's own login flow (`opencode` → `/connect`), the
  welcome screen of the Copilot desktop app, or an NRP token as above.
- **Sign-ins persist with the home volume.** The OpenCode GUI shares the CLI's XDG directories
  (`~/.config/opencode`, `~/.local/share/opencode`), the Copilot app keeps its profile in
  `~/.copilot` (logs in `~/.copilot/logs`, state in `~/.copilot/data.db`), and browser profiles
  live under `$HOME` too.
- **GPU is a runtime property, not an image property.** Ollama only sees the GPU when the container
  runs with the NVIDIA container runtime (e.g. `--gpus all`), otherwise it falls back to CPU.
  Models download to `~/.ollama`.
- Launch Ollama manually after the workspace starts: `ollama serve` (then `ollama pull <model>`).
- Harmless startup noise in the desktop: `fusermount3: fuse device not found` / `fuse init failed`
  from `xdg-document-portal` (no `/dev/fuse` in the container) and ALSA/JACK messages (no sound
  device). Neither affects the desktop.

## Desktop apps
### GitHub Copilot desktop app
- Installed from the official Linux `.deb` (`github` package). The public link
  [gh.io/copilot-app-linux](https://gh.io/copilot-app-linux) serves the AppImage build of the same
  release, which needs FUSE to mount and therefore cannot run in these containers; the `.deb`
  carries the identical payload and lets `apt` resolve the WebKitGTK/GTK3/AppIndicator dependencies.
- Launch it from the XFCE menu (Development) once the Jupyter Desktop session is up, or from a
  desktop terminal with `github-copilot &`. The upstream launcher name is `github`
  (`/usr/bin/github`); prefer the `github-copilot` wrapper, which sets the WebKitGTK
  sandbox/renderer fallbacks. The package also drops `git-credential-copilot` in `/usr/bin` —
  installed, but not wired into any Git config.
- The app's own updater only handles AppImage installs, so treat the image as the update mechanism:
  bump `COPILOT_APP_REF` and rebuild.

### OpenCode desktop app
- Installed from the official Linux `.deb` (`opencode` package, ~446 MB installed), downloaded from
  [opencode.ai/download/stable/linux-x64-deb](https://opencode.ai/download/stable/linux-x64-deb).
  That link always serves the newest stable build and there is no versioned URL, so the image build
  is the pin (the installed version shows in `dpkg -l opencode`). Every dependency it declares was
  already installed, so the app costs exactly one Debian package.
- **It does not replace the CLI.** The `.deb` installs `/opt/OpenCode/ai.opencode.desktop` (also
  `/usr/bin/ai.opencode.desktop` via `update-alternatives`) and never touches `/usr/bin/opencode`,
  which keeps resolving to the npm `opencode-ai` CLI.
- Launch it from the XFCE menu (Development) or with `opencode-desktop &`. It is Electron, so it
  needs `--no-sandbox` like Chrome/VS Code; the `opencode-desktop` wrapper supplies it, and the
  image repoints the `ai.opencode.desktop` alternative at the wrapper (priority 200) so that name
  works too. Its built-in updater cannot write to the root-owned `/opt/OpenCode` install, so rebuild
  to pick up a new stable release.
- The visible launcher (`Name=OpenCode`, `Categories=Development`) owns `x-scheme-handler/opencode`,
  so `opencode://` callbacks route back to the GUI, while its outbound links use Firefox. The
  package also ships a `NoDisplay=true` duplicate entry, left in place.

## Desktop defaults
### Default browser
Firefox. Chrome's `.deb` registers itself in `update-alternatives`, so without this the desktop,
`xdg-open` and the Copilot app's OAuth sign-in handoff all opened Chrome. The image overrides every
layer the desktop consults: system MIME defaults in `/usr/share/applications/defaults.list`, the
`x-www-browser`/`gnome-www-browser` alternatives (→ `/usr/local/bin/firefox`), XFCE's preferred
`WebBrowser=firefox` in `/etc/xdg/xfce4/helpers.rc` and `~/.config/xfce4/helpers.rc`, and a
pre-seeded `~/.config/mimeapps.list` so a fresh Coder home volume still starts out with Firefox.
Chrome stays fully installed and launchable (`google-chrome`, or its menu/panel entry). To change
the default at runtime, use the XFCE *Preferred Applications* dialog and/or
`xdg-mime default google-chrome.desktop text/html`.

### Default terminal
GNOME Terminal, so Thunar's *Open Terminal Here*, the desktop's *Open Terminal* and the XFCE menu
all open it. It is installed explicitly (it used to arrive only as a transitive dependency of the
desktop stack, which a base bump could have dropped) and marked manually installed,
`x-terminal-emulator` points at `/usr/bin/gnome-terminal.wrapper`, and both the system and per-user
`helpers.rc` set `TerminalEmulator=gnome-terminal`.

### No keyring prompts
Chrome, OpenCode, VS Code and the Copilot app all store tokens through the freedesktop Secret
Service. `gnome-keyring-daemon` is the provider, and because a container has no PAM login there is
no password to unlock its *Login* keyring with — so on the first secret write it D-Bus-activates
`gcr-prompter` and blocks the calling app on a "choose a password for your keyring" dialog that
nobody has an answer for. The image therefore seeds `~/.local/share/keyrings/login.keyring` with an
**empty password**, which the daemon unlocks silently: no dialog, and secrets persist in the home
volume.

`desktop-defaults.sh` writes it, and runs at build time and from
`/usr/local/bin/start-notebook.d/10-vibe-desktop-defaults.sh` at container start (Coder mounts a
volume over `/home/jovyan`, which hides the baked file). It is idempotent and only adds what is
missing, so a choice made in the *Preferred Applications* dialog is never overwritten.

It always writes as the notebook user, even when the container starts as root, and repairs
`~/.config`, `~/.config/xfce4` and `~/.local/share/keyrings` if an older build left them owned by
root. That matters: `xfconfd` needs to write `~/.config/xfce4/xfconf/`, and when it cannot the
desktop opens on *"Unable to load a failsafe session"* instead of a panel.

Two consequences worth knowing:

- **Secrets are stored in plaintext** in `~/.local/share/keyrings/login.keyring`. That is the
  deliberate trade for a single-user teaching container; do not reuse this image for shared or
  sensitive accounts.
- A keyring that predates this change and *was* given a password keeps prompting. Delete it
  (`rm ~/.local/share/keyrings/login.keyring`) and restart the workspace; the hook recreates a
  working one.

Setting the keyring password to `jovyan` instead would *not* fix this: nothing in the container
unlocks it at login, so the dialog would still appear — it would simply ask for a password students
are told to type.

## Build
Build locally (custom images are not built in GitHub Actions) **from the repo root** — the Dockerfile
`COPY`s `desktop-defaults.sh` from this directory. Local builds are tagged
`<jupyter_tag>-dev-vX.Y.Z`; bump the patch number for each new one, and retag an approved build as
`<jupyter_tag>-vX.Y.Z` when publishing it.

The current release is **`2026-08-03-v1.0.0`**: the GitHub Copilot and OpenCode desktop apps,
Firefox and GNOME Terminal as the defaults, no keyring password prompts, NRP LLM configuration for
every bundled agent, and no Cursor.

```bash
docker build . \
  --platform linux/amd64 \
  -f images/jupyter-custom/vibe-coding-notebook/Dockerfile \
  -t ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:dev
```

Override the base image/tag, or pin the GitHub Copilot desktop app version instead of tracking the
newest release:

```bash
docker build . \
  --platform linux/amd64 \
  -f images/jupyter-custom/vibe-coding-notebook/Dockerfile \
  --build-arg BASE_IMAGE=ghcr.io/sdsu-research-ci/coder-images/pytorch-notebook:latest \
  --build-arg COPILOT_APP_REF=v1.1.21 \
  -t ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:<tag>
```

Retag and push a release:

```bash
docker image tag \
  ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:dev \
  ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:<jupyter_tag>
docker push ghcr.io/sdsu-research-ci/coder-images/vibe-coding-notebook:<jupyter_tag>
```

This image is based on this repo's repackaged `pytorch-notebook` image (which is
itself based on the
[Jupyter Docker Stacks PyTorch image](https://github.com/jupyter/docker-stacks/tree/main/images/pytorch-notebook)).
