set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR ppc)

# COMPILERS
# ---------
SET(CMAKE_C_COMPILER powerpc-linux-gnu-gcc)
SET(CMAKE_CXX_COMPILER powerpc-linux-gnu-g++)
set(CMAKE_COMPILER_PREFIX powerpc-linux-gnu-)

# PATHS
# -----
set(CMAKE_FIND_ROOT_PATH /usr/powerpc-linux-gnu/)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# OTHER
# -----
set(ARCH 32)
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static")
