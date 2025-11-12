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
