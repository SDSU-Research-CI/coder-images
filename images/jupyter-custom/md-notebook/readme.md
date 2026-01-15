# Molecular Dynamics Notebook
Jupyter Notebook container image for running Molecular Dynamics codes

## Software Included
- cmake 
- gcc 
- g++ 
- openmpi-bin 
- vim 
- LAMMPS
- ovito
- Quantum Espresso
- GROMACS
    - *Note*: Requires additional configuration that the user must apply by running the following from terminal once:
    ```
    echo 'source /usr/local/gromacs/bin/GMXRC' >> ~/.bashrc
    source ~/.bashrc
    ```
    - Subsequent sessions should then automatically configure GROMACS

This image is based upon the [Jupyter Stack SciPy image](https://github.com/jupyter/docker-stacks/tree/main/images/scipy-notebook)
