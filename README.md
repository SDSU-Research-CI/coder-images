# Coder Images

Container images for use with [Coder](https://github.com/coder/coder)

## Jupyter Docker Stacks Images

We repackage several of the [Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks) images with necessary changes to work with Coder.

### GitHub Actions Build Instructions

This repo is configured to build all of the container images specified in the GitHub Actions [.github/workflows/build.yml](./.github/workflows/build.yml) file.
These builds can be viewed at [Build Jupyter Coder Images](https://github.com/SDSU-Research-CI/coder-images/actions/workflows/build.yml).
The resulting container images should be linked on the repo home page in the packages section to the right.

Builds can be triggered manually on the repo's actions tab, via pushing an update to the repo under the `images/jupyter` directory or an update to the workflow yaml file itself.
The jupyter tag should be given a value of `latest` or a build date like `2025-11-10` on the respective images from [quay.io/organization/jupyter](https://quay.io/organization/jupyter).
Either build trigger will default to `latest` if unset.
- Manually triggered builds will prompt for a jupyter_tag value
- Automatic builds will use the value of the JUPYTER_TAG variable specified in the repo Settings → Secrets and variables → Actions → Variables

>Note: There are some images which have a specific cuda version which may need to have the `cuda12` portion of their tag updated directly in the action yaml file. I.E. the PyTorch notebook.

### Manual Build Instructions

Some images may need to be built locally due to container image size limitations in GitHub Actions.
As of writing, this limitation is currently 10GB.

In order to build the Jupyter Docker Stack-based images locally, we need to specify the build target of `notebook-image`, i.e.:

```bash
docker build . -f Dockerfile -t [your-dockerhub-username]/[image-name]:v[x.x] --target notebook-image
```

Once the container has been built, it should be tested on a dev instance of coder prior to being retagged as an official image.

Execute the following to retag a locally built image, replacing the notebook name:
```bash
docker image tag [container-id] ghcr.io/sdsu-research-ci/coder-images/[notebook-name]:[jupyter_tag]
```
- I.E. `docker image tag ea984ac26018 ghcr.io/sdsu-research-ci/coder-images/minimal-notebook:2025-11-10`
