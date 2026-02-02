ARG BASE_IMAGE=ghcr.io/sdsu-research-ci/coder-images/scipy-notebook:2026-01-12
FROM ${BASE_IMAGE}

USER root

RUN apt-get update -y \
 && apt-get install -y \
    libopenblas-dev \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* \
 && fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"

USER ${NB_USER}
WORKDIR /home/${NB_USER}

# Install sage via conda
RUN mamba create -y -n sageenv --clone base \
 && mamba install -y -c conda-forge -n sageenv python=3.11 \
 && mamba install -y -c conda-forge -n sageenv sage
