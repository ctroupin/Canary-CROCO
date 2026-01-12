# Running CROCO 

## Code download

The code is obtained from the Gitlab repository: https://www.croco-ocean.org/download/. The code version is v2.1.2, released on November 18, 2025. 

## CROCO compilation

There are essentially 3 files to edit before the compilation:
1. `param.h`, which contains parameters related to the grid, the tiling (for parallel computing) and other options.
2. `cppdef.h` contains the C preprocessor (CPP) options, for instance this is where the boundary conditions (open or close) are specified, or the type of paralelisation (openMP, MPI, ...).
3. `jobcomp` is the file that starts the compilation; it can be editied to specify the Fortran compiler, the compilation flags, the path of the netCDF library

### NetCDF compilation

Before the model code compilation, it might be necessary to compile the netCDF library, in order to ensure that the compiler matches the one that will be used for CROCO. 

Here we used the Intel compilers available on the cluster. The netCDF compilation involves a few steps collected into a single script [compile_netCDF.sh](src/compile_netCDF.sh). 
This script calls `module` commands such as 
```bash
module load releases/2023b
module load intel-compilers
```
which allow one to use pre-installed software on the cluster.

> [!NOTE]
> We stick to HDF5 version 1.14.6, since issues were encountered with the version 2.0.0.


This is the beginning of the file `jobcomp` (user options):

```bash
#
# set source
#
SOURCE1=../OCEAN

#
# determine operating system
#
OS=`uname`
echo "OPERATING SYSTEM IS: $OS"

#
# compiler options
#
FC=ifx

#
# set MPI directories if needed
#
MPIF90="mpiifort"
MPILIB=""
MPIINC=""

#
# set NETCDF directories
#
NETCDFLIB=$(~/.local/mpiifort/bin/nf-config --flibs)
NETCDFINC=-I$(~/.local/mpiifort/bin/nf-config --includedir)

#
# set OASIS-MCT (or OASIS3) directories if needed
#
PRISM_ROOT_DIR=../../../oasis3-mct/compile_oa3-mct

#
# set XIOS directory if needed
#
# if coupling with OASIS3-MCT is activated :
# => you need to use XIOS compiled with the "--use_oasis oasis3_mct" flag
#-----------------------------------------------------------
XIOS_ROOT_DIR=$HOME/xios
```

### CROCO

