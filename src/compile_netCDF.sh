#!/bin/bash
module --force purge
module load releases/2023b
module load intel-compilers
module load iimpi

compiler="ifx"
TARGETDIR=/home/ulg/gher/ctroupin/.local/${compiler}2
mkdir -pv ${TARGETDIR}

# export PATH=${TARGETDIR}/bin/:$PATH
# export LD_LIBRARY_PATH=${TARGETDIR}/lib:${LD_LIBRARY_PATH}

export CC=icc
export CXX=mpiicpx
export CFLAGS='-O3 -xHost -ip -no-prec-div -static-intel'
export CXXFLAGS='-O3 -xHost -ip -no-prec-div -static-intel'
export F77=${compiler}
export FC=${compiler}
export F90=${compiler}
export FFLAGS='-O3 -xHost -ip -no-prec-div -static-intel'
export CPP='mpiicx -E'
export CXXCPP='mpiicpx -E'

ZDIR='/home/ulg/gher/ctroupin/download/zlib-1.3.1'
H5DIR='/home/ulg/gher/ctroupin/download/hdf5-1.14.6'
NCDIR='/home/ulg/gher/ctroupin/download/netcdf-c-4.7.4'
NFDIR='/home/ulg/gher/ctroupin/download/netcdf-fortran-4.5.2'

cd ${ZDIR}
./configure --prefix=${TARGETDIR}
#make clean
make
make install

cd ${H5DIR}
./configure --with-zlib=${TARGETDIR} --prefix=${TARGETDIR} --enable-hl
#make clean
make
make install

cd ${NCDIR}
CPPFLAGS="-I${TARGETDIR}/include" LDFLAGS="-L${TARGETDIR}/lib" ./configure --prefix=${TARGETDIR}
make clean
make
make install

export PATH=${TARGETDIR}/bin:$PATH
export LD_LIBRARY_PATH=${TARGETDIR}/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=${TARGETDIR}/lib:$LIBRARY_PATH
export CPATH=${TARGETDIR}/include:$CPATH

cd ${NFDIR}
CPPFLAGS="-I${TARGETDIR}/include" LDFLAGS="-L${TARGETDIR}/lib" ./configure --prefix=${TARGETDIR}
make clean
make
make install
