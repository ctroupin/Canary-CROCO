
# Errors & debugging

This document aims to gather the errors encountered during the compilation and execution of the code.

## MPI: PMI server not found

### Error log

```bash
MPI startup(): PMI server not found. Please set I_MPI_PMI_LIBRARY variable if it is not a singleton case.
MP` startup(): PMI server not found. Please set I_MPI_PMI_LIBRARY variable if it is not a singleton case.
...
```

### Solution

In the job file, set the value of `I_MPI_PMI_LIBRARY` variable:
```bash
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi2.so
```

## MPI: Fatal error in PMPI_Init

### Error log

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

### Solution

Set the value of `I_MPI_PMI` 
```bash
export I_MPI_PMI=pmi2
export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi2.so
```

and run the code with the option `--mpi=pmi2`:
```bash
srun --mpi=pmi2 croco_nea crocoNIC5_NEA_32.in
```

## NetCDF: nf_get_vara netCDF error code =  -57

This error was only obtained when running the code using 64 CPUs and with `NP_XI=1` and `NP_ETA=64`.     

### Error log

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

### Solution

Recompile using another tiling (for instance `NP_XI=2` and `NP_ETA=32`)

## Compilation: warning #5117: Bad # preprocessor line

### Error log

```bash
AGRIF_YOURFILES/modmpp.f90(2): warning #5117: Bad # preprocessor line
# 0 "<built-in>"
---^
```

### Solution

It is recommended to use the `-fpp` option, however this change doesn't help.

It seems the files written by AGRIF have unusual form, which can trigger the warning.

## Assertion `status == UCS_OK' failed

### Error log

```bash
[nic5-w020:837662:0:837662]        rndv.c:2360 Assertion `status == UCS_OK' failed
forrtl: error (76): Abort trap signal
```

```
[1768218704.881578] [nic5-w020:837662:0]          rcache.c:887  UCX  ERROR failed to insert region 0x58d9f30 [0x48ace40..0x48fff40]: Element already exists
[1768218704.883218] [nic5-w020:837662:0]          rcache.c:887  UCX  ERROR failed to insert region 0x58e6d60 [0x48ace40..0x48fff40]: Element already exists
[1768218704.883306] [nic5-w020:837662:0]          ucp_mm.c:62   UCX  ERROR failed to register address 0x48ace40 (host) length 340224 on md[4]=mlx5_0: Element already exists (md supports: host)
```

### Solution

Not easily reproduced.

## srun: error: Invalid --distribution specification

### Error log

```bash
srun: error: Invalid --distribution specification
```

### Solution

There was a mispelling in the command:
```bash
srun -mpi=pmi2
```
there should be a double dash before `mpi`!! 


## NotImplementedError: LateralFill currently supports only 2D masks.

This message appearq when we try to generate the forcing file using the Python toolbox and apply it on an ECMWF file containing the necessary variables.

### Error log

```python
NotImplementedError: LateralFill currently supports only 2D masks.
```

In addition there is a warning about the missing time dimension, that can be solved by renaming `valid_time` into `time`.

### Solution

Not found yet.

## Transport retry count exceeded on mlx5_0:1/IB

### Error log

```bash
slurmstepd: error: Detected 1 oom-kill event(s) in StepId=10238881.0. Some of your processes may have been killed by the cgroup out-of-memory handler.
srun: error: nic5-w052: task 13: Out Of Memory
slurmstepd: error: Detected 1 oom-kill event(s) in StepId=10238881.0. Some of your processes may have been killed by the cgroup out-of-memory handler.
slurmstepd: error: Detected 1 oom-kill event(s) in StepId=10238881.0. Some of your processes may have been killed by the cgroup out-of-memory handler.
[nic5-w050:2213736:0:2213736] ib_mlx5_log.c:171  Transport retry count exceeded on mlx5_0:1/IB (synd 0x15 vend 0x81 hw_synd 0/0)
```

### Solution 

Not easily reproducible.

### ERROR 1: PROJ: proj_create_from_database: Open of /home/ctroupin/miniconda3/envs/croco_pyenv/share/proj failed


When running the first cell of the notebook:
```python
%matplotlib widget  
%load_ext autoreload
%autoreload 2

import os
# Import custom modules
from Modules.croco_class import CROCO
```

## forrtl: severe (71): integer divide by zero

```bash
forrtl: severe (71): integer divide by zero
Image              PC                Routine            Line        Source
libpthread-2.28.s  00001471ACEA8CF0  Unknown               Unknown  Unknown
croco_2_32_agrif2  00000000008B7DEE  Unknown               Unknown  Unknown
croco_2_32_agrif2  00000000008B7DAA  Unknown               Unknown  Unknown
croco_2_32_agrif2  00000000008B7901  Unknown               Unknown  Unknown
croco_2_32_agrif2  00000000004BB31E  Unknown               Unknown  Unknown
croco_2_32_agrif2  00000000004BAFD9  Unknown               Unknown  Unknown
croco_2_32_agrif2  00000000004BAE57  Unknown               Unknown  Unknown
croco_2_32_agrif2  0000000000BC19F7  Unknown               Unknown  Unknown
croco_2_32_agrif2  0000000000BC1A6B  Unknown               Unknown  Unknown
croco_2_32_agrif2  0000000000BBF350  Unknown               Unknown  Unknown
croco_2_32_agrif2  0000000000466E88  Unknown               Unknown  Unknown
croco_2_32_agrif2  00000000004664F1  Unknown               Unknown  Unknown
croco_2_32_agrif2  00000000004084CD  Unknown               Unknown  Unknown
libc-2.28.so       00001471AB2E9D85  __libc_start_main     Unknown  Unknown
croco_2_32_agrif2  00000000004083EE  Unknown               Unknown  Unknown
```

### Solution

The `croco.in.1` file was not created (for the nested domain).

##  CHECKDIMS ERROR: inconsistent size of dimension 'xi_rho':  698 (must be  704).

### Solution

The initial conditions were created with a wrong version of the grid.

## NF_FREAD ERROR: nf_get_vara netCDF error code

See discussion here: https://forum.croco-ocean.org/t/netcdf-error-in-cluster/731

### Error log

```bash
 NF_FREAD ERROR: nf_get_vara netCDF error code =  -40  mynode = 127

 GET_GRID - error while reading variable: h
            in grid netCDF file: CROCO_FILES/run_nea/croco_grd_nea.nc
```
The message is repeated several times. The error code can be -40 or -57.

### Solution

It seems it also depends on the tiling.
