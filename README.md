# Coder Images

Container images for use with [Coder](https://github.com/coder/coder)

## Jupyter Docker Stacks Images

We repackage several of the [Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks) images with necessary changes to work with Coder.

### Manual Build Instructions

Some images may need to be built locally due to container image size limitations in GitHub Actions.
As of writing, this limitation is currently 10GB.

In order to build the Jupyter Docker Stack-based images locally, we need to specify the build target of `notebook-image`, i.e.:

```
docker build . -f Dockerfile -t [your-dockerhub-username]/[image-name]:v[x.x] --target notebook-image
```

#### Local Testing

In order to test these images locally, we need to include the second build stage `local-testing` which installs and runs coder in the container image.
This includes a custom script for use as the container's entrypoint `run-coder.sh`.
The manual configuration in the `local-testing` target is typically handled by Coder via template, so as to install the latest version at runtime as opposed to manually installing a version at build time.

*Note*: The `local-testing` targets should **NOT** be used with Coder due to the increased container image size and potentially conflicting installations of coder.

Due to the location of `run-coder.sh`, Jupyter images should be built from the root of the repository, for example:

```
docker build . -f /image/jupyter/minimal/Dockerfile -t [your-dockerhub-username]/coder-minimal-notebook:v[x.x] --target local-testing
```
