ARG BASE_IMAGE=ghcr.io/sdsu-research-ci/coder-images/pytorch-notebook:latest
FROM ${BASE_IMAGE}

USER root
WORKDIR /opt

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Switch back to notebook user
USER $NB_USER
WORKDIR /home/${NB_USER}

# Install packages via conda-forge
RUN mamba install -y -c conda-forge -n base \
    boto3 \
    geopandas \
    geoplot \
    laspy \
    lightgbm \
    natsort \
    netcdf4 \
    pysal \
    selenium \
    sentinelhub \
    xeus-python 

# Install opencv via pip
RUN pip install \
    opencv-contrib-python \
    eo-learn
