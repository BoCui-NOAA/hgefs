#! /usr/bin/env bash

#######################################################################
### Usage:
###
### To build, install and clean executable hgefs_enssat
###  ./build_hgefs_ensstat.sh >& hgefs.compile.log
###
### To build, install and clean executable hgefs_enssate in debug mode
###  ./build_hgefs_ensstat.sh debug >& hgefs.compile.log  
###
###  More information in README.build
###
#######################################################################

set -eux

module reset
cwd=`pwd`

progname=hgefs_ensstat

source ../versions/build.ver

module use ${cwd}/../modulefiles/hgefs
module load ${progname} #.${target}
module list

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  mkdir ../exec
fi

#
cd ${progname}.fd

export FCMP=${FCMP:-ftn}
export FCMP95=$FCMP

export FFLAGSM="-O3 -traceback -convert big_endian"

# Check if we are building debug executable
if [ "${1:-}" = "debug" ]; then
  export FFLAGSM="-O3 -traceback -convert big_endian -check all -ftrapuv"
  echo "Building in debug mode"
fi

export RECURS=
export LDFLAGSM=${LDFLAGSM:-""}
export OMPFLAGM=${OMPFLAGM:-""}

export INCSM="-I ${G2_INC4}"

export LIBSM="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}"

if [ "${1:-}" = "clean" ]; then
  make -f Makefile clean
elif [ "${1:-}" = "build" ]; then
  make -f Makefile
elif [ "${1:-}" = "install" ]; then
  make -f Makefile install
else
  make -f Makefile clobber
  make -f Makefile
  make -f Makefile install
  make -f Makefile clobber
fi

exit
