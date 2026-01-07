# Repository Guidelines

## Project Structure & Modules
- `images/jupyter/Dockerfile`: Single multi-stage build used to repackage Jupyter Docker Stacks with code-server and locale tweaks. All image changes happen here.
- `images/desktop/`: Reserved for future desktop-oriented images (currently empty).
- `.github/workflows/build.yml`: GitHub Actions matrix that builds and pushes tagged images to GHCR based on `BASE_IMAGE` values.
- `README.md`: High-level overview and manual build instructions; keep this in sync with Dockerfile changes.

## Build, Test, and Development Commands
- Local build targeting notebook stage (matches CI):  
  `docker build . -f images/jupyter/Dockerfile --target notebook-image --build-arg BASE_IMAGE=quay.io/jupyter/minimal-notebook:latest -t ghcr.io/sdsu-research-ci/coder-images/minimal-notebook:dev`
- Run container for a quick smoke test (expose Jupyter):  
  `docker run --rm -p 8888:8888 ghcr.io/sdsu-research-ci/coder-images/minimal-notebook:dev`
- Trigger CI build (requires GitHub Actions access):  
  `gh workflow run build.yml -f jupyter_tag=latest`
- Retag before pushing an approved build:  
  `docker image tag <id> ghcr.io/sdsu-research-ci/coder-images/<stack>:<jupyter_tag>`

## Coding Style & Naming Conventions
- Dockerfile: Uppercase ARG/ENV names; one logical change per layer; prefer `apt-get install -y --no-install-recommends` with list kept alphabetized.
- Shell snippets: use `\` line continuations, `&&` chaining, and clean up cache (`rm -rf /var/lib/apt/lists/*`).
- Image tags: use Jupyter tag dates (`2025-11-10`) or `latest`; keep CUDA variants explicit (e.g., `cuda12`).

## Testing Guidelines
- No automated test suite; rely on container smoke tests. Confirm notebook launches and code-server proxy works after builds.
- For CUDA-enabled images, verify GPU visibility (`nvidia-smi`) on a CUDA-capable host before tagging.
- When altering base images or packages, capture the build log and a brief runtime check (port 8888 reachable) in the PR notes.

## Commit & Pull Request Guidelines
- Commits: concise, imperative summaries (e.g., `Add codeserver proxy`, `Update build matrix tags`), mirroring existing history.
- PRs: include the targeted stack(s), chosen `jupyter_tag`, and rationale for base image/tag bumps. Attach build command used, image tag produced, and results of local smoke tests. Link related issues; add screenshots or logs when user-facing behavior changes.

## Security & Configuration Tips
- Secrets: CI reads `JUPYTER_TAG` from Actions variables; never hardcode tokens. Keep CODE_SERVER_VERSION explicit when changing it.
- Dependency hygiene: bump base images deliberately and note upstream changelog highlights; prefer pinning specific CUDA tags when updating GPU stacks.
