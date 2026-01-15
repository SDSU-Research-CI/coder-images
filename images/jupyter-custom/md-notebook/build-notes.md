# Build Notes

## Quantum Espresso
If you are building this container, then you must first create an account with [Quantum Espresso](https://www.quantum-espresso.org/login/).

Then you will be able to [download the latest version](https://www.quantum-espresso.org/download-page/) of the source code and documentation for Quantum Espresso (QE).

After that, you will need to extract the documentation and look for the user_guide.pdf which will contain compilation and configuration steps.

I recommend building the container up to the point that the source tarball (q-e-x.x.x.tar.gz) has been copied into the container.
From there, I recommend running the container and then following the compilation and configuration steps inside the container.
The QE docs should have a test suite you can run to verify the install.
Assuming that everything works well, then I would add the compilation/configuration steps prescribed in the user guide to the container.

## GROMACS GPU Build
Install a C++ Compiler
sudo apt update
sudo apt install build-essential

Install NVIDIA CUDA 12.8
Go to NVIDIA CUDA 12.8 official repo
cd ~
Download and install repository pin file (prioritizes NVIDIA repo)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin
sudo mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600
Add NVIDIA public key
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub
Add CUDA 12.8 repository
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /"
Update package list
sudo apt update

Install CUDA 12.8
sudo apt install -y cuda-12-8

Add CUDA 12.8 to PATH permanently
echo 'export PATH=/usr/local/cuda-12.8/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
Reload
source ~/.bashrc
Fix symlink /usr/local/cuda to point to 12.8
sudo ln -snf /usr/local/cuda-12.8 /usr/local/cuda
Check CUDA is available
nvcc –version

Install Python3
sudo apt install python3-dev python3-pip

Confirm WSL2 is used
wsl – status
Make sure it shows
Default Version: 2

Download GROMACS 2025.1
cd ~
wget https://ftp.gromacs.org/gromacs/gromacs-2025.1.tar.gz

Extract
tar -xvzf gromacs-2025.1.tar.gz

Prepare GROMACS build folder
cd ~/gromacs-2025.1
mkdir build
cd build

Make a special cuda-gcc directory (This is due to a version issue and may not be necessary in the future)
mkdir -p ~/cuda-gcc
Create symbolic links to gcc-12 and g++-12 inside this folder
ln -s /usr/bin/gcc-12 ~/cuda-gcc/gcc
ln -s /usr/bin/g++-12 ~/cuda-gcc/g++

Run CMake to configure the build
cmake .. \
  -DGMX_BUILD_OWN_FFTW=ON \
  -DREGRESSIONTEST_DOWNLOAD=ON \
  -DGMX_GPU=CUDA \
  -DGMX_SIMD=AVX2_256 \
  -DGMX_OPENMP=ON \
  -DGMX_USE_RDTSCP=ON \
  -DGMX_MPI=OFF \
  -D CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-12.8 \
  -DCUDAToolkit_ROOT=/usr/local/cuda-12.8 \
  -DCMAKE_C_COMPILER=gcc-12 \
  -DCMAKE_CXX_COMPILER=g++-12 \
  -D CUDAHOSTCXX=~/cuda-gcc/g++ \
  -DGMX_CUDA_NVCC_FLAGS="-allow-unsupported-compiler"

Compile GROMACS
make -j4

Install GROMACS system-wide
sudo make install

Add GROMACS to environment (Permanent)
echo 'source /usr/local/gromacs/bin/GMXRC' >> ~/.bashrc
source ~/.bashrc

Confirm GROMACS is installed with GPU support
gmx --version
Make sure it shows
GPU support: CUDA