We create the grid, initial conditions and boundary files with the [CROCO toolbox](https://croco-ocean.gitlabpages.inria.fr/croco_pytools/index.html) in Python. 

The toolbox doesn't have the possibility to create the forcing, so we will rely on the [ROMS toolbox](https://roms-tools.readthedocs.io/en/latest/) (also in Python), hoping that the horizontal grids are compatible.

https://roms-tools.readthedocs.io/en/latest/surface_forcing.html
https://roms-tools.readthedocs.io/en/latest/datasets.html

Procedure
1. Edit the file `grid_neatlantic.ini` and run `nb_make_grid.ipynb`. 
2. Edit `download_mercator.ini` and run `./download_mercator.py`; the download is necessary before creating the initial and boundary conditions.
2. Edit `ibc.ini` and `run make_ini.py`.

#### Grid

Essential step! Check [Evan's paper](https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2010JC006665).

```python
grid = Grid(
    nx=520,  # number of grid points in x-direction
    ny=450,  # number of grid points in y-direction
    size_x=3300,  # domain size in x-direction (in km)
    size_y=1350,  # domain size in y-direction (in km)
    center_lon=-17.75,  # longitude of the center of the domain
    center_lat=30,  # latitude of the center of the domain
    rot=-15,  # rotation of the grid (in degrees)
    N=40,  # number of vertical layers
    verbose=True,
)
```

## Issues

```python
NotImplementedError: LateralFill currently supports only 2D masks.
```

+ there is a warning about the missing time dimension?

Test: rename `valid_time` to `time`

→ update the ROMS tools version

mkvirtualenv --python=/usr/local/bin/python3.13 CROCO
pip install roms-tools[stream]
pip install ipykernel
pip install gcsfs 
pip install zarr
python -m ipykernel install --user --name=CROCO


## Results

### Subsetting

```bash
module load NCO
ncks -d time,-1, -d s_rho,32 croco_canary_avg.nc last_avg.nc 
```

## Compiling with ifort and MPI

The netCDF library was also compiled using the intel compilers.

```bash
~/.local/mpiifort/bin/nf-config --all

This netCDF-Fortran 4.5.2 has been built with the following features: 

  --cc        -> mpiicc
  --cflags    ->  -I/home/ulg/gher/ctroupin/.local/mpiifort/include -I/home/ulg/gher/ctroupin/.local/mpiifort//include -I/include

  --fc        -> mpiifort
  --fflags    -> -I/home/ulg/gher/ctroupin/.local/mpiifort/include
  --flibs     -> -L/home/ulg/gher/ctroupin/.local/mpiifort/lib -lnetcdff -L/home/ulg/gher/ctroupin/.local/mpiifort//lib -L/lib -lnetcdf -lnetcdf -lm 
  --has-f90   -> 
  --has-f03   -> yes

  --has-nc2   -> yes
  --has-nc4   -> yes

  --prefix    -> /home/ulg/gher/ctroupin/.local/mpiifort
  --includedir-> /home/ulg/gher/ctroupin/.local/mpiifort/include
  --version   -> netCDF-Fortran 4.5.2
```




```bash
module load releases/2023b
module load impi
```

export CC=icx
export CXX=icpc
export CFLAGS='-O3 -xHost -ip -no-prec-div -static-intel'
export CXXFLAGS='-O3 -xHost -ip -no-prec-div -static-intel'
export F77=ifx
export FC=ifx
export F90=ifx
export FFLAGS='-O3 -xHost -ip -no-prec-div -static-intel'
export CPP='icx -E'
export CXXCPP='icpc -E'



## Running the model

```bash
#!/bin/bash
# Submission script for NIC5
#SBATCH --job-name=CROCO-NEAtlantic
#SBATCH --time=01:01:00 # hh:mm:ss
#
#SBATCH --ntasks=32
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=1000 # megabytes
#SBATCH --partition=batch
#
#SBATCH --mail-user=ctroupin@uliege.be
#SBATCH --mail-type=ALL

module --force purge
module load releases/2023b
ulimit -s unlimited
module load OpenMPI
export I_MPI_PMI=pmi2
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi2.so
NCDIR=/home/ulg/gher/ctroupin/.local/mpiifort
LD_LIBRARY_PATH=${NCDIR}/lib:${LD_LIBRARY_PATH}
cd /home/ulg/gher/ctroupin/CROCO_Canary/croco-v2.1.2/OCEAN/
#srun croco crocoNIC5.in
#srun croco02 crocoNIC5_02.in
srun --mpi=pmi2 croco_nea crocoNIC5_NEA_32.in
```

## Errors & debugging

### MPI

```bash
MPI startup(): PMI server not found. Please set I_MPI_PMI_LIBRARY variable if it is not a singleton case.
MP` startup(): PMI server not found. Please set I_MPI_PMI_LIBRARY variable if it is not a singleton case.
...
```

Solved by setting

```bash
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi2.so
```

### MPI

```bash
Abort(1091087) on node 0 (rank 0 in comm 0): Fatal error in PMPI_Init: Other MPI error, error stack:
MPIR_Init_thread(136):
MPID_Init(939).......:
MPIR_pmi_init(168)...: PMI2_Job_GetId returned 14
Abort(1091087) on node 0 (rank 0 in comm 0): Fatal error in PMPI_Init: Other MPI error, error stack:
MPIR_Init_thread(136):
MPID_Init(939).......:
...
```

Solved by setting:

```bash
export I_MPI_PMI=pmi2
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi2.so
...
srun --mpi=pmi2 croco_nea crocoNIC5_NEA_32.in
```

## Nesting

We use the notebook `nb_make_grid_zoom.ipynb`

./make_grid.py grid_zoom_new.ini
./make_grid.py ibc_zoom_agrif_nea.in

## Optimisation

### Compilation flags

The initial value for the Fortran compilation flags is:

```bash
FFLAGS1="-O2 -mcmodel=medium -fno-alias -i4 -r8 -fp-model precise -axSSE4.2,AVX`
```

The `-axSSE4.2,AVX` is suggested by the [CECI documentation](https://support.ceci-hpc.be/doc/UsingSoftwareAndLibraries/CompilingSoftwareFromSources/#with-gcc)
According to our test, this hasn't a significant change in the run time.


### MPI tiling

To test the run time we set up an experiment with only 5 time steps, no nesting, and no output file writing. There is still a short delay before the main time stepping, but it can be neglected for a normal run.

MPI 



| NP_XI | NP_ETA | Time (s)               | Comment  |
|-------|:------:|------------------------|---|
| 1     | 1      | 218                    |   |
| 2     | 1      | 103                    |   |
| 1     | 2      | 92                     |   |
| 1     | 4      | 68                     |   |
| 2     | 2      | 49                     |   |
| 4     | 1      | 52                     |   |
| 8     | 1      | 40                     |   |
| 16    | 1      | 36                     |   |
| 32    | 1      | 47                     |   |
| 16    | 2      | 36                     |   |
| 8     | 4      | 28                     |   |
| 4     | 8      | More than 15 minutes!! | Not finished  |
| 2     | 16     | More than 15 minutes!! | Not finished  |
| 1     | 32     | 23                     |   |
| 2     | 32     | 26                     |   |
| 4     | 16     | 26                     |   |
