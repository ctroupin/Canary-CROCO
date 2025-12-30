## Preparing the input files

### CROCO

We create the grid, initial conditions and boundary files with the [CROCO toolbox](https://croco-ocean.gitlabpages.inria.fr/croco_pytools/index.html) in Python. 

The toolbox doesn't have the possibility to create the forcing, so we rely on the [ROMS toolbox](https://roms-tools.readthedocs.io/en/latest/) (also in Python), hoping that the horizontal grids are compatible.


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

Note: should adjust the northeastern side to ensure the boundary is closed.

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
ncks -d time,4 -d s_rho,32 croco_canary_avg.nc last_avg.nc 

## Compiling with ifort

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