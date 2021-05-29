#!/bin/bash
# Create a new Docker image.
#
# Example:
#   BITNESS=32 OS=Linux TARGET=powerpcle-unknown-linux-gnu \
#       FILENAME=ppcle-unknown-linux-gnu ./new-image.sh

set -ex

scriptdir=`realpath $(dirname "$BASH_SOURCE")`

if [ "$TARGET" = "" ]; then
    echo 'Must set the target triple via `$TARGET`, quitting.'
    exit 1
fi
arch=$(echo "$TARGET" | cut -d '-' -f 1)

if [ "$BITNESS" = "" ]; then
    echo 'Must set the architecture bitness `$BITNESS`, quitting.'
    exit 1
fi

if [ "$FILENAME" = "" ]; then
    # Sometimes the filename differs from the triple, such
    # as `ppcle-unknown-eabi` vs. `powerpcle-unknown-eabi`.
    FILENAME="$TARGET"
    base=$(echo "$FILENAME" | cut -d '-' -f 1)
fi

if [ "$OS" = "" ]; then
    OS="Generic"
fi

# Create our CMake toolchain file.
cmake="$scriptdir/cmake/$FILENAME.cmake"
if [ "$OS" = "Generic" ]; then
    echo "# Need to override the system name to allow CMake to configure,
# otherwise, we get errors on bare-metal systems.
SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_PROCESSOR $arch)
CMAKE_POLICY(SET CMP0065 NEW)
" > "$cmake"
else
    echo "SET(CMAKE_SYSTEM_NAME $OS)
SET(CMAKE_SYSTEM_PROCESSOR $arch)
" > "$cmake"
fi
echo "# COMPILERS
# ---------
SET(prefix $TARGET)" >> "$cmake"
echo 'SET(dir "/home/crosstoolng/x-tools/${prefix}")
SET(CMAKE_C_COMPILER "${dir}/bin/${prefix}-gcc")
SET(CMAKE_CXX_COMPILER "${dir}/bin/${prefix}-g++")
SET(CMAKE_COMPILER_PREFIX "${prefix}-")

# PATHS
# -----
SET(CMAKE_FIND_ROOT_PATH "${dir}/")
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
' >> "$cmake"
echo "# OTHER
# -----
set(ARCH $BITNESS)" >> "$cmake"

# Create our source environment file.
env="$scriptdir/env/$FILENAME"
echo "prefix=$TARGET" >> "$env"
echo 'dir=/home/crosstoolng/x-tools/"$prefix"/
export CC="$dir"/bin/"$prefix"-gcc
export CXX="$dir"/bin/"$prefix"-g++
export AR="$dir"/bin/"$prefix"-ar
export AS="$dir"/bin/"$prefix"-as
export RANLIB="$dir"/bin/"$prefix"-ranlib
export LD="$dir"/bin/"$prefix"-ld
export NM="$dir"/bin/"$prefix"-nm
export SIZE="$dir"/bin/"$prefix"-size
export STRINGS="$dir"/bin/"$prefix"-strings
export STRIP="$dir"/bin/"$prefix"-strip
' >> "$env"

# Create our dockerfile.
# TODO(ahuszagh) Needs to handle shared/static
dockerfile="$scriptdir/Dockerfile.$FILENAME"
echo "FROM ahuszagh/cross:base

# Build GCC
COPY ct-ng/$TARGET.config /ct-ng/
COPY gcc.sh /ct-ng/
RUN ARCH=$TARGET /ct-ng/gcc.sh

# Remove GCC build scripts and config.
RUN rm -rf /ct-ng/

# Add toolchains
COPY cmake/$FILENAME.cmake /toolchains/toolchain.cmake
COPY cmake/shared.cmake /toolchains
COPY cmake/static.cmake /toolchains
COPY env/$FILENAME /env/toolchain
COPY env/alias /env
COPY env/shared /env
COPY env/static /env" > "$dockerfile"