# Running CROCO 

## Installation

### Code download

The code is obtained from the Gitlab repository: https://www.croco-ocean.org/download/.     
The code version is `v2.1.2`, released on November 18, 2025. 

The code compilation is described in this [section](#croco-compilation).

### Tooolbox installation

The CROCO Python tools are obtained from https://croco-ocean.gitlabpages.inria.fr/croco_pytools/. 

#### Virtual environment

For the installation, it is required to create a virtual environment, either using `conda` or `mamba`.     
In one of the machine tested, the procedure with `conda` 
```bash
conda env create -f env.yml
conda activate croco_pyenv
```
did not work, so we switch to `micromamba`:
```bash
micromamba env create -f env.yml
eval "$(micromamba shell hook --shell bash)"
micromamba activate croco_pyenv
```

> [!NOTE]
> Working with `pip` did not allow us to complete the installation.


#### Toolbox compilation

The Python toolbox requires the compilation of code that is written in Fortran. 
```bash
cd prepro/Modules/tools_fort_routines
make clean
make
```

The kernel for Jupyter is created with
```bash
ipython kernel install --user --name=croco_pyenv
```

## NetCDF compilation

Before the CROCO code compilation, it might be necessary to compile the netCDF library, in order to ensure that the compiler matches the one that will be used for CROCO (Intel compilers in this case).

The Intel Fortran compiler can be installed with:
```bash
sudo apt install intel-oneapi-compiler-fortran
```

Here we used the Intel compilers already available on the cluster. 

The netCDF compilation involves a few steps collected into a single script [compile_netCDF.sh](../src/compile_netCDF.sh). 

This script calls `module` commands such as 
```bash
module load releases/2023b
module load intel-compilers
```
which allow one to use pre-installed software on the cluster. Those commands obviously depend on how the cluster manages the libraries (`slurm` is the workload manager for `NIC5` cluster)

> [!NOTE]
> For the compilation, we stick to HDF5 version 1.14.6, since issues were encountered with the version 2.0.0.

If the netCDF compilation is successful, you will find (among other files) two executables: 
- `nc-config` and 
- `nf-config`.

Running one of those files provide all the information concerning the compilation options used for netCDF (see example below). They are used in the `jobcomp` file to get the correct paths of the netCDF library.

```bash
$ ./nf-config --all

This netCDF-Fortran 4.5.2 has been built with the following features: 

  --cc        -> icc
  --cflags    ->  -I/home/ulg/gher/ctroupin/.local/ifx/include -I/home/ulg/gher/ctroupin/.local/ifx/include

  --fc        -> ifx
  --fflags    -> -I/home/ulg/gher/ctroupin/.local/ifx/include
  --flibs     -> -L/home/ulg/gher/ctroupin/.local/ifx/lib -lnetcdff -L/home/ulg/gher/ctroupin/.local/ifx/lib -lnetcdf -lnetcdf -lm 
  --has-f90   -> 
  --has-f03   -> yes

  --has-nc2   -> yes
  --has-nc4   -> yes

  --prefix    -> /home/ulg/gher/ctroupin/.local/ifx
  --includedir-> /home/ulg/gher/ctroupin/.local/ifx/include
  --version   -> netCDF-Fortran 4.5.2
```

## CROCO Compilation

There are essentially 3 files to edit before the compilation, all located in `croco-v2.1.2/OCEAN`:
1. `param.h`, which contains parameters related to the grid, the _tiling_ (for parallel computing) and other options.
2. `cppdef.h` contains the C preprocessor (CPP) options, for instance this is where the boundary conditions (open or close) are specified, or the type of paralelisation (openMP, MPI, ...).
3. `jobcomp` is the file that triggers the compilation; it can be edited to specify 
   - the Fortran compiler, 
   - the compilation flags, 
   - the path of the netCDF library etc.

In the followings we detail the steps to compile CROCO on `NIC5` machine using the Intel compilers.

### Editing `cppdef.h`

`cppdef.h` is the file containing all the options for the pre-compilation. There are many options to chose, 

First we set the name of our configuration (around line 55):
```bash
 /* Configuration Name */
# define CANARY01
```
then we activate/disable the different options, for instance:
- the parallelisation: 
  ```bash
  # undef  OPENMP
  # define  MPI
  ```
- the nesting:
  ```bash
  # define  AGRIF
  # define  AGRIF_2WAY
  ```
- the boundary conditions (open or closed)
  ```bash
  # undef  OBC_EAST
  # define OBC_WEST
  # define OBC_NORTH
  # define OBC_SOUTH
  ```

> [!NOTE]
> The name used for the configuration (`CANARY01`) will be used in the file `param.h`.


### Editing `param.h`

#### Setting the grid size

The first step is to create a line that matches the name of configuration (`CANARY01`)
and set the values for `LLm0` and `MMm0`

```
#  elif defined CANARY01 
       parameter (LLm0=884, MMm0=800,  N=32)
```

> [!WARNING]
> The values for those parameters have to exactly matches the size of the grid, defined by `nx` and `ny`

For example:
```bash 
ncdump -h croco_grd.nc | tail -10
    :created = "2025-12-23T11:42:02.730436" ;
		:type = "CROCO grid file produced by croco_pytools" ;
		:nx = 884 ;
		:ny = 800 ;
		:size_x_km = 3300LL ;
		:size_y_km = 3000LL ;
		:central_lon = -23LL ;
		:central_lat = 37.2 ;
		:rotation = -5.5 ;
```

#### Setting the tiling

If you work with MPI, you also need to set the values for `NP_XI` and `NP_ETA`, which define how the _tiling_ (or domain decomposition) is performed:

```bash
#ifdef MPI
      integer NP_XI, NP_ETA, NNODES
#if defined(SPLITTING_X) && defined(SPLITTING_ETA)
      parameter (NP_XI=SPLITTING_X,  NP_ETA=SPLITTING_ETA,  NNODES=NP_XI*NP_ETA)
#else
      parameter (NP_XI=2,  NP_ETA=8,  NNODES=NP_XI*NP_ETA)
```
Here we will define the domain in **2** along the ξ axis and **8** in the η axis. 

> [!NOTE]
> Those numbers will have to be taken into account when submitting the job on the cluster.


### Editing `jobcomp`

The compilation is triggered by running the `jobcomp` script. Only the first lines have to be edited by setting the Fortran compiler (`FC=ifx`), the MPI compiler (`MPIF90="mpiifort"`) and the netCDF directories, through the setting of the `nf-config` path:
```bash
NETCDFLIB=$(~/.local/mpiifort/bin/nf-config --flibs
NETCDFINC=-I$(~/.local/mpiifort/bin/nf-config --includedir)
```

> [!NOTE]
> Those environment variables can obviously be set _by hand_, the risk is that the netCDF library does not match the compilation settings needed for CROCO (i.g., netCDF compiled with `gfortran` and CROCO requiring `ifx`).

If the compilation flags are to be modified, this has to be done around line 242 (middle of the script). 

> [!WARNING]
> As of January 2026, the code doesn't recognise the latest Intel Fortran compiler (`ifx`). The solution is to edit `jobcomp` around line 239 and rewrite it as:
```bash
if [[ $FC == ifort || $FC == ifx ]] ; then
```

The `jobcomp` execution lasts around 1 minute (2 minutes when AGRIF is enabled) and create an executable `croco` in the same directory.

## CROCO input files

For our application we will create files storing:
1. the grid, 
2. the initial conditions and 
3. the boundary conditions.

To this end we use the [CROCO toolbox](https://croco-ocean.gitlabpages.inria.fr/croco_pytools/index.html) in Python. 

> [!NOTE]
> The toolbox doesn't have the possibility to create the forcing file, but it uses atmospheric state variables to compute the fluxes _online_. This means that no forcing files are created, but atmospheric variables are read at each time step and used to compute the fluxes. 

#### Grid file

1. Edit the file `grid_neatlantic.ini`; this file contains the spatial definition of the grid, but also paths to the bathymetry and the coastline;
2. Run the notebook `nb_make_grid.ipynb` or the script ``nb_make_grid.jl`. 

#### Initial conditions

Before the extraction of the initial and boundary conditions, it is necessary to have a numerical model outputs at our disposal. The CROCO Python tools provides scripts to download from:
- HYCOM (script `download_hycom.py`)
- Mercator models (script `download_mercator.py`)

The procedure is as follows:
1. Edit `download_mercator.ini` to specify the period of interest and the path to the grid file,
2. Run `python download_mercator.py`,
3. Edit `ibc.ini`
4. Run `python make_ini.py ibc.ini`

> [!NOTE]
> This step implies the interpolation of the GLORYS model on the CROCO grid and can take some time. 

> [!WARNING]
> Reminder: don't forget to activate the `croco_pyenv` before running the different scripts.

#### Boundary conditions

The file `ibc.ini` has been edited in the previous step, hence the boundary conditions are created by runing `python make_bry.py ibc.ini`

#### Forcing

No forcing files are generated but files storing atmospheric variables have to be downloaded.

1. Edit the file `download_era5.ini`
2. Run `python download_era5.py download_era5.ini`

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
srun --mpi=pmi2 croco_nea crocoNIC5_NEA_32.in
```

## Nesting

We use the notebook `nb_make_grid_zoom.ipynb`
```
./make_grid.py grid_zoom_new.ini
./make_grid.py ibc_zoom_agrif_nea.in
```

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
| 4     | 8      | > 15 minutes           | Not finished  |
| 2     | 16     | > 15 minutes           | Not finished  |
| 1     | 32     | 23                     |   |
| 1     | 64     | ???                    | Error in the input reading | 
| 2     | 32     | 26                     |   |
| 4     | 16     | 26                     |   |
| 2     | 64     | ???                    | Error in the input reading |
| 4     | 32     | > 5 minutes            | Not finished |
| 8     | 16     | ?                      | Error in the input reading |




## Result processing

Various commands that could be useful for the result analysis.

### Subsetting

Often we only want to have the results at the surface. This can be done by activating the corresponding C
 
```bash
module load NCO
ncks -d time,-1, -d s_rho,-1 croco_canary_avg.nc last_avg.nc 
```

for instance
```bash
ncks -d time,-1, -d s_rho,-1 croco_canary_avg.00085.nc last_00085.nc
ncks -d time,-1, -d s_rho,-1 croco_canary_avg.00085.nc.1 last_00085.nc.1
```

