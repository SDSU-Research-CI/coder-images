# RStudio Desktop Notebook
A container image for a Jupyter Notebook with RStudio and a desktop environment

## Software Inluded
- RStudio (Server and Desktop)
- Jupyter Desktop

## Custom conda R environments
At Jupyter startup the image scans conda environments and registers a separate
RStudio launcher tile (via [jupyter-rsession-proxy](https://github.com/jupyterhub/jupyter-rsession-proxy))
for every environment that contains an executable `bin/R`. Each RStudio session is
started inside `conda activate <env>`, so the environment's `PATH`, `activate.d`
hooks, and libraries are applied.

- The conda **base** environment is intentionally skipped; RStudio running with the
  image's default R is provided by the stock `rstudio` tile registered by
  jupyter-rsession-proxy.
- Environments created after Jupyter starts appear the next time the Jupyter server
  is restarted.
- Additional search roots can be supplied with the colon-separated
  `JUPYTER_RSESSION_PROXY_ENV_DIRS` environment variable (prefix environments such as
  `conda create -p ~/my-r-env ...` under `$HOME` are also detected).

This image is based on the [Jupyter Docker Stacks R Notebook](https://github.com/jupyter/docker-stacks/tree/main/images/r-notebook) container image.
