# Running CROCO 

## Installation

### Code download

The code is obtained from the Gitlab repository: https://www.croco-ocean.org/download/.     
The code version is v2.1.2, released on November 18, 2025. 

The code compilation is described here.

### Tooolbox installation

The CROCO Python tools are obtained from https://croco-ocean.gitlabpages.inria.fr/croco_pytools/. 

#### Virtual environment
For the installation it is required to create a virtual environment either using `conda` or `mamba`. In one of the machine tested, the procedure with `conda` did not work:
```bash
conda env create -f env.yml
conda activate croco_pyenv
```
so we switch to `micromamba`.

#### Compilation

The Python toolbox requires the compilation of code that is written in Fortran. 
cd prepro/Modules/tools_fort_routines
make clean
make

## CROCO Compilation

There are essentially 3 files to edit before the compilation:
1. `param.h`, which contains parameters related to the grid, the tiling (for parallel computing) and other options.
2. `cppdef.h` contains the C preprocessor (CPP) options, for instance this is where the boundary conditions (open or close) are specified, or the type of paralelisation (openMP, MPI, ...).
3. `jobcomp` is the file that starts the compilation; it can be editied to specify the Fortran compiler, the compilation flags, the path of the netCDF library etc.

### NetCDF compilation

Before the model code compilation, it might be necessary to compile the netCDF library, in order to ensure that the compiler matches the one that will be used for CROCO. 
Intel Fortran compiler can be installed with:
```bash
sudo apt install intel-oneapi-compiler-fortran
```


Here we used the Intel compilers available on the cluster. The netCDF compilation involves a few steps collected into a single script [compile_netCDF.sh](src/compile_netCDF.sh). 
This script calls `module` commands such as 
```bash
module load releases/2023b
module load intel-compilers
```
which allow one to use pre-installed software on the cluster. Those commands obviously depend on how the cluster manages the libraries.

> [!NOTE]
> We stick to HDF5 version 1.14.6, since issues were encountered with the version 2.0.0.

If the netCDF compilation is successful, you will find (among other files) two executables: `nc-config` and `nf-config`. 
They contain all the information concerning the compilation options used for netCDF (see example below). They are used in the `jobcomp` file to get the correct paths of the netCDF library.

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

### CROCO compilation

The compilation is launched by running the `jobcomp` script. Only the first lines have to be edited by setting the Fortran compiler (`FC=ifx`), the MPI compiler (`MPIF90="mpiifort"`) and the netCDF directories (`NETCDFLIB=$(~/.local/mpiifort/bin/nf-config --flibs)` and `NETCDFINC=-I$(~/.local/mpiifort/bin/nf-config --includedir)`). 

If the compilation flags are to be modified, this has to be done around line 242 (middle of the script). 

> [!WARNING]
> As of January 2026, the code doesn't recognise the latest Intel Fortran compiler (`ifx`). The solution is to edit `jobcomp` around line 239 and rewrite it as:
```bash
if [[ $FC == ifort || $FC == ifx ]] ; then
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



## Results

### Subsetting

```bash
module load NCO
ncks -d time,-1, -d s_rho,32 croco_canary_avg.nc last_avg.nc 
```

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
| 1     | 64     | ???                    | Error in the input reading | 
| 2     | 32     | 26                     |   |
| 4     | 16     | 26                     |   |


## Errors & debugging

In this section we gather the errors encountered during the compilation and execution of the code.

### MPI: PMI server not found

#### Error log

```bash
MPI startup(): PMI server not found. Please set I_MPI_PMI_LIBRARY variable if it is not a singleton case.
MP` startup(): PMI server not found. Please set I_MPI_PMI_LIBRARY variable if it is not a singleton case.
...
```

#### Solution

In the job file, set the value of `I_MPI_PMI_LIBRARY` variable:
```bash
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi2.so
```

### MPI: Fatal error in PMPI_Init

#### Error log

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

#### Solution

Set the value of `I_MPI_PMI` 
```bash
export I_MPI_PMI=pmi2
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi2.so
```

and run the code with the option `--mpi=pmi2`:
```bash
srun --mpi=pmi2 croco_nea crocoNIC5_NEA_32.in
```

### NetCDF: nf_get_vara netCDF error code =  -57

This error was only obtained when running the code using 64 CPUs and with `NP_XI=1` and `NP_ETA=64`.     

#### Error log

```bash
 NF_FREAD ERROR: nf_get_vara netCDF error code =  -57  mynode =   0


 GET_GRID - error while reading variable: h
            in grid netCDF file: CROCO_FILES/run_nea/croco_grd_nea.nc


 MAIN - number of records written into history  file(s):    0
        number of records written into restart  file(s):    0
        number of records written into averages file(s):    0


 ERROR: Abnormal termination: netCDF INPUT


 NF_FREAD ERROR: nf_get_vara netCDF error code =  -40  mynode =  63
```

It seems that the `h` variable cannot be read (even if it present in the netCDF).

#### Solution

Recompile using another tiling (for instance `NP_XI=2` and `NP_ETA=32`)

### Compilation: warning #5117: Bad # preprocessor line

#### Error log

```bash
AGRIF_YOURFILES/modmpp.f90(2): warning #5117: Bad # preprocessor line
# 0 "<built-in>"
---^
```

#### Solution

It is recommended to use the `-fpp` option, however this change doesn't help.

It seems the files written by AGRIF have unusual form, which can trigger the warning.

### 

```bash
[nic5-w020:837662:0:837662]        rndv.c:2360 Assertion `status == UCS_OK' failed
forrtl: error (76): Abort trap signal
```

```
[1768218704.881578] [nic5-w020:837662:0]          rcache.c:887  UCX  ERROR failed to insert region 0x58d9f30 [0x48ace40..0x48fff40]: Element already exists
[1768218704.883218] [nic5-w020:837662:0]          rcache.c:887  UCX  ERROR failed to insert region 0x58e6d60 [0x48ace40..0x48fff40]: Element already exists
[1768218704.883306] [nic5-w020:837662:0]          ucp_mm.c:62   UCX  ERROR failed to register address 0x48ace40 (host) length 340224 on md[4]=mlx5_0: Element already exists (md supports: host)
```

### srun: error: Invalid --distribution specification

#### Error log

```bash
srun: error: Invalid --distribution specification
```

#### Solution

There was a mispelling in the command:
```bash
srun -mpi=pmi2
```
there should be a double dash before `mpi`!! 


### NotImplementedError: LateralFill currently supports only 2D masks.

This message appearq when we try to generate the forcing file using the Python toolbox and apply it on an ECMWF file containing the necessary variables.

#### Error log

```python
NotImplementedError: LateralFill currently supports only 2D masks.
```

In addition there is a warning about the missing time dimension, that can be solved by renaming `valid_time` into `time`.

#### Solution

Not found yet.

### Transport retry count exceeded on mlx5_0:1/IB

#### Error log

```bash
slurmstepd: error: Detected 1 oom-kill event(s) in StepId=10238881.0. Some of your processes may have been killed by the cgroup out-of-memory handler.
srun: error: nic5-w052: task 13: Out Of Memory
slurmstepd: error: Detected 1 oom-kill event(s) in StepId=10238881.0. Some of your processes may have been killed by the cgroup out-of-memory handler.
slurmstepd: error: Detected 1 oom-kill event(s) in StepId=10238881.0. Some of your processes may have been killed by the cgroup out-of-memory handler.
[nic5-w050:2213736:0:2213736] ib_mlx5_log.c:171  Transport retry count exceeded on mlx5_0:1/IB (synd 0x15 vend 0x81 hw_synd 0/0)
```
